#include "hyprdevices.hpp"

#include <qjsonarray.h>

namespace caelestia::internal::hypr {

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
    }
    if (last.value("capsLock") != object.value("capsLock")) {
        dirty = true;
        emit capsLockChanged();
    }
    if (last.value("numLock") != object.value("numLock")) {
        dirty = true;
        emit numLockChanged();
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

} // namespace caelestia::internal::hypr
