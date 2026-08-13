#pragma once

#include <qloggingcategory.h>

namespace caelestia::settings {

Q_DECLARE_LOGGING_CATEGORY(lcSettings)

class Node;

enum class WriteOrigin {
    Init,  // On init
    File,  // From the JSON file
    Layer, // From the fallback layer
    Qml,   // From QML
    Reset, // On option reset
};

class WriteScope {
public:
    explicit WriteScope(Node* node, WriteOrigin origin);
    ~WriteScope();

private:
    Node* m_root;
    WriteOrigin m_previous;

    Q_DISABLE_COPY_MOVE(WriteScope)
};

} // namespace caelestia::settings
