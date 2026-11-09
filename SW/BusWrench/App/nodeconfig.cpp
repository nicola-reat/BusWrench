#include "nodeconfig.h"

#include <QSettings>   // permanent settings (on Windows: the registry)
#include <QDesktopServices>   // opens a folder with the default Windows program
#include <QDir>               // folder and file listing
#include <QStandardPaths>     // standard folders of the user (AppData, ...)
#include <QUrl>               // file path <-> URL conversion

// Constructor: reads the saved list as soon as the object is created.
NodeConfig::NodeConfig(QObject *parent) : QAbstractListModel(parent)
{
    load();
}

// Converts a node ID to text: 69 -> "0x45".
//   QString::number(id, 16)  writes the number in hexadecimal ("45")
//   toUpper()                makes the letters capital ("2a" -> "2A")
//   rightJustified(2, '0')   adds a leading 0 if there is only one digit ("5" -> "05")
QString NodeConfig::idToText(int id)
{
    return QStringLiteral("0x") + QString::number(id, 16).toUpper().rightJustified(2, '0');
}

// Reads the list of nodes from the settings.
// The very first time nothing is saved, so it starts with the boards we know.
void NodeConfig::load()
{
    QSettings s;

    // "nodes/initialized" is written by store(). It is false only on the first run.
    // Without this flag, a user who deletes all the nodes would get the default
    // ones back at the next start.
    if (!s.value("nodes/initialized", false).toBool()) {
        m_nodes = {
            { 0x45, QStringLiteral("Dashboard"),      QStringLiteral("ico_gauge.svg")  },
            { 0x30, QStringLiteral("PDM Anteriore"),  QStringLiteral("ico_cpu.svg")    },
            { 0x31, QStringLiteral("PDM Posteriore"), QStringLiteral("ico_cpu.svg")    },
            { 0x21, QStringLiteral("Tastierino"),     QStringLiteral("ico_keypad.svg") }
        };
        store();      // save them, so the next start finds them
        return;
    }

    // Saved list: it is stored as an "array" (nodes/list/1/id, nodes/list/1/name, ...).
    const int n = s.beginReadArray("nodes/list");
    for (int i = 0; i < n; ++i) {
        s.setArrayIndex(i);                       // select the i-th element
        Node nd;
        nd.id   = s.value("id").toInt();
        nd.name = s.value("name").toString();
        nd.icon = s.value("icon").toString();
        m_nodes.append(nd);
    }
    s.endArray();
}

// Writes the whole list in the settings. Called after every change.
void NodeConfig::store() const
{
    QSettings s;

    // Delete the old list first: if the new list is shorter, no old
    // entries are left at the end.
    s.remove("nodes/list");

    s.beginWriteArray("nodes/list", m_nodes.size());
    for (int i = 0; i < m_nodes.size(); ++i) {
        s.setArrayIndex(i);
        s.setValue("id",   m_nodes.at(i).id);
        s.setValue("name", m_nodes.at(i).name);
        s.setValue("icon", m_nodes.at(i).icon);
    }
    s.endArray();

    s.setValue("nodes/initialized", true);   // from now on the saved list is used
}
// Number of rows of the list = number of nodes.
// (A list has no sub-rows, so if "parent" is valid the answer is 0.)
int NodeConfig::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_nodes.size();
}

// Returns one field of one node, as requested by QML through a "role".
QVariant NodeConfig::data(const QModelIndex &index, int role) const
{
    // Ignore invalid requests (row outside the list).
    if (!index.isValid() || index.row() < 0 || index.row() >= m_nodes.size())
        return {};

    const Node &nd = m_nodes.at(index.row());

    switch (role) {
    case IdRole:     return nd.id;                 // 69
    case IdTextRole: return idToText(nd.id);       // "0x45"
    case NameRole:   return nd.name;               // "Dashboard"
    case IconRole:   return nd.icon;               // "ico_gauge.svg"
    }
    return {};
}

// Names of the fields as QML sees them: model.nodeName, model.idText, ...
QHash<int, QByteArray> NodeConfig::roleNames() const
{
    return {
        { IdRole,     "nodeNum"  },
        { IdTextRole, "idText"   },
        { NameRole,   "nodeName" },
        { IconRole,   "iconFile" }
    };
}

