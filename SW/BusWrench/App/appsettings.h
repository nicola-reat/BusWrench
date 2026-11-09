#pragma once

#include <QObject>

/*
 * AppSettings keeps the user settings on disk (QSettings), so they are still
 * there after the program is closed. QML reads and writes them directly:
 *   settings.bitrate      CAN speed in kbit/s (125, 250, 500, 1000)
 *   settings.autoRescan   scan the bus again after a firmware update
 */
class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int bitrate READ bitrate WRITE setBitrate NOTIFY bitrateChanged)
    Q_PROPERTY(bool autoRescan READ autoRescan WRITE setAutoRescan NOTIFY autoRescanChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    int bitrate() const { return m_bitrate; }
    bool autoRescan() const { return m_autoRescan; }

    void setBitrate(int kbit);
    void setAutoRescan(bool on);

signals:
    void bitrateChanged();
    void autoRescanChanged();

private:
    int m_bitrate = 500;
    bool m_autoRescan = true;
};
