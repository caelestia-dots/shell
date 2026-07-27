#include "entrypointloader.hpp"

#include <qloggingcategory.h>
#include <qqmlcontext.h>
#include <qqmlengine.h>
#include <qurl.h>

#include "pluginmanifest.hpp"
#include "settingsobject.hpp"

Q_LOGGING_CATEGORY(lcEntryPointLoader, "caelestia.plugins.loader", QtInfoMsg)

namespace caelestia::plugins {

EntryPointLoader::EntryPointLoader(QQuickItem* parent)
    : QQuickItem(parent) {
    QObject::connect(this, &QQuickItem::widthChanged, this, &EntryPointLoader::updateSize);
    QObject::connect(this, &QQuickItem::heightChanged, this, &EntryPointLoader::updateSize);
}

void EntryPointLoader::componentComplete() {
    QQuickItem::componentComplete();

    m_complete = true;
    reload();
}

EntryPoint EntryPointLoader::entryPoint() const {
    return m_entryPoint;
}

void EntryPointLoader::setEntryPoint(const EntryPoint& entryPoint) {
    if (m_entryPoint == entryPoint)
        return;

    const auto oldSource = source();

    m_entryPoint = entryPoint;
    emit entryPointChanged();

    if (source() != oldSource)
        emit sourceChanged();

    reload();
}

void EntryPointLoader::resetEntryPoint() {
    setEntryPoint(EntryPoint());
}

QString EntryPointLoader::source() const {
    return m_source.isEmpty() ? m_entryPoint.source() : m_source;
}

void EntryPointLoader::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();

    reload();
}

QObject* EntryPointLoader::item() const {
    return m_object;
}

EntryPointLoader::Status EntryPointLoader::status() const {
    return m_status;
}

void EntryPointLoader::onComponentStatusChanged(QQmlComponent::Status status) {
    if (status == QQmlComponent::Loading)
        return;

    if (status == QQmlComponent::Ready)
        create();
    else if (status == QQmlComponent::Error) {
        warnComponentErrors();
        setStatus(Error);
    } else
        setStatus(Null);
}

void EntryPointLoader::updateSize() {
    if (m_item)
        m_item->setSize(size());
}

void EntryPointLoader::updateImplicitSize() {
    setImplicitWidth(m_item ? m_item->implicitWidth() : 0);
    setImplicitHeight(m_item ? m_item->implicitHeight() : 0);
}

void EntryPointLoader::reload() {
    if (!m_complete)
        return;

    clear();

    const auto error = m_entryPoint.error();
    if (!error.isEmpty()) {
        qCWarning(lcEntryPointLoader) << "Refusing to load invalid entry point:" << error;
        setStatus(Error);
        return;
    }

    const auto src = source();
    if (src.isEmpty()) {
        setStatus(Null);
        return;
    }

    auto* const context = qmlContext(this);
    if (!context) {
        qCWarning(lcEntryPointLoader) << "Cannot load" << src << "without a QML context";
        setStatus(Error);
        return;
    }

    m_component =
        new QQmlComponent(context->engine(), context->resolvedUrl(QUrl(src)), QQmlComponent::PreferSynchronous, this);

    if (m_component->isLoading()) {
        setStatus(Loading);
        QObject::connect(m_component, &QQmlComponent::statusChanged, this, &EntryPointLoader::onComponentStatusChanged);
    } else
        onComponentStatusChanged(m_component->status());
}

void EntryPointLoader::clear() {
    if (m_object) {
        if (m_item) {
            QObject::disconnect(m_item, nullptr, this, nullptr);
            m_item->setParentItem(nullptr);
            m_item = nullptr;
            updateImplicitSize();
        }

        m_object->deleteLater();
        m_object = nullptr;
        emit itemChanged();
    }

    if (m_component) {
        m_component->deleteLater();
        m_component = nullptr;
    }
}

void EntryPointLoader::create() {
    auto* const object = m_component->beginCreate(qmlContext(this));
    if (!object) {
        warnComponentErrors();
        setStatus(Error);
        return;
    }

    const auto properties = injectedProperties(object);
    if (!properties.isEmpty())
        m_component->setInitialProperties(object, properties);

    m_component->completeCreate();

    // Also covers required properties the entry point declares but nothing provides
    if (m_component->isError()) {
        warnComponentErrors();
        delete object;
        setStatus(Error);
        return;
    }

    m_object = object;
    QQmlEngine::setObjectOwnership(m_object, QQmlEngine::CppOwnership);
    m_object->setParent(this);

    m_item = qobject_cast<QQuickItem*>(m_object);
    if (m_item) {
        m_item->setParentItem(this);
        QObject::connect(m_item, &QQuickItem::implicitWidthChanged, this, &EntryPointLoader::updateImplicitSize);
        QObject::connect(m_item, &QQuickItem::implicitHeightChanged, this, &EntryPointLoader::updateImplicitSize);
        updateImplicitSize();
        updateSize();
    }

    emit itemChanged();
    setStatus(Ready);
    emit loaded();
}

void EntryPointLoader::setStatus(Status status) {
    if (m_status == status)
        return;

    m_status = status;
    emit statusChanged();
}

void EntryPointLoader::warnComponentErrors() const {
    qCWarning(lcEntryPointLoader, "Failed to load %s: %s", qUtf8Printable(source()),
        qUtf8Printable(m_component->errorString()));
}

QVariantMap EntryPointLoader::injectedProperties(const QObject* object) const {
    QVariantMap properties;
    const auto* const meta = object->metaObject();

    if (meta->indexOfProperty("entryPoint") != -1)
        properties.insert(QStringLiteral("entryPoint"), QVariant::fromValue(m_entryPoint));

    if (meta->indexOfProperty("settings") != -1) {
        auto* const plugin = m_entryPoint.plugin();
        const SettingsObject* settings = plugin ? plugin->settings() : nullptr;
        properties.insert(QStringLiteral("settings"), QVariant::fromValue(settings));
    }

    return properties;
}

} // namespace caelestia::plugins
