#include "updatemanager.h"
#include "canbackend.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QtEndian>

namespace {

// CAN IDs: see can_update_proto.h
constexpr quint32 ID_CMD_BASE   = 0x600;   // PC -> board commands
constexpr quint32 ID_REPLY_BASE = 0x680;   // board -> PC answers
constexpr quint32 ID_DATA_BASE  = 0x700;   // PC -> board file data

// Commands (PC -> board)
constexpr quint8 CMD_BEGIN      = 0x10;
constexpr quint8 CMD_CRC        = 0x11;
constexpr quint8 CMD_BLOCK_END  = 0x12;
constexpr quint8 CMD_FINISH     = 0x13;
constexpr quint8 CMD_ABORT      = 0x14;
constexpr quint8 CMD_ENTER_BOOT = 0x15;

// Answers (board -> PC)
constexpr quint8 MSG_BEGIN_ACK  = 0x90;
constexpr quint8 MSG_BLOCK_ACK  = 0x92;
constexpr quint8 MSG_FINISH_ACK = 0x93;
constexpr quint8 MSG_BOOT_ACK   = 0x95;

constexpr int    BLOCK_SIZE  = 256;        // bytes per block
constexpr int    MAX_RETRIES = 5;          // attempts for the same block
constexpr qint64 MAX_FILE    = 0x380000;   // size of the app area (3.5 MB)

// Appends a number to a frame, little endian.
void put32(QByteArray &b, quint32 v)
{
    for (int i = 0; i < 4; ++i)
        b.append(char((v >> (8 * i)) & 0xFF));
}

void put16(QByteArray &b, quint16 v)
{
    b.append(char(v & 0xFF));
    b.append(char(v >> 8));
}

// Text for the status code sent by the board.
QString statusName(quint8 s)
{
    switch (s) {
    case 1:  return QStringLiteral("the board asked to resend");
    case 2:  return QStringLiteral("file too big for the board");
    case 3:  return QStringLiteral("board busy");
    case 4:  return QStringLiteral("flash error on the board");
    case 5:  return QStringLiteral("invalid file (size, CRC or image)");
    default: return QStringLiteral("unknown error (%1)").arg(s);
    }
}

// Bytes as hexadecimal text, e.g. "10 20 8F 09 00".
QString hexText(const QByteArray &b)
{
    return QString::fromLatin1(b.toHex(' ').toUpper());
}

// One log row for a CAN frame:
//   dir     - "PC >>" (sent by the PC) or "<< BOARD" (sent by the board)
//   id      - CAN identifier
//   data    - bytes of the frame as text
//   meaning - what the frame means
QString frameLine(const QString &dir, quint32 id, const QString &data, const QString &meaning)
{
    return dir.leftJustified(9)
    + QStringLiteral("0x") + QString::number(id, 16).toUpper().rightJustified(3, QLatin1Char('0'))
        + QStringLiteral("  ") + data.leftJustified(23)
        + QStringLiteral("  ") + meaning;
}

// Meaning of a command sent by the PC.
QString describeCmd(const QByteArray &p)
{
    const char *d = p.constData();
    switch (quint8(p[0])) {
    case CMD_ENTER_BOOT: return QStringLiteral("ENTER_BOOT: switch to update mode");
    case CMD_BEGIN:      return p.size() >= 5
                   ? QStringLiteral("BEGIN: file size %1 bytes").arg(qFromLittleEndian<quint32>(d + 1))
                   : QStringLiteral("BEGIN");
    case CMD_CRC:        return p.size() >= 5
                   ? QStringLiteral("CRC: CRC32 of the whole file = %1")
                         .arg(qFromLittleEndian<quint32>(d + 1), 8, 16, QLatin1Char('0'))
                   : QStringLiteral("CRC");
    case CMD_BLOCK_END:  return p.size() >= 5
                   ? QStringLiteral("BLOCK_END: block %1 complete, %2 bytes")
                         .arg(qFromLittleEndian<quint16>(d + 1)).arg(qFromLittleEndian<quint16>(d + 3))
                   : QStringLiteral("BLOCK_END");
    case CMD_FINISH:     return QStringLiteral("FINISH: check size, CRC and image");
    case CMD_ABORT:      return QStringLiteral("ABORT: cancel the update");
    default:             return QStringLiteral("unknown command");
    }
}

// Meaning of an answer sent by the board.
QString describeAnswer(const QByteArray &p)
{
    const quint8 st1 = p.size() >= 2 ? quint8(p[1]) : 0;
    switch (quint8(p[0])) {
    case MSG_BOOT_ACK:   return QStringLiteral("BOOT_ACK: board ready for the update");
    case MSG_BEGIN_ACK:  return st1 == 0 ? QStringLiteral("BEGIN_ACK: OK, new partition erased and ready")
                        : QStringLiteral("BEGIN_ACK: ") + statusName(st1);
    case MSG_BLOCK_ACK: {
        if (p.size() < 4)
            return QStringLiteral("BLOCK_ACK");
        const int block = quint8(p[1]) | (quint8(p[2]) << 8);
        return QStringLiteral("BLOCK_ACK: block %1 %2").arg(block)
            .arg(quint8(p[3]) == 0 ? QStringLiteral("written to flash") : statusName(quint8(p[3])));
    }
    case MSG_FINISH_ACK: return st1 == 0 ? QStringLiteral("FINISH_ACK: OK, image valid, new firmware selected")
                        : QStringLiteral("FINISH_ACK: ") + statusName(st1);
    default:             return QStringLiteral("unknown answer");
    }
}

} // namespace

