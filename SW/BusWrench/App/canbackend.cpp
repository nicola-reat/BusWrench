#include "canbackend.h"

#include <QCanBus>        // Qt CAN Bus API and available CAN plugins.
#include <QCanBusDevice>  // Interface for an opened CAN adapter.
#include <QCanBusFrame>   // Represents an individual CAN frame.
#include <QDebug>         // Debug and diagnostic output.
#include <QVariant>       // Generic value type used for device configuration.
#include <QTimer>         // Periodic adapter detection and reconnection.
#include <QDateTime>      // SENSOR: time of the last sensor frame.
// Windows API definitions required by PCAN-Basic.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <Windows.h>
#include <PCANBasic.h>

// Codes of the sensor parameter protocol (same numbers as can_update_proto.h).
namespace {
constexpr quint8 CMD_PARAM_READ  = 0x30;   // PC -> board: give me a parameter
constexpr quint8 CMD_PARAM_WRITE = 0x31;   // PC -> board: change a parameter
constexpr quint8 CMD_PARAM_SAVE  = 0x32;   // PC -> board: save everything
constexpr quint8 CMD_PARAM_RESET = 0x33;   // PC -> board: factory values

constexpr quint8 PAR_FILTER_MS   = 0x01;   // moving average time, ms
constexpr quint8 PAR_LOW_MV      = 0x02;   // fault limit below, mV
constexpr quint8 PAR_HIGH_MV     = 0x03;   // fault limit above, mV
constexpr quint8 PAR_NODE_ID     = 0x04;   // node ID, saved at once, used from the next boot
constexpr quint8 PAR_NAME        = 0x05;   // name of the gauge, 3 pieces of 4 bytes
constexpr quint8 PAR_UNIT        = 0x06;   // unit, 4 bytes
constexpr quint8 PAR_DECIMALS    = 0x07;   // digits after the point
constexpr quint8 PAR_FAULT_MODE  = 0x08;   // what to show on fault
constexpr quint8 PAR_SENSOR_PERIOD   = 0x09;   // period of the sensor frame, ms
constexpr quint8 PAR_ALARM_ENABLE    = 0x20;   // per alarm (index 0..2)
constexpr quint8 PAR_ALARM_THRESHOLD = 0x21;
constexpr quint8 PAR_ALARM_HYST      = 0x22;
constexpr quint8 PAR_ALARM_DELAY     = 0x23;
constexpr quint8 PAR_ALARM_STARTUP   = 0x24;
constexpr quint8 PAR_TABLE_N     = 0x10;   // number of points of the table
constexpr quint8 PAR_TABLE_POINT = 0x11;   // one point of the table (index = number)

constexpr int MAX_TABLE_POINTS   = 16;     // the board accepts 2 ... 16 points

// A 32-bit number as 4 bytes, least significant byte first (little endian).
QByteArray le32(quint32 v)
{
    QByteArray b(4, 0);
    b[0] = char(v & 0xFF);
    b[1] = char((v >> 8) & 0xFF);
    b[2] = char((v >> 16) & 0xFF);
    b[3] = char((v >> 24) & 0xFF);
    return b;
}
} // namespace

// Constructor: initializes the backend and starts the automatic
// adapter detection process.
CanBackend::CanBackend(QObject *parent) : QObject(parent)
{
    // List of devices found by the bus scan.
    m_devices = new DeviceModel(this);

    // Configure the automatic hardware monitoring and reconnection timer.
    m_retryTimer = new QTimer(this);
    m_retryTimer->setInterval(2000);

    connect(m_retryTimer, &QTimer::timeout,
            this, &CanBackend::checkHardware);

    m_retryTimer->start();

    // Every second, set Offline the devices that stopped answering.
    QTimer *onlineTimer = new QTimer(this);
    onlineTimer->setInterval(1000);
    connect(onlineTimer, &QTimer::timeout,
            m_devices, &DeviceModel::checkOnline);
    onlineTimer->start();
}

// Destructor: disconnects the CAN adapter and releases resources.
CanBackend::~CanBackend()
{
    m_retryTimer->stop();
    disconnectBus();
}

