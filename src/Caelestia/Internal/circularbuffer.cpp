#include "circularbuffer.hpp"

#include <algorithm>

namespace caelestia::internal {

CircularBuffer::CircularBuffer(QObject* parent)
    : QObject(parent) {}

int CircularBuffer::capacity() const {
    return m_capacity;
}

void CircularBuffer::setCapacity(int capacity) {
    if (capacity < 0)
        capacity = 0;
    if (m_capacity == capacity)
        return;

    const auto old = values();

    m_capacity = capacity;
    m_data.resize(capacity);
    m_data.fill(0.0);
    m_head = 0;
    m_count = 0;

    // Re-push old values, keeping the most recent ones
    const auto start = old.size() > capacity ? old.size() - capacity : 0;
    for (auto i = start; i < old.size(); ++i) {
        m_data[m_head] = old[i];
        m_head = (m_head + 1) % m_capacity;
        m_count++;
    }

    emit capacityChanged();
    emit countChanged();
    emit valuesChanged();
}

int CircularBuffer::count() const {
    return m_count;
}

QList<qreal> CircularBuffer::values() const {
    QList<qreal> result;
    result.reserve(m_count);
    for (int i = 0; i < m_count; ++i)
        result.append(at(i));
    return result;
}

qreal CircularBuffer::maximum() const {
    if (m_count == 0)
        return 0.0;

    qreal maxVal = at(0);
    for (int i = 1; i < m_count; ++i)
        maxVal = std::max(maxVal, at(i));
    return maxVal;
}

void CircularBuffer::push(qreal value) {
    if (m_capacity <= 0)
        return;

    m_data[m_head] = value;
    m_head = (m_head + 1) % m_capacity;
    if (m_count < m_capacity) {
        m_count++;
        emit countChanged();
    }
    emit valuesChanged();
}

void CircularBuffer::clear() {
    if (m_count == 0)
        return;

    m_head = 0;
    m_count = 0;
    emit countChanged();
    emit valuesChanged();
}

qreal CircularBuffer::at(int index) const {
    if (index < 0 || index >= m_count)
        return 0.0;

    const int actualIndex = (m_head - m_count + index + m_capacity) % m_capacity;
    return m_data[actualIndex];
}

} // namespace caelestia::internal
