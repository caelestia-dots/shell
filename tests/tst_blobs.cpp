#include <qtest.h>

#include <array>

#include "Blobs/blobmaterial.hpp"
#include "Blobs/blobshape.hpp"

using namespace caelestia::blobs;

class ExposedBlobShape : public BlobShape {
public:
    using BlobShape::computeExcludeMasks;
    using BlobShape::ShapeList;

    void setCachedRectCount(qsizetype count) { m_cachedRects.resize(count); }

    [[nodiscard]] quint32 excludeMaskAt(qsizetype index) const { return m_cachedRects.at(index).excludeMask; }

    void excludeWith(const BlobShape* other) { m_excluded = other; }

protected:
    [[nodiscard]] bool isExcluded(const BlobShape* other) const override { return other == m_excluded; }

private:
    const BlobShape* m_excluded = nullptr;
};

class TestBlobs : public QObject {
    Q_OBJECT

private slots:

    void exclusionAtLastIndexSetsHighBit();
};

void TestBlobs::exclusionAtLastIndexSetsHighBit() {
    std::array<ExposedBlobShape, k_maxRects> shapes;
    ExposedBlobShape::ShapeList shapeList;
    for (auto& shape : shapes) {
        shape.setCachedRectCount(k_maxRects);
        shapeList.append(&shape);
    }

    constexpr auto k_last = k_maxRects - 1;
    shapes[0].excludeWith(&shapes[k_last]);
    shapes[0].computeExcludeMasks(shapeList);

    // Index 15 must fit in the mask and be symmetric in the other rect's entry
    QCOMPARE(shapes[0].excludeMaskAt(0), quint32{ 1 } << 15U);
    QCOMPARE(shapes[0].excludeMaskAt(k_last), quint32{ 1 });
    QCOMPARE(shapes[0].excludeMaskAt(1), quint32{ 0 });
}

QTEST_MAIN(TestBlobs)
#include "tst_blobs.moc"
