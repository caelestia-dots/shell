#pragma once

#include <qassert.h>
#include <qtypes.h>

#include <algorithm>
#include <functional>
#include <span>
#include <vector>

namespace util {

// FIFO with a capacity fixed at construction, which overwrites its oldest values once full. Not thread safe.
template <typename T> class RingBuffer {
public:
    explicit RingBuffer(qsizetype capacity = 0)
        : m_data(static_cast<size_t>(std::max(capacity, static_cast<qsizetype>(0)))) {}

    [[nodiscard]] qsizetype capacity() const { return std::ssize(m_data); }

    [[nodiscard]] qsizetype count() const { return m_count; }

    void push(const T& value) {
        const auto cap = capacity();
        if (cap == 0)
            return;

        *(m_data.begin() + m_head) = value;
        m_head = (m_head + 1) % cap;
        m_count = std::min(m_count + 1, cap);
    }

    // Appends values converted with convert, overwriting the oldest values once full
    template <typename U, typename Convert = std::identity> void push(std::span<const U> values, Convert convert = {}) {
        const auto cap = capacity();
        if (cap == 0)
            return;

        // Only the newest capacity() values can survive
        if (std::ssize(values) > cap)
            values = values.last(static_cast<size_t>(cap));

        const qsizetype n = std::ssize(values);
        const auto firstRun = std::min(n, cap - m_head);
        std::transform(values.begin(), values.begin() + firstRun, m_data.begin() + m_head, convert);
        std::transform(values.begin() + firstRun, values.end(), m_data.begin(), convert);

        m_head = (m_head + n) % cap;
        m_count = std::min(m_count + n, cap);
    }

    // Copies the newest min(out.size(), count()) values, oldest first, to the start of out
    template <typename U, typename Convert = std::identity>
    void copyLatest(std::span<U> out, Convert convert = {}) const {
        const auto n = std::min<qsizetype>(std::ssize(out), m_count);
        if (n == 0)
            return;

        const auto cap = capacity();
        const auto start = (m_head - n + cap) % cap;
        const auto firstRun = std::min(n, cap - start);
        std::transform(m_data.begin() + start, m_data.begin() + start + firstRun, out.begin(), convert);
        std::transform(m_data.begin(), m_data.begin() + (n - firstRun), out.begin() + firstRun, convert);
    }

    // Pushes every value, oldest first, onto other
    void pushTo(RingBuffer& other) const {
        if (m_count == 0)
            return;

        const std::span<const T> data(m_data);
        const auto cap = capacity();
        const auto start = (m_head - m_count + cap) % cap;
        const auto firstRun = std::min(m_count, cap - start);
        other.push(data.subspan(static_cast<size_t>(start), static_cast<size_t>(firstRun)));
        other.push(data.first(static_cast<size_t>(m_count - firstRun)));
    }

    // Index 0 is the oldest value
    [[nodiscard]] const T& at(qsizetype index) const {
        Q_ASSERT(index >= 0 && index < m_count);
        const auto cap = capacity();
        return *(m_data.begin() + (m_head - m_count + index + cap) % cap);
    }

    void clear() {
        m_head = 0;
        m_count = 0;
    }

private:
    std::vector<T> m_data;
    qsizetype m_head = 0; // Next write position
    qsizetype m_count = 0;
};

} // namespace util
