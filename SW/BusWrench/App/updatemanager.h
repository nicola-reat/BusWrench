#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QUrl>

class CanBackend;

/*
 * OVERVIEW
 * --------
 * UpdateManager sends a firmware file (.bin) to a board through the CAN bus.
 * The protocol is described in can_update_proto.h (same on PC and boards).
 *
 * Main responsibilities:
 *   1. Load the file and compute its size, CRC32, SHA-256 and version.
 *   2. Run the transfer: ENTER_BOOT, BEGIN, blocks of 256 bytes, FINISH.
 *   3. After every block wait for the board's confirmation and send the
 *      block again if the answer is missing or negative.
 *   4. Expose progress, remaining time, status text and log to QML.
 *
 * The class does not draw anything: QML reads its properties.
 * It uses CanBackend only to send frames and to receive the board's answers.
 */

class UpdateManager : public QObject
{
    Q_OBJECT

    // Transfer state, read by the Update page.
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)      // 0.0 ... 1.0
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(QString etaText READ etaText NOTIFY progressChanged)       // mm:ss
    Q_PROPERTY(QStringList logLines READ logLines NOTIFY logChanged)

    // Information about the loaded file ("File information" box).
    Q_PROPERTY(bool fileLoaded READ fileLoaded NOTIFY fileChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY fileChanged)
    Q_PROPERTY(QString fileVersion READ fileVersion NOTIFY fileChanged)
    Q_PROPERTY(QString fileSize READ fileSize NOTIFY fileChanged)
    Q_PROPERTY(QString fileSha READ fileSha NOTIFY fileChanged)

public:
    explicit UpdateManager(CanBackend *can, QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    double progress() const { return m_progress; }
    QString statusText() const { return m_status; }
    QString etaText() const { return m_eta; }
    QStringList logLines() const { return m_log; }

    bool fileLoaded() const { return !m_data.isEmpty(); }
    QString fileName() const { return m_fileName; }
    QString fileVersion() const { return m_fileVersion; }
    QString fileSize() const { return m_fileSize; }
    QString fileSha() const { return m_fileSha; }

    // Reads the firmware file and computes its information.
    Q_INVOKABLE void loadFile(const QUrl &url);

    // Starts the update of the node with the given ID (e.g. 0x45).
    Q_INVOKABLE void start(int nodeId);

    // Cancels the update in progress (the board keeps its old firmware).
    Q_INVOKABLE void abort();

signals:
    void busyChanged();
    void progressChanged();
    void statusChanged();
    void logChanged();
    void fileChanged();
    void finished(bool ok);

private:
    enum State { Idle, EnterBoot, Begin, SendBlock, Finish };

    void onFrame(quint32 id, const QByteArray &payload);   // answers of the board
    void onTimeout();                                      // no answer in time
    void sendCmd(const QByteArray &payload);               // command to the node
    void sendBegin();
    void sendBlock();
    void retryBlock(const QString &reason);
    void fail(const QString &reason);
    void succeed();
    void updateProgress();
    void setBusy(bool busy);
    void setStatus(const QString &text);
    void log(const QString &text);
    bool detailed(int block) const;   // write the frames of this block in the log?
    int m_nextLogPct = 10;            // next percentage to write in the log
    static quint32 crc32(const QByteArray &data);

    CanBackend *m_can = nullptr;
    QTimer m_timer;                // timeout of the answer we are waiting for
    QElapsedTimer m_elapsed;       // time since the start (remaining time)

    State m_state = Idle;
    int m_node = 0;                // node ID of the board being updated
    int m_block = 0;               // block we are sending / waiting for
    int m_blockCount = 0;
    int m_retries = 0;

    QByteArray m_data;             // content of the .bin file
    quint32 m_crc = 0;
    bool m_isEsp = false;          // the file looks like an ESP32 image

    bool m_busy = false;
    double m_progress = 0.0;
    QString m_status = QStringLiteral("Select a firmware file");
    QString m_eta = QStringLiteral("--:--");
    QStringList m_log;

    QString m_fileName;
    QString m_fileVersion = QStringLiteral("-");
    QString m_fileSize = QStringLiteral("-");
    QString m_fileSha = QStringLiteral("-");
};
