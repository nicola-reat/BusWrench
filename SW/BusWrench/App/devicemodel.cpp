#include "devicemodel.h"

#include <QDateTime>   // Current time, used to detect silent nodes.
#include "nodeconfig.h"   // list of the known nodes (names and icons)


// Receives the list of the known nodes (called once by main.cpp).
void DeviceModel::setNodeConfig(NodeConfig *cfg)
{
    m_nodes = cfg;
    if (!cfg)
        return;

    // When the user saves a node in the Settings page, NodeConfig emits
    // nodesChanged(). Here every row is marked "changed" (only the name and
    // icon fields), so QML redraws all the cards with the new name and icon.
    connect(cfg, &NodeConfig::nodesChanged, this, [this]() {
        if (!m_items.isEmpty())
            emit dataChanged(index(0), index(m_items.size() - 1), { NameRole, IconRole });
    });
}

// Constructor: nothing to initialize, the list starts empty.
DeviceModel::DeviceModel(QObject *parent) : QAbstractListModel(parent) {}

// Number of rows (devices) in the list.
int DeviceModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

// Returns one field of one device, as requested by QML through a role.
QVariant DeviceModel::data(const QModelIndex &index, int role) const
{
    // Ignore invalid requests.
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const Item &it = m_items.at(index.row());

    switch (role) {
    case NameRole:
        // Name chosen in the Settings page (or "Nodo 0xNN" if the node is unknown).
        return m_nodes ? m_nodes->nameFor(it.nodeId) : QString();

    case ChipRole:
        return it.chip == 1 ? QStringLiteral("ESP32-S3")
               : it.chip == 2 ? QStringLiteral("STM32")
                              : QStringLiteral("Sconosciuto");

    case NodeIdRole:
        // Example: 0x45
        return QStringLiteral("0x")
               + QString::number(it.nodeId, 16).toUpper().rightJustified(2, '0');

    case FirmwareRole:
        // Example: 0.9.1
        return QStringLiteral("%1.%2.%3").arg(it.maj).arg(it.min).arg(it.patch);

    case HardwareRole:
        // Example: REV_A
        return QStringLiteral("REV_") + QChar(it.hw);

    case UidRole: {
        // The 6 UID bytes are shown as three groups, e.g. 7A12-3F6D-9C8E.
        const QByteArray hex = it.uid.toHex().toUpper();
        if (hex.size() != 12)
            return QStringLiteral("-");   // UID not received yet
        return QString::fromLatin1(hex.mid(0, 4)) + '-' +
               QString::fromLatin1(hex.mid(4, 4)) + '-' +
               QString::fromLatin1(hex.mid(8, 4));
    }

    case OnlineRole:
        return it.online;

    case IconRole:
        // Icon file chosen in the Settings page (or the generic chip icon).
        return m_nodes ? m_nodes->iconFor(it.nodeId) : QString();
    }

    return {};
}

// Maps each role to the name used in QML (model.deviceName, model.chip, ...).
QHash<int, QByteArray> DeviceModel::roleNames() const
{
    return {
        { NameRole,     "deviceName" },
        { ChipRole,     "chip" },
        { NodeIdRole,   "nodeId" },
        { FirmwareRole, "firmware" },
        { HardwareRole, "hardware" },
        { UidRole,      "uid" },
        { OnlineRole,   "online" },
        { IconRole,     "iconFile" }
    };
}

// Removes all devices from the list. Called before a new scan.
void DeviceModel::clear()
{
    beginResetModel();
    m_items.clear();
    endResetModel();

    emit countChanged();
}

// Returns the row of the given node. If the node is not in the list yet,
// a new row is added at the end and its index is returned.
int DeviceModel::ensure(quint8 nodeId)
{
    for (int i = 0; i < m_items.size(); ++i)
        if (m_items.at(i).nodeId == nodeId)
            return i;

    // Notify QML that a new row is being inserted (a new card will appear).
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
    Item it;
    it.nodeId = nodeId;
    it.frames = 1;     // the frame that created the row is counted
    m_items.append(it);
    endInsertRows();

    emit countChanged();
    return m_items.size() - 1;
}

// Stores the INFO_A message: chip type, hardware revision, firmware version.
// The node counts as online because it has just answered.
void DeviceModel::setInfoA(quint8 nodeId, quint8 chip, char hw,
                           quint8 maj, quint8 min, quint8 patch)
{
    const int i = ensure(nodeId);
    Item &it = m_items[i];

    it.chip = chip;
    it.hw = hw;
    it.maj = maj;
    it.min = min;
    it.patch = patch;
    it.lastSeen = QDateTime::currentMSecsSinceEpoch();
    it.online = true;

    emit dataChanged(index(i), index(i));
}

// Stores the INFO_B message: the 6-byte UID.
void DeviceModel::setInfoB(quint8 nodeId, const QByteArray &uid)
{
    const int i = ensure(nodeId);
    Item &it = m_items[i];

    it.uid = uid;
    it.lastSeen = QDateTime::currentMSecsSinceEpoch();
    it.online = true;

    emit dataChanged(index(i), index(i));
}

// Marks a node as alive after any frame received from it (heartbeat, answers).
// It never adds new nodes: devices appear in the list only after a scan.
void DeviceModel::touch(quint8 nodeId)
{
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items.at(i).nodeId != nodeId)
            continue;

        m_items[i].lastSeen = QDateTime::currentMSecsSinceEpoch();
        ++m_items[i].frames;    // one more frame from this node
        // If the node was offline, bring it back online and update the UI.
        if (!m_items[i].online) {
            m_items[i].online = true;
            emit dataChanged(index(i), index(i), { OnlineRole });
        }
        return;
    }
}

