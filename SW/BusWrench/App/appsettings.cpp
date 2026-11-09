#include "appsettings.h"

#include <QSettings>

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
{
    // Read the saved values (the second argument is the default if nothing is saved yet).
    QSettings s;
    m_bitrate = s.value("can/bitrate", 500).toInt();
    m_autoRescan = s.value("update/autoRescan", true).toBool();
}

void AppSettings::setBitrate(int kbit)
{
    // Only the speeds shown in the Settings page are accepted.
    if (kbit != 125 && kbit != 250 && kbit != 500 && kbit != 1000)
        return;
    if (kbit == m_bitrate)
        return;
    m_bitrate = kbit;
    QSettings().setValue("can/bitrate", m_bitrate);
    emit bitrateChanged();
}

void AppSettings::setAutoRescan(bool on)
{
    if (on == m_autoRescan)
        return;
    m_autoRescan = on;
    QSettings().setValue("update/autoRescan", m_autoRescan);
    emit autoRescanChanged();
}