// Updates the connection status exposed to the QML interface.
//   ok     - Connection state (true = connected, false = disconnected).
//   title  - Main status message displayed in the UI.
//   detail - Additional connection information or error description.
void CanBackend::setStatus(bool ok, const QString &title, const QString &detail)
{
    m_connected = ok;
    m_title = title;
    m_detail = detail;

    emit statusChanged();
}

// Detects an available PEAK adapter and establishes the CAN connection.
void CanBackend::connectBus()
{
    // Prevent multiple connection attempts if a device is already active.
    if (m_dev)
        return;

    // Retrieve the list of available PEAK CAN adapters.
    QString err;

    const auto list = QCanBus::instance()->availableDevices(
        QStringLiteral("peakcan"), &err);

    qDebug() << "Available PEAK adapters:" << list.size()
             << "Error:" << err;

    // No adapter detected.
    if (list.isEmpty()) {
        setStatus(false,
                  QStringLiteral("USB-CAN not found"),
                  err.isEmpty()
                      ? QStringLiteral("Connect the PCAN-USB adapter")
                      : err);
        return;
    }

    // Create a CAN device instance using the first available adapter.
    QCanBusDevice *dev = QCanBus::instance()->createDevice(
        QStringLiteral("peakcan"), list.first().name(), &err);

    if (!dev) {
        setStatus(false, QStringLiteral("Adapter error"), err);
        return;
    }

    // Assign ownership to CanBackend.
    dev->setParent(this);

    // Configure CAN bitrate (the value chosen in the Settings page, in bit/s).
    dev->setConfigurationParameter(
        QCanBusDevice::BitRateKey, QVariant(m_bitrate * 1000));

    // Monitor CAN device state changes.
    connect(dev, &QCanBusDevice::stateChanged, this,
            [this, dev](QCanBusDevice::CanBusDeviceState state) {

                qDebug() << "CAN device state changed:" << state;

                if (dev == m_dev &&
                    state == QCanBusDevice::UnconnectedState) {
                    handleDeviceDisconnected();
                }
            });

    // Handle incoming CAN frames.
    connect(dev, &QCanBusDevice::framesReceived, this, [this, dev]() {

        if (dev != m_dev)
            return;

        // Read all frames currently available in the receive queue.
        while (dev->framesAvailable()) {

            const QCanBusFrame f = dev->readFrame();

            ++m_rx;
            m_last = f.toString();
            handleFrame(f);
        }

        emit rxCountChanged();
    });

    // Monitor CAN communication errors.
    connect(dev, &QCanBusDevice::errorOccurred, this,
            [this, dev](QCanBusDevice::CanBusError error) {

                qWarning() << "CAN error:" << error << dev->errorString();

                if (dev != m_dev)
                    return;

                // Bus errors (for example a frame that no node acknowledges)
                // do not mean the adapter was lost: declare a disconnection
                // only if the PCAN-USB hardware is really missing.
                if (error == QCanBusDevice::ConnectionError ||
                    error == QCanBusDevice::ReadError) {

                    const TPCANStatus status = CAN_GetStatus(PCAN_USBBUS1);
                    if (status & PCAN_ERROR_ILLHW)
                        handleDeviceDisconnected();
                }
            });

    // Establish the connection with the physical CAN adapter.
    if (!dev->connectDevice()) {

        const QString error = dev->errorString();

        qWarning() << "CAN connection failed:" << error;

        dev->deleteLater();

        setStatus(false,
                  QStringLiteral("Connection failed"),
                  error);
        return;
    }

    // Connection established successfully.
    m_dev = dev;

    setStatus(true,
              QStringLiteral("USB-CAN connected"),
              QStringLiteral("PCAN-USB | %1 kbit/s").arg(m_bitrate));

    qDebug() << "CAN adapter connected successfully.";
}

