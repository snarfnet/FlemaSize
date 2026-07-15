import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var model = MeasurementModel()
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showShare = false
    @State private var shareImage: UIImage?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if model.image == nil {
                startScreen
            } else {
                measureScreen
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { img in
                model.image = img
                model.placed = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            ImagePicker(sourceType: .photoLibrary) { img in
                model.image = img
                model.placed = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showShare) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    // MARK: - スタート画面

    private var startScreen: some View {
        VStack(spacing: 22) {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(Theme.accent)
                Text("フリマサイズ")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.text)
                Text("硬貨を一緒に置いて撮るだけで\n商品のサイズがわかります")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.sub)
                    .lineSpacing(4)
            }

            coinPicker
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                bigButton(title: "カメラで撮る", icon: "camera.fill", filled: true) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showLibrary = true
                    }
                }
                bigButton(title: "写真から選ぶ", icon: "photo.on.rectangle", filled: false) {
                    showLibrary = true
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Text("硬貨と商品は同じ高さ・真上から撮ると正確です")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.sub.opacity(0.8))
                .padding(.bottom, 12)
        }
    }

    // MARK: - 計測画面

    private var measureScreen: some View {
        VStack(spacing: 0) {
            MeasureView(model: model)
                .background(Color.black)

            resultPanel
        }
    }

    private var resultPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.accent)
                Text("円を")
                    .foregroundStyle(Theme.sub)
                Text("硬貨")
                    .foregroundStyle(Theme.coin)
                Text("に、枠を")
                    .foregroundStyle(Theme.sub)
                Text("商品")
                    .foregroundStyle(Theme.item)
                Text("に合わせてね")
                    .foregroundStyle(Theme.sub)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            coinPicker

            HStack(spacing: 12) {
                dimCard(label: "よこ", value: model.itemWidthMM.cmString)
                dimCard(label: "たて", value: model.itemHeightMM.cmString)
            }

            if !model.fittingOptions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("入りそうな発送方法")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.sub)
                    ForEach(model.fittingOptions) { opt in
                        HStack(spacing: 6) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.accent)
                            Text(opt.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.text)
                            Text(opt.note)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.sub)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 12) {
                smallButton(title: "撮り直す", icon: "arrow.counterclockwise") {
                    model.image = nil
                    model.placed = false
                }
                smallButton(title: "保存・共有", icon: "square.and.arrow.up") {
                    shareImage = renderResult()
                    if shareImage != nil { showShare = true }
                }
            }
        }
        .padding(16)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }

    // MARK: - パーツ

    private var coinPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("基準にする硬貨")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Theme.sub)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Coin.allCases) { coin in
                        let sel = model.selectedCoin == coin
                        Button {
                            model.selectedCoin = coin
                        } label: {
                            Text(coin.rawValue)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(sel ? Theme.bg : Theme.text)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(sel ? Theme.coin : Theme.card)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func dimCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Theme.sub)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func bigButton(title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 17, weight: .black))
                Text(title).font(.system(size: 17, weight: .black, design: .rounded))
            }
            .foregroundStyle(filled ? Theme.bg : Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(filled ? Theme.accent : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func smallButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 14, weight: .black))
                Text(title).font(.system(size: 14, weight: .black, design: .rounded))
            }
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    /// 計測画面（写真＋オーバーレイ）を画像化して共有
    @MainActor
    private func renderResult() -> UIImage? {
        let size = model.canvasSize
        guard size.width > 0, size.height > 0 else { return nil }
        let view = MeasureView(model: model)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
