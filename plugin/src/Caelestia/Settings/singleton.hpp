#pragma once

#include <qjsengine.h>
#include <qqmlengine.h>

#include "layerregistry.hpp" // IWYU pragma: keep
#include "rootnode.hpp"      // IWYU pragma: keep

// Declares a QML singleton over a root node: the global layer plus per-screen overlays via forScreen().
#define SETTINGS_SINGLETON_DECL(Type, Root, QmlName)                                                                   \
    class Type : public Root {                                                                                         \
        Q_OBJECT                                                                                                       \
        QML_NAMED_ELEMENT(QmlName)                                                                                     \
        QML_SINGLETON                                                                                                  \
                                                                                                                       \
    public:                                                                                                            \
        static Type* instance();                                                                                       \
        static Type* create(QQmlEngine*, QJSEngine*);                                                                  \
                                                                                                                       \
        [[nodiscard]] Q_INVOKABLE Root* forScreen(const QString& screen);                                              \
                                                                                                                       \
    private:                                                                                                           \
        explicit Type(QObject* parent = nullptr);                                                                      \
                                                                                                                       \
        void initLayer(Root* layer);                                                                                   \
                                                                                                                       \
        caelestia::shell::settings::LayerRegistry<Root> m_layers;                                                      \
    };

// Handler provides static loaded(Root*, screen), loadFailed(error, screen) and saveFailed(error, screen);
// screen is empty for the global layer.
#define SETTINGS_SINGLETON_IMPL(Type, Root, dir, monitorDir, file, Handler)                                            \
    Type* Type::instance() {                                                                                           \
        static Type instance;                                                                                          \
        return &instance;                                                                                              \
    }                                                                                                                  \
                                                                                                                       \
    Type* Type::create(QQmlEngine*, QJSEngine*) {                                                                      \
        QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);                                          \
        return instance();                                                                                             \
    }                                                                                                                  \
                                                                                                                       \
    Root* Type::forScreen(const QString& screen) {                                                                     \
        bool created;                                                                                                  \
        auto* const layer = m_layers.get(screen, this, &created);                                                      \
        if (created)                                                                                                   \
            initLayer(layer);                                                                                          \
        return layer;                                                                                                  \
    }                                                                                                                  \
                                                                                                                       \
    Type::Type(QObject* parent)                                                                                        \
        : Root(dir + u'/' + file, nullptr, parent)                                                                     \
        , m_layers(monitorDir, file, this) {                                                                           \
        initLayer(this);                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
    void Type::initLayer(Root* layer) {                                                                                \
        QObject::connect(layer, &Root::treeLoaded, this, [this, layer] {                                               \
            Handler::loaded(layer, m_layers.nameFor(layer));                                                           \
        });                                                                                                            \
        QObject::connect(layer, &Root::treeLoadFailed, this,                                                           \
            [this, layer](caelestia::shell::settings::RootNode*, const QString& error) {                               \
                Handler::loadFailed(error, m_layers.nameFor(layer));                                                   \
            });                                                                                                        \
        QObject::connect(layer, &Root::treeSaveFailed, this,                                                           \
            [this, layer](caelestia::shell::settings::RootNode*, const QString& error) {                               \
                Handler::saveFailed(error, m_layers.nameFor(layer));                                                   \
            });                                                                                                        \
        layer->load();                                                                                                 \
    }