// Name of a node ID. If the ID is not known, "Nodo 0xNN" is returned.
QString NodeConfig::nameFor(quint8 id) const
{
    for (const Node &nd : m_nodes)
        if (nd.id == id)
            return nd.name;
    return QStringLiteral("Nodo ") + idToText(id);
}

// Icon file of a node ID. If the ID is not known, the generic chip icon is used.
QString NodeConfig::iconFor(quint8 id) const
{
    for (const Node &nd : m_nodes)
        if (nd.id == id)
            return nd.icon;
    return QStringLiteral("ico_cpu.svg");
}

// Returns the fields of one row as a set of named values for QML.
QVariantMap NodeConfig::get(int row) const
{
    if (row < 0 || row >= m_nodes.size())
        return {};

    const Node &nd = m_nodes.at(row);
    return { { "nodeName", nd.name },
            { "idText",   idToText(nd.id) },
            { "iconFile", nd.icon } };
}

// Checks the values written in the editor and saves the node.
// Returns "" if all is fine, otherwise the text of the error.
QString NodeConfig::save(int row, const QString &name,
                         const QString &idText, const QString &icon)
{
    // The name cannot be empty.
    const QString n = name.trimmed();
    if (n.isEmpty())
        return QStringLiteral("Inserisci un nome");

    // Convert the ID text to a number. Base 0 accepts both "0x45" and "69".
    // Valid IDs are 1..0x7F: the replies of the boards use 0x680 + node ID,
    // and CanBackend only reads the IDs from 0x680 to 0x6FF.
    bool ok = false;
    const int id = idText.trimmed().toInt(&ok, 0);
    if (!ok || id < 1 || id > 0x7F)
        return QStringLiteral("ID non valido (da 0x01 a 0x7F)");

    // Two nodes cannot have the same ID (the row being edited is ignored).
    for (int i = 0; i < m_nodes.size(); ++i)
        if (i != row && m_nodes.at(i).id == id)
            return QStringLiteral("ID già usato da ") + m_nodes.at(i).name;

    Node nd;
    nd.id = id;
    nd.name = n;
    nd.icon = icon;

    if (row < 0 || row >= m_nodes.size()) {
        // New node: it is added at the end of the list.
        // beginInsertRows/endInsertRows tell QML that a row is being added.
        beginInsertRows(QModelIndex(), m_nodes.size(), m_nodes.size());
        m_nodes.append(nd);
        endInsertRows();
        emit countChanged();
    } else {
        // Existing node: replace it and tell QML that this row changed.
        m_nodes[row] = nd;
        emit dataChanged(index(row), index(row));
    }

    store();               // write to the settings
    emit nodesChanged();   // DeviceModel refreshes the cards
    return {};             // no error
}

// Removes a node from the list and from the settings.
void NodeConfig::remove(int row)
{
    if (row < 0 || row >= m_nodes.size())
        return;

    // beginRemoveRows/endRemoveRows tell QML that a row disappears.
    beginRemoveRows(QModelIndex(), row, row);
    m_nodes.removeAt(row);
    endRemoveRows();

    store();
    emit countChanged();
    emit nodesChanged();
}

// Folder for the user icons: ...\AppData\Roaming\BusWrench\BusWrench\deviceicons
// The organization and application names set in main.cpp are part of the path.
QString NodeConfig::iconFolder()
{
    const QString dir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        + QStringLiteral("/deviceicons");
    QDir().mkpath(dir);          // create the folder if it is missing
    return dir;
}

// Lists the .svg and .png files of the icon folder, as file URLs
// ("file:///C:/Users/.../deviceicons/fan.svg"), sorted by name.
// An Image in QML can load a file URL directly.
QStringList NodeConfig::userIcons() const
{
    QDir d(iconFolder());
    const QStringList files = d.entryList({ "*.svg", "*.png" }, QDir::Files,
                                          QDir::Name | QDir::IgnoreCase);
    QStringList urls;
    for (const QString &f : files)
        urls << QUrl::fromLocalFile(d.filePath(f)).toString();
    return urls;
}

// Opens the icon folder in Windows Explorer.
void NodeConfig::openIconFolder() const
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(iconFolder()));
}
