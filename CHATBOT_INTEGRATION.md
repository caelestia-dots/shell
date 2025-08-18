# Chatbot Integration for Caelestia Shell

## Overview

This document outlines the implementation of a chatbot widget integrated into the Caelestia Quickshell desktop environment. The chatbot will be seamlessly integrated into the drawer system with fluid animations and proper theming.

## Architecture

### Integration Point
The chatbot will be integrated into the existing drawer system (`modules/drawers/`) as a new panel, similar to how the dashboard, launcher, and utilities panels work.

### Component Structure
```
modules/chatbot/
├── Wrapper.qml          # Main wrapper with animations
├── Content.qml          # Chat interface content
├── Background.qml       # Panel background shape
├── ChatMessage.qml      # Individual message component
├── ChatInput.qml        # Input field with send button
├── ChatHistory.qml      # Scrollable message history
└── services/
    └── ChatbotService.qml   # API communication service
```

## Implementation Plan

### 1. Service Layer (`services/ChatbotService.qml`)

**Purpose**: Handle API communication with the chatbot service
**Features**:
- API key management (stored securely)
- HTTP requests to chatbot API
- Message history management
- Error handling and retry logic
- Rate limiting

**Key Properties**:
```qml
property string apiKey: Config.chatbot?.apiKey ?? ""
property string apiEndpoint: Config.chatbot?.endpoint ?? "https://api.openai.com/v1/chat/completions"
property var messageHistory: []
property bool isLoading: false
property string lastError: ""
```

**Key Methods**:
```qml
function sendMessage(message: string)
function clearHistory()
function retryLastMessage()
```

### 2. UI Components

#### Wrapper.qml
- Follows the same pattern as `launcher/Wrapper.qml`
- Handles show/hide animations
- Manages visibility state
- Provides smooth transitions

#### Content.qml
- Main chat interface
- Contains input field and message history
- Handles user interactions
- Manages layout and styling

#### ChatMessage.qml
- Individual message bubble
- Supports both user and bot messages
- Proper styling with Material 3 colors
- Copy functionality
- Timestamp display

#### ChatInput.qml
- Text input field
- Send button
- Loading indicator
- Character count (if needed)
- Multi-line support

#### ChatHistory.qml
- Scrollable list of messages
- Auto-scroll to bottom on new messages
- Proper spacing and animations
- Message grouping by time

## Configuration

### Config Structure (`config/ChatbotConfig.qml`)
```qml
QtObject {
    property bool enabled: false
    property string apiKey: ""
    property string apiEndpoint: "https://api.openai.com/v1/chat/completions"
    property string model: "gpt-3.5-turbo"
    property int maxTokens: 1000
    property real temperature: 0.7
    property bool showOnHover: true
    property int dragThreshold: 50
    property string triggerPosition: "right" // "left", "right", "top", "bottom"
}
```

### User Configuration (`~/.config/caelestia/shell.json`)
```json
{
  "chatbot": {
    "enabled": true,
    "apiKey": "your-api-key-here",
    "model": "gpt-3.5-turbo",
    "maxTokens": 1000,
    "temperature": 0.7,
    "showOnHover": true,
    "triggerPosition": "right"
  }
}
```

## Integration Steps

### 1. Add to Drawer System

**Update `modules/drawers/Panels.qml`**:
```qml
import qs.modules.chatbot as Chatbot

// Add property
readonly property Chatbot.Wrapper chatbot: chatbot

// Add component
Chatbot.Wrapper {
    id: chatbot
    
    visibilities: root.visibilities
    
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    anchors.rightMargin: session.width + utilities.width
}
```

**Update `modules/drawers/Backgrounds.qml`**:
```qml
import qs.modules.chatbot as Chatbot

Chatbot.Background {
    wrapper: root.panels.chatbot
    
    startX: root.width - root.panels.session.width - root.panels.utilities.width
    startY: (root.height - wrapper.height) / 2 - rounding
}
```

**Update `modules/drawers/Drawers.qml`**:
```qml
// Add visibility property
property bool chatbot
```

**Update `modules/drawers/Interactions.qml`**:
```qml
// Add hover detection
const showChatbot = inRightPanel(panels.chatbot, x, y);
if (!chatbotShortcutActive) {
    visibilities.chatbot = showChatbot;
}
```

### 2. Add to Services