UpdateManager::UpdateManager(CanBackend *can, QObject *parent)
    : QObject(parent), m_can(can)
{
    m_timer.setSingleShot(true);
    connect(&m_timer, &QTimer::timeout, this, &UpdateManager::onTimeout);

    // Every answer of a board arrives here.
    connect(m_can, &CanBackend::frameReceived, this, &UpdateManager::onFrame);
}

// Standard CRC-32 (same result as esp_crc32_le(0, ...) on the ESP32).
quint32 UpdateManager::crc32(const QByteArray &data)
{
    quint32 crc = 0xFFFFFFFFu;
    for (const char c : data) {
        crc ^= quint8(c);
        for (int i = 0; i < 8; ++i)
            crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}

void UpdateManager::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void UpdateManager::setStatus(const QString &text)
{
    m_status = text;
    emit statusChanged();
}

// During the transfer only some blocks are written in the log, otherwise the
// list would have thousands of rows: the first two, the last one and every
// block that is being sent again. Errors are always written.
bool UpdateManager::detailed(int block) const
{
    return block < 2 || block >= m_blockCount - 1 || m_retries > 0;
}

// Adds a line to the log (QML) and to the Application Output (Qt Creator).
void UpdateManager::log(const QString &text)
{
    const QString line = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"))
    + QStringLiteral("  ") + text;
    qDebug().noquote() << "[UPDATE]" << line;

    m_log.append(line);
    if (m_log.size() > 500)
        m_log.removeFirst();
    emit logChanged();
}

// Reads the .bin file and computes size, CRC32, SHA-256 and version.
void UpdateManager::loadFile(const QUrl &url)
{
    if (m_busy)
        return;

    const QString path = url.isLocalFile() ? url.toLocalFile() : url.toString();
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        log(QStringLiteral("Cannot open file: ") + path);
        return;
    }

    const QByteArray data = f.readAll();
    if (data.isEmpty() || data.size() > MAX_FILE) {
        log(QStringLiteral("Invalid file size: %1 bytes").arg(data.size()));
        return;
    }

    m_data = data;
    m_crc = crc32(data);
    m_fileName = QFileInfo(path).fileName();
    m_fileSize = QString::number(data.size() / 1048576.0, 'f', 2) + QStringLiteral(" MB");

    const QByteArray sha = QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex();
    m_fileSha = QString::fromLatin1(sha.left(6)) + QStringLiteral("...")
                + QString::fromLatin1(sha.right(4));

    // An ESP32 image starts with the byte 0xE9. The version (project version
    // set in CMake) is inside the application descriptor, at offset 48.
    m_isEsp = (quint8(data[0]) == 0xE9);
    m_fileVersion = QStringLiteral("-");
    if (m_isEsp && data.size() >= 112
        && qFromLittleEndian<quint32>(data.constData() + 32) == 0xABCD5432u) {
        const char *v = data.constData() + 48;
        m_fileVersion = QString::fromLatin1(v, int(qstrnlen(v, 32)));
    }

    m_progress = 0.0;
    m_eta = QStringLiteral("--:--");
    emit progressChanged();
    emit fileChanged();

    setStatus(m_isEsp ? QStringLiteral("File ready")
                      : QStringLiteral("This is not an ESP32 image"));
    log(QStringLiteral("File loaded: %1, %2 bytes, CRC32 %3")
            .arg(m_fileName).arg(data.size()).arg(m_crc, 8, 16, QLatin1Char('0')));
}