// Handles an unexpected CAN adapter disconnection.
void CanBackend::handleDeviceDisconnected()
{
    if (!m_dev)
        return;

    qDebug() << "CAN adapter disconnected.";

    QCanBusDevice *dev = m_dev;

    // Clear the active device pointer before releasing the object.
    m_dev = nullptr;

    // Disconnect the device and schedule its deletion.
    dev->disconnectDevice();
    dev->deleteLater();

    // The adapter is gone: the devices found on the bus are no longer valid.
    m_devices->clear();

    // Update the QML connection status.
    setStatus(false,
              QStringLiteral("USB-CAN disconnected"),
              QStringLiteral("Adapter connection lost"));
}

// Periodic check (every 2 s): reconnects if no adapter is active,
// otherwise verifies that the physical adapter is still present.
void CanBackend::checkHardware()
{
    // If no device is connected, search for an available adapter.
    if (!m_dev) {
        connectBus();
        return;
    }

    // Check the physical status of the first PEAK USB channel.
    TPCANStatus status = CAN_GetStatus(PCAN_USBBUS1);

    // The hardware has been physically disconnected.
    if (status & PCAN_ERROR_ILLHW) {

        qWarning() << "PCAN-USB hardware disconnected!";

        handleDeviceDisconnected();
        return;
    }

    // Bus warning / error-passive states are expected when no node acknowledges
    // the frames (empty bus): they are not a hardware failure, so ignore them.
    const TPCANStatus busBits = PCAN_ERROR_BUSLIGHT | PCAN_ERROR_BUSHEAVY
                                | PCAN_ERROR_BUSPASSIVE;
    const TPCANStatus other = status & ~busBits;

    // Log only unexpected PCAN-Basic errors.
    if (other != PCAN_ERROR_OK) {
        qWarning() << "PCAN status:" << Qt::hex << status;
    }
}

// Disconnects the CAN adapter and releases associated resources.
void CanBackend::disconnectBus()
{
    if (!m_dev)
        return;

    QCanBusDevice *dev = m_dev;
    m_dev = nullptr;

    // Close the CAN connection and release the device instance.
    dev->disconnectDevice();
    delete dev;

    // Empty the device list shown in the UI.
    m_devices->clear();

    setStatus(false,
              QStringLiteral("USB-CAN disconnected"),
              QStringLiteral("No adapter connected"));
}

// Sends the SCAN command (ID 0x600, data 0x01) to all nodes on the bus.
void CanBackend::scan()
{
    if (!m_dev) {
        qWarning() << "Scan not possible: bus not connected";
        return;
    }

    m_devices->clear();    // empty the list before a new scan
    m_dev->writeFrame(QCanBusFrame(0x600, QByteArray::fromHex("01")));
    qDebug() << "SCAN sent";
}

// Interprets the frames sent by the nodes: the replies (IDs 0x680..0x6FF)
// and the sensor values of the gauge boards (IDs 0x501..0x57F).
void CanBackend::handleFrame(const QCanBusFrame &f)
{
    if (f.frameType() != QCanBusFrame::DataFrame || f.hasExtendedFrameFormat())
        return;

    const quint32 id = f.frameId();

    // SENSOR: sensor value of a gauge board: ID 0x500 + node ID. It is not an
    // answer to a command, so it is handled before the range check below.
    if (id > 0x500 && id <= 0x57F) {
        const quint8 node = quint8(id - 0x500);
        m_devices->touch(node);                  // the board is alive
        handleSensorFrame(node, f.payload());
        return;
    }

    if (id < 0x680 || id > 0x6FF)
        return;                                   // not part of our protocol

    const quint8 node = quint8(id - 0x680);       // node ID
    const QByteArray p = f.payload();
    if (p.isEmpty())
        return;

    // Any frame from a node (heartbeat included) means the node is alive:
    // this keeps its card Online. Nodes found by a scan only.
    m_devices->touch(node);
    emit frameReceived(id, p);   // lets UpdateManager read the answers of the nodes
    switch (quint8(p[0])) {
    case 0x81:                                    // INFO_A
        if (p.size() >= 6) {
            m_devices->setInfoA(node, quint8(p[1]), p[2],
                                quint8(p[3]), quint8(p[4]), quint8(p[5]));
            qDebug() << "INFO_A from node" << node;
        }
        break;
    case 0x82:                                    // INFO_B (UID)
        if (p.size() >= 7)
            m_devices->setInfoB(node, p.mid(1, 6));
        break;
    case 0xA0:                                    // DETAIL_A
    case 0xA1:                                    // DETAIL_B
    case 0xA2:                                    // DETAIL_C
    case 0xA3:                                    // PART_A
    case 0xA4:                                    // PART_B
        m_devices->setDetails(node, p);
        break;
    case 0xA5:                                    // ACTION_ACK: [0xA5, command, result]
        if (p.size() >= 3)
            emit actionResult(node, quint8(p[1]), quint8(p[2]));
        break;
    case 0xB0:                                    // PARAM_VALUE: [0xB0, param, index, 0, value x4]
        if (p.size() >= 8) {
            const quint32 value = quint32(quint8(p[4]))
            | (quint32(quint8(p[5])) << 8)
                | (quint32(quint8(p[6])) << 16)
                | (quint32(quint8(p[7])) << 24);
            handleParamValue(node, quint8(p[1]), quint8(p[2]), value);
        }
        break;
    case 0xB1:                                    // PARAM_ACK: [0xB1, command, param, status]
        if (p.size() >= 4)
            handleParamAck(node, quint8(p[1]), quint8(p[2]), quint8(p[3]));
        break;
    default:                                      // heartbeat etc.: ignored for now
        break;
    }
}

