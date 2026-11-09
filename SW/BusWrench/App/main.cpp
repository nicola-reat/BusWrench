// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QApplication>
#include <QQmlApplicationEngine>

#include "autogen/environment.h"
#include <QQmlContext>
#include "canbackend.h"
#include "updatemanager.h"
#include "appsettings.h"          // user settings
#include <QIcon>
#include "nodeconfig.h"                     // list of the known nodes
int main(int argc, char *argv[])
{
    set_qt_environment();
    QApplication app(argc, argv);
    // Icon of the window and of the taskbar
    app.setWindowIcon(QIcon(":/icons/icon-256.png"));
    // Names used by QSettings to decide where the settings are saved.
    QCoreApplication::setOrganizationName("BusWrench");
    QCoreApplication::setApplicationName("BusWrench");
    QQmlApplicationEngine engine;

    AppSettings settings; //created after the names above are set
    engine.rootContext()->setContextProperty("settings", &settings);
    NodeConfig nodes;                       // known nodes (ID, name, icon), saved on disk
    engine.rootContext()->setContextProperty("nodes", &nodes);   // visible in QML as "nodes"
    CanBackend can;
    can.devices()->setNodeConfig(&nodes);   // the device cards read name and icon from here
    engine.rootContext()->setContextProperty("can", &can);
    UpdateManager updater(&can);
    engine.rootContext()->setContextProperty("updater", &updater);
    can.setBitrate(settings.bitrate());      // speed saved in the settings
    can.connectBus(); //Activate bus
    const QUrl url(mainQmlFile);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");
    engine.addImportPath(":/");
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
