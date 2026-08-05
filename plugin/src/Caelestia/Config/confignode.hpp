#pragma once

#include <qjsonvalue.h>
#include <qloggingcategory.h>
#include <qmap.h>
#include <qobject.h>
#include <qstringlist.h>
#include <qtimer.h>
#include <qvariant.h>

namespace caelestia::config {

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

// Common base for config tree nodes. Owns change batching, the overlay link and the
// JSON contract, so a parent traverses children without caring which kind they are.
class ConfigNode : public QObject {
    Q_OBJECT

public:
    explicit ConfigNode(QObject* parent = nullptr);

    virtual void loadFromJson(const QJsonValue& json) = 0;
    // Loads without reporting a change, for defaults and values synced from global
    void loadFromJsonQuietly(const QJsonValue& json);
    // Returns Undefined when the node holds nothing worth writing.
    [[nodiscard]] virtual QJsonValue toJson() const = 0;

    virtual void clearLoadedKeys() = 0;

    // Paths of loaded keys that matched no property, relative to this node.
    [[nodiscard]] virtual QStringList unknownKeys() const = 0;
    // Child nodes held as properties, a list has none since it reports element changes itself
    [[nodiscard]] virtual QList<ConfigNode*> childNodes() const;

    void syncFromGlobal(ConfigNode* global);
    virtual void resyncFromGlobal() = 0;

    [[nodiscard]] bool isOverlay() const;
    [[nodiscard]] QString propertyPath(const QString& name = {}) const;

    // First property index past QObject's own (objectName). Unlike propertyOffset(),
    // this keeps properties inherited from intermediate config classes
    [[nodiscard]] static int basePropertyOffset();

signals:
    void propertiesChanged(const QMap<QString, QVariant>& changed);

protected:
    virtual void syncValuesFromGlobal() = 0;
    virtual void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) = 0;

    // Name this node gives the child, empty if it does not hold it
    [[nodiscard]] virtual QString childPath(const ConfigNode* child) const = 0;

    void notifyPropertyChanged(const QString& name, const QVariant& value);

    [[nodiscard]] static QString joinPath(const QString& parent, const QString& child);

    ConfigNode* m_global = nullptr;

private:
    void setNotifySuppressed(bool suppressed);
    void emitBatchedChanges();

    QMap<QString, QVariant> m_pendingChanges;
    QTimer* m_batchTimer = nullptr;
    bool m_suppressNotify = false;
};

} // namespace caelestia::config