void UpdateManager::start(int nodeId)
{
    if (m_busy)
        return;
    if (m_data.isEmpty()) {
        log(QStringLiteral("No firmware file loaded"));
        return;
    }
    if (!m_isEsp) {
        // For now only ESP32 images are accepted. The STM32 will come later.
        log(QStringLiteral("This file is not an ESP32 image: update refused"));
        setStatus(QStringLiteral("Invalid file"));
        return;
    }
    if (!m_can->connected()) {
        log(QStringLiteral("CAN adapter not connected"));
        setStatus(QStringLiteral("CAN adapter not connected"));
        return;
    }
    if (nodeId <= 0 || nodeId > 0x7F) {
        log(QStringLiteral("Invalid node ID"));
        return;
    }

    m_node = nodeId;
    m_block = 0;
    m_retries = 0;
    m_blockCount = (m_data.size() + BLOCK_SIZE - 1) / BLOCK_SIZE;
    m_progress = 0.0;
    m_eta = QStringLiteral("--:--");
    emit progressChanged();
    m_elapsed.start();
    m_nextLogPct = 10;
    setBusy(true);
    log(QStringLiteral("Update started on node 0x%1").arg(m_node, 2, 16, QLatin1Char('0')));
    setStatus(QStringLiteral("Entering update mode..."));

    m_state = EnterBoot;
    sendCmd(QByteArray(1, char(CMD_ENTER_BOOT)));
    m_timer.start(2000);                       // the board must answer in 2 s
}

void UpdateManager::abort()
{
    if (m_state == Idle)
        return;
    m_timer.stop();
    sendCmd(QByteArray(1, char(CMD_ABORT)));
    m_state = Idle;
    log(QStringLiteral("Update cancelled"));
    setStatus(QStringLiteral("Cancelled"));
    setBusy(false);
    emit finished(false);
}

// Sends a command frame to the node (ID 0x600 + node) and writes it in the log.
void UpdateManager::sendCmd(const QByteArray &payload)
{
    const quint32 id = ID_CMD_BASE + quint32(m_node);

    // The BLOCK_END of the middle blocks is not listed (thousands of rows).
    const bool isBlockEnd = !payload.isEmpty() && quint8(payload[0]) == CMD_BLOCK_END;
    if (!isBlockEnd || detailed(m_block))
        log(frameLine(QStringLiteral("PC >>"), id, hexText(payload), describeCmd(payload)));

    m_can->sendFrame(id, payload);
}

// BEGIN (file size) and CRC (file checksum), sent one after the other.
void UpdateManager::sendBegin()
{
    QByteArray a;
    a.append(char(CMD_BEGIN));
    put32(a, quint32(m_data.size()));
    sendCmd(a);

    QByteArray c;
    c.append(char(CMD_CRC));
    put32(c, m_crc);
    sendCmd(c);

    setStatus(QStringLiteral("Preparing the flash..."));
    m_timer.start(15000);                      // flash preparation can take a while
}

// Sends one block: data frames of 8 bytes, then BLOCK_END.
void UpdateManager::sendBlock()
{
    const int offset = m_block * BLOCK_SIZE;
    const int len = qMin(BLOCK_SIZE, int(m_data.size()) - offset);

    for (int i = 0; i < len; i += 8) {
        const QByteArray chunk = m_data.mid(offset + i, qMin(8, len - i));
        if (!m_can->sendFrame(ID_DATA_BASE + quint32(m_node), chunk)) {
            fail(QStringLiteral("CAN adapter not available"));
            return;
        }
    }
    // The single data frames are not listed: one row is enough.
    if (detailed(m_block))
        log(frameLine(QStringLiteral("PC >>"), ID_DATA_BASE + quint32(m_node),
                      QStringLiteral("[%1 frames x 8 bytes]").arg((len + 7) / 8),
                      QStringLiteral("DATA: block %1, bytes %2..%3 of the file")
                          .arg(m_block).arg(offset).arg(offset + len - 1)));
    QByteArray e;
    e.append(char(CMD_BLOCK_END));
    put16(e, quint16(m_block));
    put16(e, quint16(len));
    sendCmd(e);

    m_timer.start(2000);                       // the board must confirm the block
}

void UpdateManager::retryBlock(const QString &reason)
{
    if (++m_retries > MAX_RETRIES) {
        fail(QStringLiteral("block %1: too many retries").arg(m_block));
        return;
    }
    log(QStringLiteral("Block %1: %2, sending again (%3/%4)")
            .arg(m_block).arg(reason).arg(m_retries).arg(MAX_RETRIES));
    sendBlock();
}