// Sends one standard CAN frame on the bus.
bool CanBackend::sendFrame(quint32 id, const QByteArray &payload)
{
    if (!m_dev)
        return false;
    return m_dev->writeFrame(QCanBusFrame(id, payload));
}

// Changes the CAN speed: closes the adapter and opens it again with the new bitrate.
// The list of devices is emptied (a new scan is needed on the new speed).
void CanBackend::applyBitrate(int kbit)
{
    m_bitrate = kbit;

    // Close the current connection; this also empties the device list.
    disconnectBus();

    // Wait a moment so the adapter driver releases the channel, then reconnect
    // (connectBus() reads m_bitrate). If it fails, checkHardware() retries every 2 s.
    QTimer::singleShot(300, this, &CanBackend::connectBus);
}

// Sends the DETAILS command (0x20) to one node: ID 0x600 + node ID.
// The board answers with 7 frames (0xA0..0xA4), read by handleFrame().
void CanBackend::requestDetails(int nodeId)
{
    sendFrame(0x600u + quint32(nodeId), QByteArray(1, char(0x20)));
}

// Sends a command made of one byte to a node: ID 0x600 + node ID.
void CanBackend::sendAction(int nodeId, int cmd)
{
    sendFrame(0x600u + quint32(nodeId), QByteArray(1, char(cmd)));
}

// SENSOR: decodes the sensor frame of one node (6 bytes, little endian):
//   byte 0-1: value in tenths of the unit (200 = 20.0 L), signed 16 bit
//   byte 2-3: voltage at the connector in millivolts
//   byte 4  : flags: bit0 = sensor fault, bit1 = low alarm, bit2 = high alarm
//   byte 5  : counter 0..255
void CanBackend::handleSensorFrame(quint8 node, const QByteArray &p)
{
    if (p.size() < 6)
        return;
    auto u8 = [&p](int i) { return quint8(p[i]); };

    SensorData &s = m_sensor[node];          // created the first time this node is seen
    s.valid    = true;
    s.valueX10 = qint16(u8(0) | (u8(1) << 8));    // -1 = no valid value yet
    s.mv       = quint16(u8(2) | (u8(3) << 8));
    s.flags    = u8(4);
    s.counter  = u8(5);
    s.lastMs   = QDateTime::currentMSecsSinceEpoch();

    // Keep the last 600 values of this node (60 s at 10 frames per second) for the graph.
    if (s.valueX10 >= 0) {
        QList<double> &h = m_sensorHist[node];
        h.append(s.valueX10 / 10.0);
        if (h.size() > 600)
            h.removeFirst();
    }
}

