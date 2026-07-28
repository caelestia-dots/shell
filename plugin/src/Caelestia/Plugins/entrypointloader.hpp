#pragma once

#include <qobject.h>
#include <qpointer.h>
#include <qqmlcomponent.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qstring.h>
#include <qvariant.h>

#include "entrypoint.hpp"

namespace caelestia::plugins {

class PluginManifest;

class EntryPointLoader : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    // The entry point to load
    Q_PROPERTY(caelestia::plugins::EntryPoint entryPoint READ entryPoint WRITE setEntryPoint RESET resetEntryPoint
            NOTIFY entryPointChanged)
    // The URL to load. Defaults to the entry point's source resolved against its plugin at the
    // plugin's current generation, so it changes, and the loader reloads, on every plugin edit.
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    // The loaded object, null until it has finished loading
    Q_PROPERTY(QObject* item READ item NOTIFY itemChanged)
    Q_PROPERTY(caelestia::plugins::EntryPointLoader::Status status READ status NOTIFY statusChanged)

public:
    enum Status {
        Null,    // Nothing to load
        Loading, // Waiting for the component to compile
        Ready,   // Object created successfully
        Error,   // The entry point, its source or the created object is invalid
    };
    Q_ENUM(Status)

    explicit EntryPointLoader(QQuickItem* parent = nullptr);

    void componentComplete() override;

    [[nodiscard]] EntryPoint entryPoint() const;
    void setEntryPoint(const EntryPoint& entryPoint);
    void resetEntryPoint();

    [[nodiscard]] QString source() const;
    void setSource(const QString& source);

    [[nodiscard]] QObject* item() const;
    [[nodiscard]] Status status() const;

signals:
    void entryPointChanged();
    void sourceChanged();
    void itemChanged();
    void statusChanged();

    // Emitted after the object has been created and injected
    void loaded();

private slots:
    void onComponentStatusChanged(QQmlComponent::Status status);
    void onGenerationChanged();
    void updateSize();
    void updateImplicitSize();

private:
    void reload();
    void clear();
    void create();
    void setStatus(Status status);
    void warnComponentErrors() const;

    // Follows the entry point's plugin so a generation bump reloads this loader. Loaders are
    // created lazily, so each one derives its URL when it builds its component and joins
    // whichever generation is current then; there is no stored URL to go stale.
    void trackPlugin();

    // The subset of the injectable properties actually declared by the given object
    [[nodiscard]] QVariantMap injectedProperties(const QObject* object) const;

    EntryPoint m_entryPoint;
    QPointer<PluginManifest> m_plugin;
    QString m_source;
    QQmlComponent* m_component = nullptr;
    QObject* m_object = nullptr;
    QQuickItem* m_item = nullptr;
    Status m_status = Null;
    bool m_complete = false;
};

} // namespace caelestia::plugins
