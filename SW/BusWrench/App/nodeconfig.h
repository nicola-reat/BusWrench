#pragma once

#include <QAbstractListModel>   // base class: a list that QML can show (Repeater, ListView)
#include <QList>                // container used to store the nodes
#include <QString>
#include <QVariantMap>          // set of named values, used to send one node to QML
#include <QStringList>
/*
 * OVERVIEW
 * --------
 * NodeConfig is the list of the "known nodes": for each board it stores the
 * CAN node ID (e.g. 0x45), the name (e.g. "Dashboard") and the icon.
 * The list is edited in the Settings page and saved with QSettings, so it is
 * still there after the program is closed.
 *
 * It has two jobs:
 *   1. Show the list in the Settings page (it is a list model, like DeviceModel).
 *   2. Tell DeviceModel which name and icon to use for each device found on the bus.
 */
class NodeConfig : public QAbstractListModel
{
    Q_OBJECT

    // Number of nodes in the list (QML can read it as nodes.count).
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    // Fields of each node that QML can read. In the delegate they are used as
    // model.nodeNum, model.idText, model.nodeName, model.iconFile (see roleNames()).
    enum Roles {
        IdRole = Qt::UserRole + 1,   // nodeNum   -> 69
        IdTextRole,                  // idText    -> "0x45"
        NameRole,                    // nodeName  -> "Dashboard"
        IconRole                     // iconFile  -> "ico_gauge.svg"
    };

    explicit NodeConfig(QObject *parent = nullptr);

    // Functions every list model must have: how many rows, the value of a
    // field of a row, and the names of the fields for QML.
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_nodes.size(); }

    // Name and icon file of a node ID. Used by DeviceModel for every card.
    // If the ID is not in the list, a generic name and icon are returned.
    QString nameFor(quint8 id) const;
    QString iconFor(quint8 id) const;

    // Returns the three fields of one row (nodeName, idText, iconFile).
    // QML uses it to fill the editor when a row is clicked.
    Q_INVOKABLE QVariantMap get(int row) const;

    // Saves a node. row = -1 adds a new node, otherwise it changes that row.
    // Returns an empty text if everything is fine, otherwise the error to show.
    Q_INVOKABLE QString save(int row, const QString &name,
                             const QString &idText, const QString &icon);

    // Removes the node of the given row.
    Q_INVOKABLE void remove(int row);

    // File URLs of the icons (.svg and .png) found in the user icon folder.
    // QML adds them to the built-in icons in the icon picker.
    Q_INVOKABLE QStringList userIcons() const;

    // Opens the user icon folder in Windows Explorer.
    Q_INVOKABLE void openIconFolder() const;
signals:
    void countChanged();   // a node was added or removed
    void nodesChanged();   // a name or an icon changed: the device cards must refresh

private:
    // Data of one known node.
    struct Node {
        int id = 0;        // CAN node ID (e.g. 0x45 = 69)
        QString name;      // name shown in the UI
        QString icon;      // file name inside the "images" folder
    };

    void load();                       // reads the list from the settings
    void store() const;                // writes the list in the settings
    static QString idToText(int id);   // 69 -> "0x45"
    // Folder where the user puts his own icons (it is created if it does not exist).
    static QString iconFolder();
    QList<Node> m_nodes;               // the list itself
};