// SENSOR: last sensor values of one node as named values, for the Gauge page.
// For a node that never sent the frame, "valid" is false.
QVariantMap CanBackend::sensorInfo(int nodeId) const
{
    const SensorData s = m_sensor.value(nodeId);      // empty data if the node is unknown
    QVariantMap m;
    m["node"]     = nodeId;
    m["valid"]    = s.valid;
    m["valueX10"] = s.valueX10;
    m["value"]    = s.valueX10 / 10.0;
    m["mv"]       = s.mv;
    m["volt"]     = s.mv / 1000.0;
    m["fault"]    = (s.flags & 0x01) != 0;
    m["flags"]    = int(s.flags);
    m["counter"]  = int(s.counter);
    m["ageMs"]    = s.valid ? (QDateTime::currentMSecsSinceEpoch() - s.lastMs)
                         : qint64(-1);
    return m;
}

// SENSOR: the values of the last 60 seconds of one node, oldest first.
QVariantList CanBackend::sensorHistory(int nodeId) const
{
    const QList<double> h = m_sensorHist.value(nodeId);
    QVariantList list;
    list.reserve(h.size());
    for (double v : h)
        list.append(v);
    return list;
}

/* ---------- Sensor parameters ---------- */

// Asks the board for every sensor parameter. The old values are forgotten first,
// so the page never shows a mix of old and new data. The points of the table are
// requested when the number of points arrives (see handleParamValue()).
void CanBackend::readSensorParams(int nodeId)
{
    m_params[nodeId] = SensorParams();       // empty: everything is "not received yet"
    readParam(nodeId, PAR_FILTER_MS);
    readParam(nodeId, PAR_LOW_MV);
    readParam(nodeId, PAR_HIGH_MV);
    readParam(nodeId, PAR_NODE_ID);
    for (int i = 0; i < 3; ++i)
        readParam(nodeId, PAR_NAME, i);
    readParam(nodeId, PAR_UNIT);
    readParam(nodeId, PAR_DECIMALS);
    readParam(nodeId, PAR_FAULT_MODE);
    for (int i = 0; i < 3; ++i) {
        readParam(nodeId, PAR_ALARM_ENABLE, i);
        readParam(nodeId, PAR_ALARM_THRESHOLD, i);
        readParam(nodeId, PAR_ALARM_HYST, i);
        readParam(nodeId, PAR_ALARM_DELAY, i);
    }
    readParam(nodeId, PAR_ALARM_STARTUP);
    readParam(nodeId, PAR_SENSOR_PERIOD);
    readParam(nodeId, PAR_TABLE_N);
}

// PARAM_READ frame: [0x30, parameter, index].
void CanBackend::readParam(int nodeId, int param, int index)
{
    QByteArray d;
    d.append(char(CMD_PARAM_READ));
    d.append(char(param));
    d.append(char(index));
    sendFrame(0x600u + quint32(nodeId), d);
}

// PARAM_WRITE frame: [0x31, parameter, index, 0, value x4 (little endian)].
void CanBackend::writeParam(int nodeId, int param, int index, qint64 value)
{
    QByteArray d;
    d.append(char(CMD_PARAM_WRITE));
    d.append(char(param));
    d.append(char(index));
    d.append(char(0));
    d.append(le32(quint32(value)));
    sendFrame(0x600u + quint32(nodeId), d);
}

