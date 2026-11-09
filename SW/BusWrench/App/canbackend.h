#ifndef CANBACKEND_H
#define CANBACKEND_H

#include <QObject>
#include <QString>
#include <QTimer>
#include "devicemodel.h"


class QCanBusDevice;
class QCanBusFrame;

/*
 * OVERVIEW
 * --------
 * CanBackend is the CAN communication manager of the application.
 * It handles the PEAK PCAN-USB adapter connection and provides
 * CAN communication status and received frame information to the QML UI.
 *
 * Main responsibilities:
 *   1. Manage the CAN adapter connection.
 *   2. Monitor connection status and detect unexpected disconnections.
 *   3. Automatically retry the connection when the adapter is unavailable.
 *   4. Receive incoming CAN frames and maintain the RX counter.
 *   5. Expose connection and reception information through Q_PROPERTY.
 *
 * The class does not contain any UI logic.
 * Communication with the QML frontend is handled through Qt properties
 * and signals.
 */

class CanBackend : public QObject
{
    Q_OBJECT

    // CAN adapter connection status.
    Q_PROPERTY(bool connected READ connected NOTIFY statusChanged)

    // Main connection status message displayed in the UI.
    Q_PROPERTY(QString statusTitle READ statusTitle NOTIFY statusChanged)

    // Additional connection information or error description.
    Q_PROPERTY(QString statusDetail READ statusDetail NOTIFY statusChanged)

    // Total number of received CAN frames.
    Q_PROPERTY(int rxCount READ rxCount NOTIFY rxCountChanged)

    // String representation of the most recently received CAN frame.
    Q_PROPERTY(QString lastFrame READ lastFrame NOTIFY rxCountChanged)

    // List of devices found by the bus scan (read by the QML UI as a list model).
    Q_PROPERTY(DeviceModel* devices READ devices CONSTANT)

public:
    // Constructor and destructor.
    explicit CanBackend(QObject *parent = nullptr);
    ~CanBackend() override;

    // QML-accessible property getters.
    bool connected() const { return m_connected; }
    QString statusTitle() const { return m_title; }
    QString statusDetail() const { return m_detail; }
    int rxCount() const { return m_rx; }
    QString lastFrame() const { return m_last; }
    DeviceModel *devices() { return m_devices; }

    // QML-accessible CAN connection control functions.
    Q_INVOKABLE void connectBus();
    Q_INVOKABLE void disconnectBus();
    Q_INVOKABLE void scan();      // sends the SCAN command to all nodes
    // Asks one board (node ID, e.g. 69) for its details: uptime, flash partitions, ...
    Q_INVOKABLE void requestDetails(int nodeId);
    // Sends a one-byte command to a board (e.g. 0x21 = reboot). The answer
    // arrives with the signal actionResult().
    Q_INVOKABLE void sendAction(int nodeId, int cmd);
    // Sends one standard CAN frame (used by UpdateManager). False if not connected.
    bool sendFrame(quint32 id, const QByteArray &payload);

    // Speed of the CAN bus in kbit/s. setBitrate() only stores the value
    // (used before the first connection); applyBitrate() also reconnects the adapter.
    void setBitrate(int kbit) { m_bitrate = kbit; }
    Q_INVOKABLE void applyBitrate(int kbit);

signals:
    // Emitted whenever the adapter connection status or related information changes.
    void statusChanged();

    // Emitted whenever the RX counter or last received frame is updated.
    void rxCountChanged();

    // Emitted for every frame coming from a node (IDs 0x680..0x6FF).
    void frameReceived(quint32 id, const QByteArray &payload);

    // Answer of a board to an action command: result 0 = ok, 1 = failed.
    void actionResult(int nodeId, int cmd, int result);

private:
    // Updates the connection status and notifies the QML interface.
    void setStatus(bool ok, const QString &title, const QString &detail);

    // Handles unexpected adapter disconnections and prepares for reconnection.
    void handleDeviceDisconnected();

    // Checks whether the physical PEAK adapter is still available.
    void checkHardware();

    // Pointer to the active Qt CAN device instance.
    // nullptr indicates that no device is currently assigned.
    QCanBusDevice *m_dev = nullptr;

    // Current adapter connection state.
    bool m_connected = false;

    // Connection status information exposed to QML.
    QString m_title = QStringLiteral("USB-CAN non connesso");
    QString m_detail = QStringLiteral("Nessun adattatore");

    // CAN reception statistics and last received frame.
    int m_rx = 0;
    QString m_last;

    // Periodic timer used to detect available adapters
    // and automatically retry failed or lost connections.
    QTimer *m_retryTimer = nullptr;
    // CAN speed in kbit/s (default 500, replaced by the saved setting at startup).
    int m_bitrate = 500;
    void handleFrame(const QCanBusFrame &f);
    DeviceModel *m_devices = nullptr;
};

#endif // CANBACKEND_H