**Update `services/` directory**:
- Add `ChatbotService.qml` to handle API communication
- Register service in main services loader

### 3. Add Configuration

**Update `config/Config.qml`**:
```qml
import "." as Config

Config.ChatbotConfig {
    id: chatbot
}
```

## API Integration

### Supported APIs
1. **OpenAI GPT API**
   - Models: GPT-3.5-turbo, GPT-4
   - Endpoint: `https://api.openai.com/v1/chat/completions`

2. **Anthropic Claude API**
   - Models: Claude-3-haiku, Claude-3-sonnet
   - Endpoint: `https://api.anthropic.com/v1/messages`

3. **Local APIs**
   - Ollama: `http://localhost:11434/api/chat`
   - LM Studio: `http://localhost:1234/v1/chat/completions`

### Request Format (OpenAI)
```json
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {"role": "system", "content": "You are a helpful desktop assistant."},
    {"role": "user", "content": "Hello!"}
  ],
  "max_tokens": 1000,
  "temperature": 0.7
}
```

## UI/UX Design

### Panel Positioning
- **Default**: Right side of screen (like current OSD)
- **Alternative**: Left, top, or bottom based on configuration
- **Size**: Medium width panel (~400px), dynamic height

### Styling
- **Colors**: Matches Material 3 theme from wallpaper
- **Background**: `Colours.tPalette.m3surfaceContainer`
- **Messages**: User messages on right (primary color), bot on left (surface variant)
- **Animations**: Smooth slide-in/out with proper easing curves

### Interactions
- **Trigger**: Mouse hover on panel edge or keyboard shortcut
- **Input**: Enter to send, Shift+Enter for new line
- **Actions**: Copy message, clear history, retry last message

## Security Considerations

### API Key Storage
- Store in user config file with restricted permissions
- Consider encryption for sensitive keys
- Never log or expose API keys in debug output

### Request Validation
- Sanitize user input before sending to API
- Implement rate limiting to prevent abuse
- Add request timeouts

### Privacy
- Option to disable message history persistence
- Clear sensitive data on session end
- Respect user privacy preferences

## Performance Considerations

### Message History
- Limit stored messages (default: 50 messages)
- Implement message cleanup for old conversations
- Efficient scrolling for large message lists

### API Calls
- Implement request queuing
- Add retry logic with exponential backoff
- Cache responses when appropriate

### Animations
- Use efficient QML animations
- Minimize repaints during transitions
- Optimize list view performance

## Testing Strategy

### Unit Tests
- Test API communication service
- Validate message formatting
- Test error handling scenarios

### Integration Tests
- Test panel integration with drawer system
- Verify animations and transitions
- Test configuration loading

### User Testing
- Test hover detection accuracy
- Verify keyboard shortcuts work
- Test on different screen sizes

## Future Enhancements

### Phase 1 (Basic Implementation)
- Simple text chat interface
- OpenAI API integration
- Basic hover trigger

### Phase 2 (Enhanced Features)
- Multiple API provider support
- Message history persistence
- Keyboard shortcuts
- Copy/paste functionality

### Phase 3 (Advanced Features)
- File attachments (images, documents)
- Voice input/output
- Chat templates/presets
- Integration with system information
- Plugin system for custom commands

### Phase 4 (Smart Integration)
- Context awareness (current app, selection)
- System control commands
- Workflow automation
- Custom AI models

## Development Timeline

1. **Week 1**: Service layer and API integration
2. **Week 2**: Basic UI components and styling
3. **Week 3**: Drawer system integration
4. **Week 4**: Polish, testing, and documentation

## Configuration Examples

### Minimal Setup
```json
{
  "chatbot": {
    "enabled": true,
    "apiKey": "sk-..."
  }
}
```

### Advanced Setup
```json
{
  "chatbot": {
    "enabled": true,
    "apiKey": "sk-...",
    "model": "gpt-4",
    "maxTokens": 2000,
    "temperature": 0.5,
    "showOnHover": true,
    "triggerPosition": "right",
    "systemPrompt": "You are a helpful Linux desktop assistant. Be concise and helpful.",
    "saveHistory": false,
    "maxHistoryLength": 100
  }
}
```

This documentation provides a comprehensive roadmap for implementing a chatbot widget that seamlessly integrates with your Caelestia shell's existing architecture and design patterns.