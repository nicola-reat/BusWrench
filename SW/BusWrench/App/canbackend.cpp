#include "canbackend.h"

#include <QCanBus>        // Qt CAN Bus API and available CAN plugins.
#include <QCanBusDevice>  // Interface for an opened CAN adapter.
#include <QCanBusFrame>   // Represents an individual CAN frame.
#include <QDebug>         // Debug and diagnostic output.
#include <QVariant>       // Generic value type used for device configuration.
#include <QTimer>         // Periodic adapter detection and reconnection.
// Windows API definitions required by PCAN-Basic.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <Windows.h>
#include <PCANBasic.h>

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

// Interprets the frames sent by the nodes (IDs 0x680..0x6FF).
void CanBackend::handleFrame(const QCanBusFrame &f)
{
    if (f.frameType() != QCanBusFrame::DataFrame || f.hasExtendedFrameFormat())
        return;

    const quint32 id = f.frameId();
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
