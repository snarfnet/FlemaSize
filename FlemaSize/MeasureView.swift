import SwiftUI

struct MeasureView: View {
    @ObservedObject var model: MeasurementModel

    // ジェスチャ開始時のスナップショット
    @State private var coinCenterStart: CGPoint?
    @State private var itemRectStart: CGRect?

    var body: some View {
        GeometryReader { geo in
            let canvas = geo.size
            ZStack {
                if let image = model.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: canvas.width, height: canvas.height)
                }

                if model.placed {
                    itemBox
                    coinCircle
                }
            }
            .frame(width: canvas.width, height: canvas.height)
            .coordinateSpace(name: "canvas")
            .clipped()
            .onAppear {
                if !model.placed { model.reset(canvas: canvas) }
            }
        }
    }

    // MARK: - 硬貨の円

    private var coinCircle: some View {
        let d = model.coinRadius * 2
        return ZStack {
            Circle()
                .stroke(Theme.coin, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                .frame(width: d, height: d)
                .background(Circle().fill(Theme.coin.opacity(0.12)).frame(width: d, height: d))
                .contentShape(Circle())
                .position(model.coinCenter)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            if coinCenterStart == nil { coinCenterStart = model.coinCenter }
                            let s = coinCenterStart!
                            model.coinCenter = CGPoint(x: s.x + v.translation.width,
                                                       y: s.y + v.translation.height)
                        }
                        .onEnded { _ in coinCenterStart = nil }
                )

            Text("\(model.selectedCoin.short)円")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Theme.coin)
                .position(x: model.coinCenter.x, y: model.coinCenter.y - model.coinRadius - 14)
                .allowsHitTesting(false)

            // 半径ハンドル（右端）
            handle(color: Theme.coin)
                .position(x: model.coinCenter.x + model.coinRadius, y: model.coinCenter.y)
                .gesture(
                    DragGesture(coordinateSpace: .named("canvas"))
                        .onChanged { v in
                            let dx = v.location.x - model.coinCenter.x
                            let dy = v.location.y - model.coinCenter.y
                            model.coinRadius = max(14, sqrt(dx * dx + dy * dy))
                        }
                )
        }
    }

    // MARK: - 商品ボックス

    private var itemBox: some View {
        let r = model.itemRect
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.item, style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.item.opacity(0.10)))
                .frame(width: r.width, height: r.height)
                .contentShape(Rectangle())
                .position(x: r.midX, y: r.midY)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            if itemRectStart == nil { itemRectStart = model.itemRect }
                            let s = itemRectStart!
                            model.itemRect = s.offsetBy(dx: v.translation.width, dy: v.translation.height)
                        }
                        .onEnded { _ in itemRectStart = nil }
                )

            // サイズラベル
            dimensionBadge
                .position(x: r.midX, y: r.minY - 16)
                .allowsHitTesting(false)

            // リサイズハンドル（右下）
            handle(color: Theme.item)
                .position(x: r.maxX, y: r.maxY)
                .gesture(
                    DragGesture(coordinateSpace: .named("canvas"))
                        .onChanged { v in
                            let s = model.itemRect
                            let w = max(24, v.location.x - s.minX)
                            let h = max(24, v.location.y - s.minY)
                            model.itemRect = CGRect(x: s.minX, y: s.minY, width: w, height: h)
                        }
                )
        }
    }

    private var dimensionBadge: some View {
        Text("\(model.itemWidthMM.cmString) × \(model.itemHeightMM.cmString)")
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.item.opacity(0.9))
            .clipShape(Capsule())
    }

    private func handle(color: Color) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .frame(width: 26, height: 26)
            .shadow(radius: 3)
            .contentShape(Circle().inset(by: -12))
    }
}
