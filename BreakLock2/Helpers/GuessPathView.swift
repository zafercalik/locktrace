
import SwiftUI

struct GuessPathView: View {
    let combination: [Int]
    let dotPositions: [Int: CGPoint]
    let dotSize: CGFloat
    let spacing: CGFloat
    let totalNumberOfDots: Int
    let originalDefaultDotSizeRef: CGFloat

    var body: some View {
        ZStack {
            // Arka plandaki pasif noktaları çiz
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(dotSize), spacing: spacing), count: 3), spacing: spacing) {
                ForEach(0..<totalNumberOfDots, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: dotSize, height: dotSize)
                }
            }

            // Çizgileri çizmek için: Her bir segment için ayrı Path
            // Sadece kombinasyonda en az 2 nokta varsa (yani çizilecek en az 1 segment varsa) döngüyü çalıştır.
            if combination.count > 1 {
                ForEach(segments) { segment in
                    Path { path in
                        path.move(to: segment.from)
                        path.addLine(to: segment.to)
                    }
                    .stroke(
                        lineColor(for: segment.index, totalSegments: segments.count),
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }

            // Seçili (tahmin edilmiş) noktaları çiz
            ForEach(0..<totalNumberOfDots, id: \.self) { index in
                if combination.contains(index) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: dotSize * 0.6, height: dotSize * 0.6)
                        .position(positionForIndex(index: index, totalWidth: (3 * dotSize) + (2 * spacing), totalHeight: (3 * dotSize) + (2 * spacing)))
                }
            }
        }
    }

    // Çizgi rengini segmentin sırasına göre hesaplayan fonksiyon
    func lineColor(for segmentIndex: Int, totalSegments: Int) -> Color {
        guard totalSegments > 0 else { return .white }

        let startGray: Double = 0.2 // En koyu gri (ilk segment)
        let endGray: Double = 1.0   // Beyaz (son segment)

        let progress = Double(segmentIndex) / Double(totalSegments)
        let opacity = startGray + (endGray - startGray) * progress

        return Color.white.opacity(opacity)
    }

    // Minyatür alanda noktanın pozisyonunu hesaplayan fonksiyon
    private func positionForIndex(index: Int, totalWidth: CGFloat, totalHeight: CGFloat) -> CGPoint {
        let column = index % 3
        let row = index / 3
        
        let x = (CGFloat(column) * (dotSize + spacing)) + (dotSize / 2)
        let y = (CGFloat(row) * (dotSize + spacing)) + (dotSize / 2)
        
        return CGPoint(x: x, y: y)
    }
    
    var segments: [LineSegment] {
        guard combination.count > 1 else { return [] }

        let originalDotRadius = originalDefaultDotSizeRef / 2

        var originalMinX: CGFloat = .infinity
        var originalMinY: CGFloat = .infinity
        var originalMaxX: CGFloat = -.infinity
        var originalMaxY: CGFloat = -.infinity

        for idx in 0..<totalNumberOfDots {
            if let pos = dotPositions[idx] {
                originalMinX = min(originalMinX, pos.x - originalDotRadius)
                originalMinY = min(originalMinY, pos.y - originalDotRadius)
                originalMaxX = max(originalMaxX, pos.x + originalDotRadius)
                originalMaxY = max(originalMaxY, pos.y + originalDotRadius)
            }
        }

        let originalGridTotalWidth = originalMaxX - originalMinX
        let originalGridTotalHeight = originalMaxY - originalMinY

        let currentViewGridWidth = (3 * dotSize) + (2 * spacing)
        let currentViewGridHeight = (3 * dotSize) + (2 * spacing)

        let scaleX = originalGridTotalWidth > 0 ? currentViewGridWidth / originalGridTotalWidth : 1
        let scaleY = originalGridTotalHeight > 0 ? currentViewGridHeight / originalGridTotalHeight : 1
        let scaleFactor = min(scaleX, scaleY)

        let offsetX = (currentViewGridWidth - originalGridTotalWidth * scaleFactor) / 2 - originalMinX * scaleFactor
        let offsetY = (currentViewGridHeight - originalGridTotalHeight * scaleFactor) / 2 - originalMinY * scaleFactor

        var result: [LineSegment] = []

        for i in 0..<(combination.count - 1) {
            if let fromIndex = combination.safeIndex(i),
               let toIndex = combination.safeIndex(i + 1),
               let fromPos = dotPositions[fromIndex],
               let toPos = dotPositions[toIndex] {

                let transformedFrom = CGPoint(
                    x: fromPos.x * scaleFactor + offsetX,
                    y: fromPos.y * scaleFactor + offsetY
                )
                let transformedTo = CGPoint(
                    x: toPos.x * scaleFactor + offsetX,
                    y: toPos.y * scaleFactor + offsetY
                )

                result.append(LineSegment(from: transformedFrom, to: transformedTo, index: i))
            }
        }

        return result
    }
}



// Array extension'ı GuessPathView içinde kullanıldığı için burada da olması gerekiyor.
extension Array {
    func safeIndex(_ i: Int) -> Element? {
        guard i >= 0 && i < endIndex else { return nil }
        return self[i]
    }
}
