#ifndef CANBACKEND_H
#define CANBACKEND_H

#include <QObject>
#include <QString>
#include <QTimer>
#include "devicemodel.h"
#include <QMap>
#include <QPoint>

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
 *   6. Read, write and save the sensor parameters of the gauge boards.
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

    // Last value of the sensor of one gauge board (frame 0x500 + node ID) as named
    // values: node, valid, value, valueX10, volt, mv, fault, flags, counter, ageMs.
    // ageMs = milliseconds since the last frame (-1 if none was received).
    Q_INVOKABLE QVariantMap sensorInfo(int nodeId) const;
    // Last values of the sensor of one board (about 60 seconds), for the graph.
    Q_INVOKABLE QVariantList sensorHistory(int nodeId) const;

    // ---- Sensor parameters of a gauge board (filter, fault limits, table) ----
    // The answers arrive later: the signals sensorParamsChanged() and paramAck()
    // tell when, and sensorParams() returns what the PC has received so far.

    // Asks the board for all its sensor parameters (the points of the table too).
    Q_INVOKABLE void readSensorParams(int nodeId);
    // Asks for one parameter (see CANUPD_PAR_... in can_update_proto.h).
    Q_INVOKABLE void readParam(int nodeId, int param, int index = 0);
    // Changes one parameter. The board uses it at once but does NOT save it.
    Q_INVOKABLE void writeParam(int nodeId, int param, int index, qint64 value);
    // Sends a whole calibration table: a list of {mv: ..., valueX10: ...}.
    Q_INVOKABLE void writeTable(int nodeId, const QVariantList &points);
    // "Save": the board writes all its parameters in the permanent memory.
    Q_INVOKABLE void saveParams(int nodeId);
    // "Factory": the board goes back to the factory values and erases the saved ones.
    Q_INVOKABLE void resetParams(int nodeId);
    // The parameters received from one board as named values: node, known,
    // filterMs, lowMv, highMv, tableN, tableComplete and table (a list of
    // {index, mv, volt, valueX10, value}). A value not received yet is -1.
    Q_INVOKABLE QVariantMap sensorParams(int nodeId) const;
    // Writes a text parameter (name or unit): it is cut in pieces of 4 bytes, one
    // frame each. Too long (in bytes, UTF-8) -> paramAck with status 5.
    Q_INVOKABLE void writeText(int nodeId, int param, const QString &text);

signals:
    // Emitted whenever the adapter connection status or related information changes.
    void statusChanged();

    // Emitted whenever the RX counter or last received frame is updated.
    void rxCountChanged();

    // Emitted for every frame coming from a node (IDs 0x680..0x6FF).
    void frameReceived(quint32 id, const QByteArray &payload);

    // Answer of a board to an action command: result 0 = ok, 1 = failed.
    void actionResult(int nodeId, int cmd, int result);

    // A sensor parameter of a board has been received: sensorParams() has news.
    void sensorParamsChanged(int nodeId);

    // Answer of a board to WRITE / SAVE / RESET. status: 0 = ok, 5 = value not valid,
    // 6 = unknown parameter, 3 = busy (update in progress), 4 = memory error.
    void paramAck(int nodeId, int cmd, int param, int status);

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
    // Decodes the sensor frame of one node (see send_sensor_value() in the firmware).
    void handleSensorFrame(quint8 node, const QByteArray &p);

    // Last sensor frame received from one node.
    struct SensorData {
        bool valid = false;        // at least one frame was received
        int valueX10 = -1;         // value in tenths of the unit (-1 = no valid value yet)
        int mv = 0;                // voltage at the connector, in millivolts
        quint8 flags = 0;          // bit0 sensor fault, bit1 low alarm, bit2 high alarm
        quint8 counter = 0;        // counter of the board (grows at every frame)
        qint64 lastMs = 0;         // PC time when the frame arrived
    };
    QMap<int, SensorData> m_sensor;          // node ID -> last frame
    QMap<int, QList<double>> m_sensorHist;   // node ID -> last values (10 per second)

    // Sensor parameters received from one board (-1 = not received yet).
    struct SensorParams {
        int filterMs = -1;         // moving average time, ms
        int lowMv = -1;            // fault limit below, mV
        int highMv = -1;           // fault limit above, mV
        int nodeNext = -1;         // node ID saved in the board (used from the next boot)
        QByteArray nameBytes = QByteArray(12, '\0');   // the name, 3 pieces of 4 bytes
        quint8 nameMask = 0;       // bit i = piece i of the name has arrived
        QByteArray unitBytes = QByteArray(4, '\0');    // the unit (4 bytes)
        bool unitOk = false;       // the unit has arrived
        int decimals = -1;         // digits after the point (-1 = not received yet)
        int faultMode = -1;        // 0 = "- - -" blinking, 1 = last valid value
        int alarmEnabled[3] = { -1, -1, -1 };   // per alarm: 0/1 (-1 = not received yet)
        int alarmThr[3]     = { -1, -1, -1 };   // threshold, tenths
        int alarmHyst[3]    = { -1, -1, -1 };   // hysteresis, tenths
        int alarmDelay[3]   = { -1, -1, -1 };   // delay, tenths of a second
        int alarmStartup    = -1;               // seconds ignored after power on
        int periodMs = -1;                      // period of the sensor frame (-1 = not received yet)
        int tableN = -1;           // number of points of the calibration table
        QMap<int, QPoint> table;   // point number -> (x = mV, y = value x10)
    };
    QMap<int, SensorParams> m_params;        // node ID -> its parameters

    // A VALUE answer (0xB0) of a board: stores it and, if it is the number of
    // points of the table, asks for the points too.
    void handleParamValue(quint8 node, quint8 param, quint8 index, quint32 value);
    // An ACK answer (0xB1) of a board to WRITE / SAVE / RESET.
    void handleParamAck(quint8 node, quint8 cmd, quint8 param, quint8 status);
};

#endif // CANBACKEND_H
