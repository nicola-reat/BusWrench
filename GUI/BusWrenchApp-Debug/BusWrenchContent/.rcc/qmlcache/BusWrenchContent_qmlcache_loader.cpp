#include <QtQml/qqmlprivate.h>
#include <QtCore/qdir.h>
#include <QtCore/qurl.h>
#include <QtCore/qhash.h>
#include <QtCore/qstring.h>

namespace QmlCacheGeneratedCode {
namespace _qt_qml_BusWrenchContent_App_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}
namespace _qt_qml_BusWrenchContent_DeviceCard_ui_0x2e_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}
namespace _qt_qml_BusWrenchContent_PageDevices_ui_0x2e_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}
namespace _qt_qml_BusWrenchContent_PageUpdate_ui_0x2e_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}
namespace _qt_qml_BusWrenchContent_Screen01_ui_0x2e_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}
namespace _qt_qml_BusWrenchContent_PageSettings_ui_0x2e_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}
namespace _qt_qml_BusWrenchContent_PageDetails_ui_0x2e_qml { 
    extern bool validateLookupSignatures(QQmlEngine *engine, QV4::CompiledData::CompilationUnit *cu);
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], &validateLookupSignatures
    };
}

}
namespace {
struct Registry {
    Registry();
    ~Registry();
    QHash<QString, const QQmlPrivate::CachedQmlUnit*> resourcePathToCachedUnit;
    static const QQmlPrivate::CachedQmlUnit *lookupCachedUnit(const QUrl &url);
};

Q_GLOBAL_STATIC(Registry, unitRegistry)


Registry::Registry() {
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/App.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_App_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/DeviceCard.ui.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_DeviceCard_ui_0x2e_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/PageDevices.ui.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_PageDevices_ui_0x2e_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/PageUpdate.ui.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_PageUpdate_ui_0x2e_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/Screen01.ui.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_Screen01_ui_0x2e_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/PageSettings.ui.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_PageSettings_ui_0x2e_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/BusWrenchContent/PageDetails.ui.qml"), &QmlCacheGeneratedCode::_qt_qml_BusWrenchContent_PageDetails_ui_0x2e_qml::unit);
    QQmlPrivate::RegisterQmlUnitCacheHook registration;
    registration.structVersion = 0;
    registration.lookupCachedQmlUnit = &lookupCachedUnit;
    QQmlPrivate::qmlregister(QQmlPrivate::QmlUnitCacheHookRegistration, &registration);
}

Registry::~Registry() {
    QQmlPrivate::qmlunregister(QQmlPrivate::QmlUnitCacheHookRegistration, quintptr(&lookupCachedUnit));
}

const QQmlPrivate::CachedQmlUnit *Registry::lookupCachedUnit(const QUrl &url) {
    if (url.scheme() != QLatin1String("qrc"))
        return nullptr;
    QString resourcePath = QDir::cleanPath(url.path());
    if (resourcePath.isEmpty())
        return nullptr;
    if (!resourcePath.startsWith(QLatin1Char('/')))
        resourcePath.prepend(QLatin1Char('/'));
    return unitRegistry()->resourcePathToCachedUnit.value(resourcePath, nullptr);
}
}
int QT_MANGLE_NAMESPACE(qInitResources_qmlcache_BusWrenchContent)() {
    ::unitRegistry();
    return 1;
}
Q_CONSTRUCTOR_FUNCTION(QT_MANGLE_NAMESPACE(qInitResources_qmlcache_BusWrenchContent))
int QT_MANGLE_NAMESPACE(qCleanupResources_qmlcache_BusWrenchContent)() {
    return 1;
}
