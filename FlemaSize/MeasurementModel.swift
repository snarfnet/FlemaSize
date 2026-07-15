import SwiftUI

/// 配送方法の目安（平面サイズのみで判定。厚みは別途要確認）
struct ShippingOption: Identifiable {
    let id = UUID()
    let name: String
    let longMax: Double   // 長辺の上限(mm)
    let shortMax: Double  // 短辺の上限(mm)
    let note: String
}

let shippingOptions: [ShippingOption] = [
    ShippingOption(name: "ネコポス", longMax: 312, shortMax: 228, note: "厚さ3cm・1kg以内"),
    ShippingOption(name: "ゆうパケットポスト", longMax: 340, shortMax: 250, note: "厚さ3cm以内"),
    ShippingOption(name: "クリックポスト", longMax: 340, shortMax: 250, note: "厚さ3cm・1kg以内"),
    ShippingOption(name: "宅急便コンパクト(専用箱)", longMax: 250, shortMax: 200, note: "厚さ5cm"),
    ShippingOption(name: "ゆうパケット", longMax: 340, shortMax: 250, note: "3辺合計60cm・厚さ3cm"),
]

final class MeasurementModel: ObservableObject {
    @Published var selectedCoin: Coin = .yen500
    @Published var image: UIImage?

    /// キャンバス座標での硬貨の中心と半径
    @Published var coinCenter: CGPoint = .zero
    @Published var coinRadius: CGFloat = 60

    /// キャンバス座標での商品ボックス
    @Published var itemRect: CGRect = .zero

    /// キャンバスに配置済みか
    @Published var placed = false

    /// 計測キャンバスのサイズ（共有画像レンダリング用）
    @Published var canvasSize: CGSize = .zero

    /// 1ポイントあたりの実寸(mm)。硬貨の既知直径 ÷ 画面上の硬貨直径。
    var mmPerPoint: Double {
        let diameterPoints = Double(coinRadius * 2)
        guard diameterPoints > 0 else { return 0 }
        return selectedCoin.diameterMM / diameterPoints
    }

    var itemWidthMM: Double { Double(itemRect.width) * mmPerPoint }
    var itemHeightMM: Double { Double(itemRect.height) * mmPerPoint }

    var longSideMM: Double { max(itemWidthMM, itemHeightMM) }
    var shortSideMM: Double { min(itemWidthMM, itemHeightMM) }

    /// 平面サイズで入りそうな配送方法
    var fittingOptions: [ShippingOption] {
        guard itemWidthMM > 0, itemHeightMM > 0 else { return [] }
        return shippingOptions.filter { longSideMM <= $0.longMax && shortSideMM <= $0.shortMax }
    }

    func reset(canvas: CGSize) {
        canvasSize = canvas

        let w = canvas.width * 0.42
        let h = canvas.height * 0.42
        itemRect = CGRect(x: canvas.width * 0.5 - w * 0.5,
                          y: canvas.height * 0.32 - h * 0.2,
                          width: w, height: h)

        // 硬貨を自動検出して円を合わせる。見つからなければデフォルト位置。
        if let img = image, let norm = CoinDetector.detect(in: img) {
            let disp = displayedImageRect(canvas: canvas, imageSize: img.size)
            coinCenter = CGPoint(x: disp.minX + norm.midX * disp.width,
                                 y: disp.minY + norm.midY * disp.height)
            coinRadius = max(norm.width * disp.width, norm.height * disp.height) / 2
        } else {
            coinCenter = CGPoint(x: canvas.width * 0.30, y: canvas.height * 0.70)
            coinRadius = min(canvas.width, canvas.height) * 0.10
        }
        placed = true
    }

    /// scaledToFit で表示される画像の実矩形（レターボックス考慮）
    private func displayedImageRect(canvas: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: canvas)
        }
        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvas.width / canvas.height
        if imageAspect > canvasAspect {
            let dh = canvas.width / imageAspect
            return CGRect(x: 0, y: (canvas.height - dh) / 2, width: canvas.width, height: dh)
        } else {
            let dw = canvas.height * imageAspect
            return CGRect(x: (canvas.width - dw) / 2, y: 0, width: dw, height: canvas.height)
        }
    }
}

extension Double {
    /// mm を「◯◯.◯cm」表記に
    var cmString: String {
        String(format: "%.1fcm", self / 10.0)
    }
}