// Writes a text (name: max 12 bytes, unit: max 4 bytes). The text is padded with
// zeros and sent in pieces of 4 bytes, one WRITE frame for each piece.
void CanBackend::writeText(int nodeId, int param, const QString &text)
{
    if (param != PAR_NAME && param != PAR_UNIT)
        return;
    const int maxLen = (param == PAR_NAME) ? 12 : 4;

    QByteArray b = text.toUtf8();              // "°C" is 3 bytes
    if (b.size() > maxLen) {
        emit paramAck(nodeId, CMD_PARAM_WRITE, param, 5);   // 5 = not valid
        return;
    }
    b = b.leftJustified(maxLen, '\0');         // fill the rest with zeros

    for (int i = 0; i < maxLen / 4; ++i) {
        const quint32 v = quint32(quint8(b[i * 4]))
        | (quint32(quint8(b[i * 4 + 1])) << 8)
            | (quint32(quint8(b[i * 4 + 2])) << 16)
            | (quint32(quint8(b[i * 4 + 3])) << 24);
        writeParam(nodeId, param, i, v);
    }
}
// Sends a whole table: first every point (the board keeps them aside), then the
// number of points, which makes the board check and apply the whole table.
// "points" is a list of {mv: ..., valueX10: ...}, in increasing order of mv.
void CanBackend::writeTable(int nodeId, const QVariantList &points)
{
    const int n = points.size();
    bool ok = (n >= 2 && n <= MAX_TABLE_POINTS);

    // Check the points here too, so an impossible table never goes on the bus.
    for (int i = 0; ok && i < n; ++i) {
        const QVariantMap pt = points[i].toMap();
        const int mv  = pt.value("mv").toInt();
        const int val = pt.value("valueX10").toInt();
        if (mv < 0 || mv > 65535 || val < -32768 || val > 32767)
            ok = false;
        if (i > 0 && mv <= points[i - 1].toMap().value("mv").toInt())
            ok = false;                       // voltages must grow
    }
    if (!ok) {
        emit paramAck(nodeId, CMD_PARAM_WRITE, PAR_TABLE_N, 5);   // 5 = not valid
        return;
    }

    for (int i = 0; i < n; ++i) {
        const QVariantMap pt = points[i].toMap();
        // A point travels in 4 bytes: mV in the low 16 bits, value x10 in the high 16.
        const quint32 packed = quint32(quint16(pt.value("mv").toInt()))
                               | (quint32(quint16(qint16(pt.value("valueX10").toInt()))) << 16);
        writeParam(nodeId, PAR_TABLE_POINT, i, packed);
    }
    writeParam(nodeId, PAR_TABLE_N, 0, n);     // the "confirm"
}

// "Save in NVS": [0x32].
void CanBackend::saveParams(int nodeId)
{
    sendFrame(0x600u + quint32(nodeId), QByteArray(1, char(CMD_PARAM_SAVE)));
}

// "Factory values": [0x33].
void CanBackend::resetParams(int nodeId)
{
    sendFrame(0x600u + quint32(nodeId), QByteArray(1, char(CMD_PARAM_RESET)));
}

// A parameter value arrived from the board.
void CanBackend::handleParamValue(quint8 node, quint8 param, quint8 index, quint32 value)
{
    SensorParams &sp = m_params[node];        // created the first time this node answers

    switch (param) {
    case PAR_FILTER_MS: sp.filterMs = int(value); break;
    case PAR_LOW_MV:    sp.lowMv    = int(value); break;
    case PAR_HIGH_MV:   sp.highMv   = int(value); break;
    case PAR_NODE_ID:   sp.nodeNext = int(value); break;
    case PAR_NAME:
        if (index < 3) {                      // piece "index" of the name: 4 bytes
            sp.nameBytes.replace(index * 4, 4, le32(value));
            sp.nameMask |= quint8(1 << index);
        }
        break;
    case PAR_UNIT:
        sp.unitBytes = le32(value);
        sp.unitOk = true;
        break;
    case PAR_DECIMALS:   sp.decimals  = int(value); break;
    case PAR_FAULT_MODE: sp.faultMode = int(value); break;
    case PAR_ALARM_ENABLE:    if (index < 3) sp.alarmEnabled[index] = int(value); break;
    case PAR_ALARM_THRESHOLD: if (index < 3) sp.alarmThr[index]     = int(value); break;
    case PAR_ALARM_HYST:      if (index < 3) sp.alarmHyst[index]    = int(value); break;
    case PAR_ALARM_DELAY:     if (index < 3) sp.alarmDelay[index]   = int(value); break;
    case PAR_ALARM_STARTUP:   sp.alarmStartup = int(value); break;
    case PAR_SENSOR_PERIOD:   sp.periodMs = int(value); break;
    case PAR_TABLE_N:
        sp.tableN = int(value);
        sp.table.clear();                     // the points are asked again, one by one
        for (int i = 0; i < sp.tableN && i < MAX_TABLE_POINTS; ++i)
            readParam(node, PAR_TABLE_POINT, i);
        break;
    case PAR_TABLE_POINT:
        // mV in the low 16 bits, value x10 (signed) in the high 16 bits.
        sp.table[index] = QPoint(int(value & 0xFFFF), int(qint16(value >> 16)));
        break;
    default:
        return;                               // unknown parameter: ignored
    }
    emit sensorParamsChanged(node);
}

