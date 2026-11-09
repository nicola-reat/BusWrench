#pragma once

#include <QAbstractListModel>
#include <QByteArray>
#include <QList>
#include <QString>
#include <QVariantMap>   // set of named values, used to send the data of one device to QML
/*
 * OVERVIEW
 * --------
 * DeviceModel is the list of devices found on the CAN bus.
 * It is exposed to QML as a list model, so a Repeater or ListView
 * can create one card for each device.
 *
 * Main responsibilities:
 *   1. Store the information sent by each node (chip, firmware, hardware, UID).
 *   2. Add a device to the list when it answers the bus scan.
 *   3. Track the last time each node was heard and mark it Online or Offline.
 *   4. Provide the data to QML through named roles (deviceName, chip, ...).
 *   5. Decide the name and the icon of each device (single source of truth:
 *      the card and the detail panel both read them from here).
 *
 * The class does not talk to the CAN adapter directly: CanBackend
 * decodes the CAN frames and calls the functions below.
 */
class NodeConfig;   // only the name is needed here: the full class is in nodeconfig.h

class DeviceModel : public QAbstractListModel
{
    Q_OBJECT

    // Number of devices currently in the list.
    Q_PROPERTY(int count READ count NOTIFY countChanged)


public:
    // Data fields available to QML for each device (used as model.<roleName>).
    enum Roles {
        NameRole = Qt::UserRole + 1,   // deviceName
        ChipRole,                      // chip
        NodeIdRole,                    // nodeId
        FirmwareRole,                  // firmware
        HardwareRole,                  // hardware
        UidRole,                       // uid
        OnlineRole,                    // online
        IconRole                       // iconFile
    };

    explicit DeviceModel(QObject *parent = nullptr);

    // Standard list model functions required by Qt.
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Number of devices in the list.
    int count() const { return m_items.size(); }
    // Gives the model the list of the known nodes. The model asks it for the
    // name and the icon of each device. Called once by main.cpp.
    void setNodeConfig(NodeConfig *cfg);
    // All the data of one device (found by its node ID) as named values, for the
    // Details page. Returns an empty set if the node is not in the list.
    Q_INVOKABLE QVariantMap infoFor(int nodeId) const;
    // Stores the answer of a board to the DETAILS command (frames 0xA0..0xA4).
    void setDetails(quint8 nodeId, const QByteArray &payload);
    // Removes all devices (called before a new scan).
    void clear();

    // Stores chip type, hardware revision and firmware version of a node
    // (INFO_A message). Adds the node to the list if it is not present yet.
    void setInfoA(quint8 nodeId, quint8 chip, char hw,
                  quint8 maj, quint8 min, quint8 patch);

    // Stores the 6-byte UID of a node (INFO_B message).
    void setInfoB(quint8 nodeId, const QByteArray &uid);

    // Marks a node as "seen now". Called for every frame received from it.
    void touch(quint8 nodeId);

    // Sets Offline every node silent for more than 3 seconds.
    // Called periodically by a timer in CanBackend.
    void checkOnline();

signals:
    // Emitted when a device is added to or removed from the list.
    void countChanged();

private:
    // Information stored for each device.
    struct Item {
        quint8 nodeId = 0;         // CAN node ID (e.g. 0x45)
        quint8 chip = 0;           // 1 = ESP32-S3, 2 = STM32
        char hw = '?';             // hardware revision letter (e.g. 'A')
        quint8 maj = 0, min = 0, patch = 0;   // firmware version
        QByteArray uid;            // 6-byte unique ID
        qint64 lastSeen = 0;       // time of the last received frame (ms)
        bool online = false;       // true if the node answered recently
        quint32 frames = 0;        // number of frames received from this node
        // ---- Details (answer to the DETAILS command) ----
        bool detailsOk = false;     // at least one DETAILS frame was received
        quint32 uptime = 0;         // seconds since the board started
        quint8 resetCode = 0;       // see CANUPD_RST_* in the protocol
        quint8 txErr = 0, rxErr = 0;     // CAN error counters of the board
        qint8 temp = -128;          // chip temperature in degrees (-128 = not available)
        QString buildDate;          // "09/11/2026 11:20"
        quint32 gitHash = 0;        // short git hash (7 hex digits), 0 = not available
        bool gitDirty = false;      // the code had uncommitted changes
        struct Part {               // one OTA slot of the flash
            bool present = false;
            quint8 flags = 0;       // bit0 running, bit1 next boot, bit2 valid image
            quint8 addr = 0;        // address in units of 64 KB
            quint8 size = 0;        // size in units of 64 KB
            quint16 usedKb = 0;     // size of the firmware in KB
            QString version = QStringLiteral("-");
        };
        Part part[2];               // 0 = ota_0, 1 = ota_1
    };

    // Returns the row of a node, adding it to the list if it does not exist.
    int ensure(quint8 nodeId);

    // All devices found on the bus.
    QList<Item> m_items;
    // Source of the names and icons of the devices (set by setNodeConfig()).
    NodeConfig *m_nodes = nullptr;
};