// Called every second by a timer: a node that has been silent for more
// than 3 seconds is set Offline, so its card turns red in the UI.
void DeviceModel::checkOnline()
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();

    for (int i = 0; i < m_items.size(); ++i) {
        const bool on = (now - m_items.at(i).lastSeen) < 3000;

        if (on != m_items.at(i).online) {
            m_items[i].online = on;
            emit dataChanged(index(i), index(i), { OnlineRole });
        }
    }
}

// Collects all the data of one device in a set of named values (name, chip, ...).
// The Details page calls it every half second. The text fields are built by
// data(), so they are the same shown by the device card.
QVariantMap DeviceModel::infoFor(int nodeId) const
{
    for (int i = 0; i < m_items.size(); ++i) {
        const Item &it = m_items.at(i);
        if (it.nodeId != nodeId)
            continue;

        const QModelIndex idx = index(i);
        QVariantMap m;
        m["deviceName"] = data(idx, NameRole);
        m["chip"]       = data(idx, ChipRole);
        m["nodeId"]     = data(idx, NodeIdRole);
        m["firmware"]   = data(idx, FirmwareRole);
        m["hardware"]   = data(idx, HardwareRole);
        m["uid"]        = data(idx, UidRole);
        m["online"]     = data(idx, OnlineRole);
        m["iconFile"]   = data(idx, IconRole);
        m["chipId"]     = it.chip;        // 1 = ESP32-S3, 2 = STM32
        m["lastSeen"]   = it.lastSeen;    // ms since 1970, same clock as Date.now() in QML
        m["frames"]     = it.frames;
        // Details received from the board (all empty/zero until the board answers).
        m["detailsOk"]  = it.detailsOk;
        m["uptimeSec"]  = uint(it.uptime);
        m["resetCode"]  = int(it.resetCode);
        m["txErr"]      = int(it.txErr);
        m["rxErr"]      = int(it.rxErr);
        m["tempC"]      = int(it.temp);               // -128 = not available
        m["buildDate"]  = it.buildDate;
        m["commit"]     = it.gitHash == 0
                          ? QString()
                          : QString::number(it.gitHash, 16).rightJustified(7, '0')
                                + (it.gitDirty ? QStringLiteral("-dirty") : QString());
        for (int s = 0; s < 2; ++s) {
            const Item::Part &pt = it.part[s];
            m[QStringLiteral("p%1Present").arg(s)] = pt.present;
            m[QStringLiteral("p%1Flags").arg(s)]   = int(pt.flags);
            m[QStringLiteral("p%1Addr").arg(s)]    = int(pt.addr);
            m[QStringLiteral("p%1Size").arg(s)]    = int(pt.size);
            m[QStringLiteral("p%1Used").arg(s)]    = int(pt.usedKb);
            m[QStringLiteral("p%1Version").arg(s)] = pt.version;
        }
        return m;
    }
    return {};     // node not found (for example after a new scan)
}

// Stores one frame of the answer to the DETAILS command. The first byte of the
// payload tells which frame it is (see can_update_proto.h). Numbers are little endian.
void DeviceModel::setDetails(quint8 nodeId, const QByteArray &p)
{
    // Find the device. Unknown nodes are ignored: the list is filled only by the scan.
    int row = -1;
    for (int i = 0; i < m_items.size(); ++i)
        if (m_items.at(i).nodeId == nodeId)
            row = i;
    if (row < 0 || p.isEmpty())
        return;

    Item &it = m_items[row];
    auto u8 = [&p](int i) { return quint8(p[i]); };

    switch (u8(0)) {
    case 0xA0:                                   // DETAIL_A
        if (p.size() < 8) return;
        it.uptime = quint32(u8(1)) | (quint32(u8(2)) << 8)
                    | (quint32(u8(3)) << 16) | (quint32(u8(4)) << 24);
        it.resetCode = u8(5);
        it.txErr = u8(6);
        it.rxErr = u8(7);
        break;

    case 0xA1:                                   // DETAIL_B
        if (p.size() < 7) return;
        it.temp = qint8(u8(1));
        it.buildDate = QStringLiteral("%1/%2/%3 %4:%5")
                           .arg(u8(4), 2, 10, QChar('0'))          // day
                           .arg(u8(3), 2, 10, QChar('0'))          // month
                           .arg(2000 + u8(2))                      // year
                           .arg(u8(5), 2, 10, QChar('0'))          // hour
                           .arg(u8(6), 2, 10, QChar('0'));         // minute
        break;

    case 0xA2:                                   // DETAIL_C
        if (p.size() < 6) return;
        it.gitHash = quint32(u8(1)) | (quint32(u8(2)) << 8)
                     | (quint32(u8(3)) << 16) | (quint32(u8(4)) << 24);
        it.gitDirty = (u8(5) != 0);
        break;

    case 0xA3: {                                 // PART_A
        if (p.size() < 7 || u8(1) > 1) return;
        Item::Part &pt = it.part[u8(1)];
        pt.present = true;
        pt.flags = u8(2);
        pt.addr = u8(3);
        pt.size = u8(4);
        pt.usedKb = quint16(u8(5) | (u8(6) << 8));
        break;
    }

    case 0xA4: {                                 // PART_B
        if (p.size() < 5 || u8(1) > 1) return;
        Item::Part &pt = it.part[u8(1)];
        pt.version = (u8(2) == 0xFF && u8(3) == 0xFF && u8(4) == 0xFF)
                         ? QStringLiteral("-")
                         : QStringLiteral("%1.%2.%3").arg(u8(2)).arg(u8(3)).arg(u8(4));
        break;
    }

    default:
        return;
    }

    it.detailsOk = true;     // the Details page reads the data with infoFor()
}
