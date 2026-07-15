import UIKit
import Vision

/// 写真から「硬貨らしい丸い形」を1つ探す。
/// 返り値は画像内の正規化矩形（原点左上・y下向き、0〜1）。見つからなければ nil。
enum CoinDetector {
    static func detect(in image: UIImage) -> CGRect? {
        guard let cg = image.cgImage else { return nil }

        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.6
        request.detectsDarkOnLight = true
        request.maximumImageDimension = 512

        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        try? handler.perform([request])
        guard let obs = request.results?.first as? VNContoursObservation else { return nil }

        var best: (score: Double, rect: CGRect)?

        for i in 0..<obs.contourCount {
            guard let contour = try? obs.contour(at: i) else { continue }
            let pts = contour.normalizedPoints        // 原点左下・y上向き
            if pts.count < 12 { continue }

            var minX = Float.greatestFiniteMagnitude, minY = Float.greatestFiniteMagnitude
            var maxX = -Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
            var signedArea: Float = 0
            var perimeter: Float = 0

            for j in 0..<pts.count {
                let p = pts[j]
                let q = pts[(j + 1) % pts.count]
                minX = min(minX, p.x); minY = min(minY, p.y)
                maxX = max(maxX, p.x); maxY = max(maxY, p.y)
                signedArea += p.x * q.y - q.x * p.y
                let dx = q.x - p.x, dy = q.y - p.y
                perimeter += (dx * dx + dy * dy).squareRoot()
            }

            let area = abs(signedArea) / 2
            let w = maxX - minX, h = maxY - minY
            guard w > 0, h > 0, perimeter > 0 else { continue }

            let sizeN = Double(max(w, h))
            if sizeN < 0.04 || sizeN > 0.55 { continue }      // 硬貨サイズの想定範囲

            let aspect = Double(w / h)
            if aspect < 0.78 || aspect > 1.28 { continue }    // ほぼ正円

            // 円形度: 4πA / P²（真円なら1）
            let circularity = Double(4 * Float.pi * area / (perimeter * perimeter))
            if circularity < 0.65 { continue }

            // 充填率: 面積/外接矩形（真円なら約0.785）
            let fill = Double(area / (w * h))

            let score = circularity - abs(fill - 0.785)
            let rect = CGRect(x: Double(minX), y: Double(1 - maxY),
                              width: Double(w), height: Double(h))   // 左上原点に変換
            if best == nil || score > best!.score {
                best = (score, rect)
            }
        }
        return best?.rect
    }
}
