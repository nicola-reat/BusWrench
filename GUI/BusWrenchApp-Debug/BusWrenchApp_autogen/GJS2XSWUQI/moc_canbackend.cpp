/****************************************************************************
** Meta object code from reading C++ file 'canbackend.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.12.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../SW/BusWrench/App/canbackend.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'canbackend.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.12.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN10CanBackendE_t {};
} // unnamed namespace

template <> constexpr inline auto CanBackend::qt_create_metaobjectdata<qt_meta_tag_ZN10CanBackendE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "CanBackend",
        "statusChanged",
        "",
        "rxCountChanged",
        "frameReceived",
        "id",
        "payload",
        "actionResult",
        "nodeId",
        "cmd",
        "result",
        "sensorParamsChanged",
        "paramAck",
        "param",
        "status",
        "connectBus",
        "disconnectBus",
        "scan",
        "requestDetails",
        "sendAction",
        "applyBitrate",
        "kbit",
        "sensorInfo",
        "QVariantMap",
        "sensorHistory",
        "QVariantList",
        "readSensorParams",
        "readParam",
        "index",
        "writeParam",
        "value",
        "writeTable",
        "points",
        "saveParams",
        "resetParams",
        "sensorParams",
        "writeText",
        "text",
        "connected",
        "statusTitle",
        "statusDetail",
        "rxCount",
        "lastFrame",
        "devices",
        "DeviceModel*"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'statusChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'rxCountChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'frameReceived'
        QtMocHelpers::SignalData<void(quint32, const QByteArray &)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::UInt, 5 }, { QMetaType::QByteArray, 6 },
        }}),
        // Signal 'actionResult'
        QtMocHelpers::SignalData<void(int, int, int)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 9 }, { QMetaType::Int, 10 },
        }}),
        // Signal 'sensorParamsChanged'
        QtMocHelpers::SignalData<void(int)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 },
        }}),
        // Signal 'paramAck'
        QtMocHelpers::SignalData<void(int, int, int, int)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 9 }, { QMetaType::Int, 13 }, { QMetaType::Int, 14 },
        }}),
        // Method 'connectBus'
        QtMocHelpers::MethodData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'disconnectBus'
        QtMocHelpers::MethodData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'scan'
        QtMocHelpers::MethodData<void()>(17, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'requestDetails'
        QtMocHelpers::MethodData<void(int)>(18, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'sendAction'
        QtMocHelpers::MethodData<void(int, int)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 9 },
        }}),
        // Method 'applyBitrate'
        QtMocHelpers::MethodData<void(int)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 21 },
        }}),
        // Method 'sensorInfo'
        QtMocHelpers::MethodData<QVariantMap(int) const>(22, 2, QMC::AccessPublic, 0x80000000 | 23, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'sensorHistory'
        QtMocHelpers::MethodData<QVariantList(int) const>(24, 2, QMC::AccessPublic, 0x80000000 | 25, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'readSensorParams'
        QtMocHelpers::MethodData<void(int)>(26, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'readParam'
        QtMocHelpers::MethodData<void(int, int, int)>(27, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 13 }, { QMetaType::Int, 28 },
        }}),
        // Method 'readParam'
        QtMocHelpers::MethodData<void(int, int)>(27, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 13 },
        }}),
        // Method 'writeParam'
        QtMocHelpers::MethodData<void(int, int, int, qint64)>(29, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 13 }, { QMetaType::Int, 28 }, { QMetaType::LongLong, 30 },
        }}),
        // Method 'writeTable'
        QtMocHelpers::MethodData<void(int, const QVariantList &)>(31, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { 0x80000000 | 25, 32 },
        }}),
        // Method 'saveParams'
        QtMocHelpers::MethodData<void(int)>(33, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'resetParams'
        QtMocHelpers::MethodData<void(int)>(34, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'sensorParams'
        QtMocHelpers::MethodData<QVariantMap(int) const>(35, 2, QMC::AccessPublic, 0x80000000 | 23, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'writeText'
        QtMocHelpers::MethodData<void(int, int, const QString &)>(36, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 }, { QMetaType::Int, 13 }, { QMetaType::QString, 37 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'connected'
        QtMocHelpers::PropertyData<bool>(38, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'statusTitle'
        QtMocHelpers::PropertyData<QString>(39, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'statusDetail'
        QtMocHelpers::PropertyData<QString>(40, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'rxCount'
        QtMocHelpers::PropertyData<int>(41, QMetaType::Int, QMC::DefaultPropertyFlags, 1),
        // property 'lastFrame'
        QtMocHelpers::PropertyData<QString>(42, QMetaType::QString, QMC::DefaultPropertyFlags, 1),
        // property 'devices'
        QtMocHelpers::PropertyData<DeviceModel*>(43, 0x80000000 | 44, QMC::DefaultPropertyFlags | QMC::EnumOrFlag | QMC::Constant),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<CanBackend, qt_meta_tag_ZN10CanBackendE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject CanBackend::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10CanBackendE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10CanBackendE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN10CanBackendE_t>.metaTypes,
    nullptr
} };

void CanBackend::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<CanBackend *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->statusChanged(); break;
        case 1: _t->rxCountChanged(); break;
        case 2: _t->frameReceived((*reinterpret_cast<std::add_pointer_t<quint32>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QByteArray>>(_a[2]))); break;
        case 3: _t->actionResult((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 4: _t->sensorParamsChanged((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 5: _t->paramAck((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 6: _t->connectBus(); break;
        case 7: _t->disconnectBus(); break;
        case 8: _t->scan(); break;
        case 9: _t->requestDetails((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 10: _t->sendAction((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 11: _t->applyBitrate((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 12: { QVariantMap _r = _t->sensorInfo((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 13: { QVariantList _r = _t->sensorHistory((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 14: _t->readSensorParams((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 15: _t->readParam((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 16: _t->readParam((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 17: _t->writeParam((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<qint64>>(_a[4]))); break;
        case 18: _t->writeTable((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QVariantList>>(_a[2]))); break;
        case 19: _t->saveParams((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 20: _t->resetParams((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 21: { QVariantMap _r = _t->sensorParams((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 22: _t->writeText((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[3]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (CanBackend::*)()>(_a, &CanBackend::statusChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanBackend::*)()>(_a, &CanBackend::rxCountChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanBackend::*)(quint32 , const QByteArray & )>(_a, &CanBackend::frameReceived, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanBackend::*)(int , int , int )>(_a, &CanBackend::actionResult, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanBackend::*)(int )>(_a, &CanBackend::sensorParamsChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (CanBackend::*)(int , int , int , int )>(_a, &CanBackend::paramAck, 5))
            return;
    }
    if (_c == QMetaObject::RegisterPropertyMetaType) {
        switch (_id) {
        default: *reinterpret_cast<int*>(_a[0]) = -1; break;
        case 5:
            *reinterpret_cast<int*>(_a[0]) = qRegisterMetaType< DeviceModel* >(); break;
        }
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<bool*>(_v) = _t->connected(); break;
        case 1: *reinterpret_cast<QString*>(_v) = _t->statusTitle(); break;
        case 2: *reinterpret_cast<QString*>(_v) = _t->statusDetail(); break;
        case 3: *reinterpret_cast<int*>(_v) = _t->rxCount(); break;
        case 4: *reinterpret_cast<QString*>(_v) = _t->lastFrame(); break;
        case 5: *reinterpret_cast<DeviceModel**>(_v) = _t->devices(); break;
        default: break;
        }
    }
}

const QMetaObject *CanBackend::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *CanBackend::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10CanBackendE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int CanBackend::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 23)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 23;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 23)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 23;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    }
    return _id;
}

// SIGNAL 0
void CanBackend::statusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void CanBackend::rxCountChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void CanBackend::frameReceived(quint32 _t1, const QByteArray & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1, _t2);
}

// SIGNAL 3
void CanBackend::actionResult(int _t1, int _t2, int _t3)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1, _t2, _t3);
}

// SIGNAL 4
void CanBackend::sensorParamsChanged(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void CanBackend::paramAck(int _t1, int _t2, int _t3, int _t4)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1, _t2, _t3, _t4);
}
QT_WARNING_POP
