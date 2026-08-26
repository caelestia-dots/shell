#include "hyprdevices.hpp"

#include <qjsonarray.h>

#include "../Config/rootnodes.hpp"
#include "../toaster.hpp"

namespace caelestia::services::hypr {

using Qt::StringLiterals::operator""_s;

namespace {

const config::UtilitiesToasts* toastConfig() {
    return config::ConfigSingleton::instance()->utilities()->toasts();
}

void toastCapsLock(bool enabled) {
    if (!toastConfig()->capsLockChanged())
        return;

    // TODO: tr when translations added
    Toaster::instance()->toast(enabled ? u"Caps lock enabled"_s : u"Caps lock disabled"_s,
        enabled ? u"Caps lock is currently enabled"_s : u"Caps lock is currently disabled"_s,
        enabled ? u"keyboard_capslock_badge"_s : u"keyboard_capslock"_s);
}

void toastNumLock(bool enabled) {
    if (!toastConfig()->numLockChanged())
        return;

    // TODO: tr when translations added
    Toaster::instance()->toast(enabled ? u"Num lock enabled"_s : u"Num lock disabled"_s,
        enabled ? u"Num lock is currently enabled"_s : u"Num lock is currently disabled"_s,
        enabled ? u"looks_one"_s : u"timer_1"_s);
}

void toastKbLayout(const QString& layout) {
    if (!toastConfig()->kbLayoutChanged())
        return;

    // TODO: tr when translations added
    Toaster::instance()->toast(u"Keyboard layout changed"_s, u"Layout changed to: %1"_s.arg(layout), u"keyboard"_s);
}

} // namespace

HyprKeyboard::HyprKeyboard(QJsonObject ipcObject, QObject* parent)
    : QObject(parent)
    , m_lastIpcObject(ipcObject) {}

QVariantHash HyprKeyboard::lastIpcObject() const {
    return m_lastIpcObject.toVariantHash();
}

QString HyprKeyboard::address() const {
    return m_lastIpcObject.value("address").toString();
}

QString HyprKeyboard::name() const {
    return m_lastIpcObject.value("name").toString();
}

QString HyprKeyboard::layout() const {
    return m_lastIpcObject.value("layout").toString();
}

QString HyprKeyboard::activeKeymap() const {
    return m_lastIpcObject.value("active_keymap").toString();
}

bool HyprKeyboard::capsLock() const {
    return m_lastIpcObject.value("capsLock").toBool();
}

bool HyprKeyboard::numLock() const {
    return m_lastIpcObject.value("numLock").toBool();
}

bool HyprKeyboard::main() const {
    return m_lastIpcObject.value("main").toBool();
}

bool HyprKeyboard::updateLastIpcObject(QJsonObject object) {
    if (m_lastIpcObject == object) {
        return false;
    }

    const auto last = m_lastIpcObject;
    const auto isMain = object.value("main").toBool();

    m_lastIpcObject = object;
    emit lastIpcObjectChanged();

    bool dirty = false;
    if (last.value("address") != object.value("address")) {
        dirty = true;
        emit addressChanged();
    }
    if (last.value("name") != object.value("name")) {
        dirty = true;
        emit nameChanged();
    }
    if (last.value("layout") != object.value("layout")) {
        dirty = true;
        emit layoutChanged();
    }
    if (last.value("active_keymap") != object.value("active_keymap")) {
        dirty = true;
        emit activeKeymapChanged();
        if (isMain && !last.value("active_keymap").toString().isEmpty())
            toastKbLayout(object.value("active_keymap").toString());
    }
    if (last.value("capsLock") != object.value("capsLock")) {
        dirty = true;
        emit capsLockChanged();
        if (isMain)
            toastCapsLock(object.value("capsLock").toBool());
    }
    if (last.value("numLock") != object.value("numLock")) {
        dirty = true;
        emit numLockChanged();
        if (isMain)
            toastNumLock(object.value("numLock").toBool());
    }
    if (last.value("main") != object.value("main")) {
        dirty = true;
        emit mainChanged();
    }
    return dirty;
}

HyprDevices::HyprDevices(QObject* parent)
    : QObject(parent) {}

QQmlListProperty<HyprKeyboard> HyprDevices::keyboards() {
    return QQmlListProperty<HyprKeyboard>(this, &m_keyboards);
}

bool HyprDevices::updateLastIpcObject(QJsonObject object) {
    const auto val = object.value("keyboards").toArray();
    bool dirty = false;

    for (auto it = m_keyboards.begin(); it != m_keyboards.end();) {
        auto* const keyboard = *it;
        const auto inNewValues = std::any_of(val.begin(), val.end(), [keyboard](const QJsonValue& o) {
            return o.toObject().value("address").toString() == keyboard->address();
        });

        if (!inNewValues) {
            dirty = true;
            it = m_keyboards.erase(it);
            keyboard->deleteLater();
        } else {
            ++it;
        }
    }

    for (const auto& o : val) {
        const auto obj = o.toObject();
        const auto addr = obj.value("address").toString();

        auto it = std::find_if(m_keyboards.begin(), m_keyboards.end(), [addr](const HyprKeyboard* kb) {
            return kb->address() == addr;
        });

        if (it != m_keyboards.end()) {
            dirty |= (*it)->updateLastIpcObject(obj);
        } else {
            dirty = true;
            m_keyboards << new HyprKeyboard(obj, this);
        }
    }

    if (dirty) {
        emit keyboardsChanged();
    }

    return dirty;
}

} // namespace caelestia::services::hypr