// The board answered a WRITE / SAVE / RESET.
void CanBackend::handleParamAck(quint8 node, quint8 cmd, quint8 param, quint8 status)
{
    emit paramAck(node, cmd, param, status);
    if (status != 0)
        return;                               // error: nothing changed on the board

    // After a good WRITE the value is read again: the page then shows what the
    // board really has. The single points of the table are not read here: the
    // whole table is read when the number of points is confirmed.
    if (cmd == CMD_PARAM_WRITE) {
        if (param == PAR_FILTER_MS || param == PAR_LOW_MV || param == PAR_HIGH_MV
            || param == PAR_TABLE_N || param == PAR_NODE_ID)
            readParam(node, param);
        if (param == PAR_NAME) {
            for (int i = 0; i < 3; ++i)
                readParam(node, PAR_NAME, i);
        } else if (param == PAR_UNIT || param == PAR_DECIMALS || param == PAR_FAULT_MODE) {
            readParam(node, param);
        }
        if (param >= PAR_ALARM_ENABLE && param <= PAR_ALARM_DELAY) {
            for (int i = 0; i < 3; ++i)       // the ACK does not tell which alarm: read all 3
                readParam(node, param, i);
        } else if (param == PAR_ALARM_STARTUP) {
            readParam(node, param);
        }
        if (param == PAR_SENSOR_PERIOD)
            readParam(node, param);
    } else if (cmd == CMD_PARAM_RESET) {
        readSensorParams(node);               // factory values: read everything again
    }
}

// The parameters received from one board, as named values for QML.
QVariantMap CanBackend::sensorParams(int nodeId) const
{
    const SensorParams sp = m_params.value(nodeId);   // empty if the node never answered
    QVariantMap m;
    m["node"]     = nodeId;
    m["known"]    = (sp.filterMs >= 0 || sp.lowMv >= 0 || sp.highMv >= 0 || sp.tableN >= 0);
    m["filterMs"] = sp.filterMs;
    m["lowMv"]    = sp.lowMv;
    m["highMv"]   = sp.highMv;
    m["tableN"]   = sp.tableN;
    m["nodeNext"] = sp.nodeNext;
    m["nameKnown"]  = (sp.nameMask == 7);                          // all 3 pieces arrived
    m["name"]       = QString::fromUtf8(sp.nameBytes.constData()); // ends at the first zero
    m["unitKnown"]  = sp.unitOk;
    m["unit"]       = QString::fromUtf8(sp.unitBytes.constData());
    m["decimals"]   = sp.decimals;
    m["faultMode"]  = sp.faultMode;
    QVariantList alEn, alThr, alHyst, alDelay;
    for (int i = 0; i < 3; ++i) {
        alEn    << sp.alarmEnabled[i];
        alThr   << sp.alarmThr[i];
        alHyst  << sp.alarmHyst[i];
        alDelay << sp.alarmDelay[i];
    }
    m["alarmEnabled"] = alEn;
    m["alarmThr"]     = alThr;
    m["alarmHyst"]    = alHyst;
    m["alarmDelay"]   = alDelay;
    m["alarmStartup"] = sp.alarmStartup;
    m["periodMs"] = sp.periodMs;

    // The points received so far, in order of point number.
    QVariantList table;
    for (auto it = sp.table.cbegin(); it != sp.table.cend(); ++it) {
        QVariantMap pt;
        pt["index"]    = it.key();
        pt["mv"]       = it.value().x();
        pt["volt"]     = it.value().x() / 1000.0;
        pt["valueX10"] = it.value().y();
        pt["value"]    = it.value().y() / 10.0;
        table.append(pt);
    }
    m["table"] = table;
    m["tableComplete"] = (sp.tableN > 0 && sp.table.size() == sp.tableN);
    return m;
}