// Answers of the board.
void UpdateManager::onFrame(quint32 id, const QByteArray &p)
{
    if (m_state == Idle || id != ID_REPLY_BASE + quint32(m_node) || p.isEmpty())
        return;

    // Write the answer in the log. Heartbeats are not listed, and the answers
    // to the middle blocks are listed only if they report a problem.
    const quint8 type = quint8(p[0]);
    if (type == MSG_BOOT_ACK || type == MSG_BEGIN_ACK || type == MSG_FINISH_ACK
        || (type == MSG_BLOCK_ACK && p.size() >= 4
            && (quint8(p[3]) != 0 || detailed(quint8(p[1]) | (quint8(p[2]) << 8)))))
        log(frameLine(QStringLiteral("<< BOARD"), id, hexText(p), describeAnswer(p)));

    switch (quint8(p[0])) {

    case MSG_BOOT_ACK:                         // the board is ready
        if (m_state == EnterBoot) {
            m_state = Begin;
            sendBegin();
        }
        break;

    case MSG_BEGIN_ACK: {                      // the flash is ready (or an error)
        if (m_state != Begin || p.size() < 2)
            break;
        const quint8 st = quint8(p[1]);
        if (st != 0) {
            fail(statusName(st));
            break;
        }
        log(QStringLiteral("Flash ready, transfer started (%1 blocks)").arg(m_blockCount));
        m_state = SendBlock;
        m_block = 0;
        m_retries = 0;
        setStatus(QStringLiteral("Transferring..."));
        sendBlock();
        break;
    }

    case MSG_BLOCK_ACK: {                      // a block was received
        if (m_state != SendBlock || p.size() < 4)
            break;
        const int block = quint8(p[1]) | (quint8(p[2]) << 8);
        const quint8 st = quint8(p[3]);
        if (block != m_block)
            break;                             // old or duplicated answer

        if (st == 0) {
            m_retries = 0;
            ++m_block;
            updateProgress();
            if (m_block >= m_blockCount) {     // all blocks sent: final check
                m_state = Finish;
                setStatus(QStringLiteral("Verifying..."));
                sendCmd(QByteArray(1, char(CMD_FINISH)));
                m_timer.start(10000);
            } else {
                sendBlock();
            }
        } else if (st == 1) {
            retryBlock(QStringLiteral("the board asked to resend"));
        } else {
            fail(statusName(st));
        }
        break;
    }

    case MSG_FINISH_ACK: {                     // final check done
        if (m_state != Finish || p.size() < 2)
            break;
        const quint8 st = quint8(p[1]);
        if (st == 0)
            succeed();
        else
            fail(statusName(st));
        break;
    }

    default:
        break;
    }
}

// The board did not answer in time.
void UpdateManager::onTimeout()
{
    switch (m_state) {
    case EnterBoot:
        fail(QStringLiteral("no answer from the board (check the node ID)"));
        break;
    case Begin:
        fail(QStringLiteral("the board did not prepare its flash in time"));
        break;
    case SendBlock:
        retryBlock(QStringLiteral("no answer"));
        break;
    case Finish:
        fail(QStringLiteral("no answer to the final check: scan again to see if the board restarted"));
        break;
    default:
        break;
    }
}

// Progress and remaining time.
void UpdateManager::updateProgress()
{
    const qint64 sent = qMin<qint64>(qint64(m_block) * BLOCK_SIZE, m_data.size());
    m_progress = double(sent) / double(m_data.size());

    if (m_progress > 0.02) {
        const int remaining = int(m_elapsed.elapsed() * (1.0 - m_progress) / m_progress / 1000.0);
        m_eta = QStringLiteral("%1:%2")
                    .arg(remaining / 60, 2, 10, QLatin1Char('0'))
                    .arg(remaining % 60, 2, 10, QLatin1Char('0'));
    } else {
        m_eta = QStringLiteral("--:--");
    }
    emit progressChanged();
    // One log line every 10 %.
    const int pct = int(m_progress * 100.0);
    if (pct >= m_nextLogPct) {
        log(QStringLiteral("Progress %1% (block %2 of %3)").arg(pct).arg(m_block).arg(m_blockCount));
        m_nextLogPct = (pct / 10 + 1) * 10;
    }
}

// Error: the board is told to cancel, and keeps its old firmware.
void UpdateManager::fail(const QString &reason)
{
    m_timer.stop();
    if (m_state != Idle)
        sendCmd(QByteArray(1, char(CMD_ABORT)));
    m_state = Idle;

    log(QStringLiteral("ERROR: ") + reason);
    setStatus(QStringLiteral("Error: ") + reason);
    setBusy(false);
    emit finished(false);
}

void UpdateManager::succeed()
{
    m_timer.stop();
    m_state = Idle;
    m_progress = 1.0;
    emit progressChanged();

    log(QStringLiteral("Update completed in %1 s. The board is restarting.")
            .arg(m_elapsed.elapsed() / 1000));
    setStatus(QStringLiteral("Update completed"));
    setBusy(false);
    emit finished(true);
}

