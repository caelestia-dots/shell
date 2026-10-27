#include "hyprdevices.hpp"

#include <qjsonarray.h>

#include <algorithm>
#include <utility>

#include "config/rootnodes.hpp"
#include "core/toaster.hpp"
#include "util/i18n.hpp"

namespace caelestia::shell::services::hypr {

using Qt::StringLiterals::operator""_s;

namespace {

using util::i18n::mark;

const config::UtilitiesToasts* toastConfig() {
    return config::ConfigSingleton::instance()->utilities()->toasts();
}

void toastCapsLock(bool enabled) {
    if (!toastConfig()->capsLockChanged())
        return;

    const auto title = enabled ? mark(u"Caps lock enabled"_s) : mark(u"Caps lock disabled"_s);
    const auto message =
        enabled ? mark(u"Caps lock is currently enabled"_s) : mark(u"Caps lock is currently disabled"_s);
    const auto icon = enabled ? u"keyboard_capslock_badge"_s : u"keyboard_capslock"_s;
    Toaster::instance()->toast(title, message, icon);
}

void toastNumLock(bool enabled) {
    if (!toastConfig()->numLockChanged())
        return;

    const auto title = enabled ? mark(u"Num lock enabled"_s) : mark(u"Num lock disabled"_s);
    const auto message = enabled ? mark(u"Num lock is currently enabled"_s) : mark(u"Num lock is currently disabled"_s);
    const auto icon = enabled ? u"looks_one"_s : u"timer_1"_s;
    Toaster::instance()->toast(title, message, icon);
}

void toastKbLayout(const QString& layout) {
    if (!toastConfig()->kbLayoutChanged())
        return;

    Toaster::instance()->toast(
        // TRANSLATORS: %1 = an XKB keyboard layout name, e.g. English (US)
        mark(u"Keyboard layout changed"_s), mark(u"Layout changed to: %1"_s, { layout }), u"keyboard"_s);
}

} // namespace

HyprKeyboard::HyprKeyboard(QJsonObject ipcObject, QObject* parent)
    : QObject(parent)
    , m_lastIpcObject(std::move(ipcObject)) {}

QVariantHash HyprKeyboard::lastIpcObject() const {
    return m_lastIpcObject.toVariantHash();
}

QString HyprKeyboard::address() const {
    return m_lastIpcObject.value(u"address").toString();
}

QString HyprKeyboard::name() const {
    return m_lastIpcObject.value(u"name").toString();
}

QString HyprKeyboard::layout() const {
    return m_lastIpcObject.value(u"layout").toString();
}

QString HyprKeyboard::activeKeymap() const {
    return m_lastIpcObject.value(u"active_keymap").toString();
}

bool HyprKeyboard::capsLock() const {
    return m_lastIpcObject.value(u"capsLock").toBool();
}

bool HyprKeyboard::numLock() const {
    return m_lastIpcObject.value(u"numLock").toBool();
}

bool HyprKeyboard::main() const {
    return m_lastIpcObject.value(u"main").toBool();
}

bool HyprKeyboard::updateLastIpcObject(const QJsonObject& object) {
    if (m_lastIpcObject == object) {
        return false;
    }

    const auto last = m_lastIpcObject;
    const auto isMain = object.value(u"main").toBool();

    m_lastIpcObject = object;
    emit lastIpcObjectChanged();

    bool dirty = false;
    if (last.value(u"address") != object.value(u"address")) {
        dirty = true;
        emit addressChanged();
    }
    if (last.value(u"name") != object.value(u"name")) {
        dirty = true;
        emit nameChanged();
    }
    if (last.value(u"layout") != object.value(u"layout")) {
        dirty = true;
        emit layoutChanged();
    }
    if (last.value(u"active_keymap") != object.value(u"active_keymap")) {
        dirty = true;
        emit activeKeymapChanged();
        if (isMain && !last.value(u"active_keymap").toString().isEmpty())
            toastKbLayout(object.value(u"active_keymap").toString());
    }
    if (last.value(u"capsLock") != object.value(u"capsLock")) {
        dirty = true;
        emit capsLockChanged();
        if (isMain)
            toastCapsLock(object.value(u"capsLock").toBool());
    }
    if (last.value(u"numLock") != object.value(u"numLock")) {
        dirty = true;
        emit numLockChanged();
        if (isMain)
            toastNumLock(object.value(u"numLock").toBool());
    }
    if (last.value(u"main") != object.value(u"main")) {
        dirty = true;
        emit mainChanged();
    }
    return dirty;
}

HyprDevices::HyprDevices(QObject* parent)
    : QObject(parent) {}

QQmlListProperty<HyprKeyboard> HyprDevices::keyboards() {
    return { this, &m_keyboards };
}

bool HyprDevices::updateLastIpcObject(const QJsonObject& object) {
    const auto val = object.value(u"keyboards").toArray();
    bool dirty = false;

    for (auto it = m_keyboards.begin(); it != m_keyboards.end();) {
        auto* const keyboard = *it;
        const auto inNewValues = std::ranges::any_of(val, [keyboard](const QJsonValue& o) {
            return o.toObject().value(u"address").toString() == keyboard->address();
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
        const auto addr = obj.value(u"address").toString();

        const auto it = std::ranges::find_if(m_keyboards, [addr](const HyprKeyboard* kb) {
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

} // namespace caelestia::shell::services::hypr
