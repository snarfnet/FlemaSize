import SwiftUI

/// 基準に使う硬貨。直径は日本の造幣局公表値（mm）。
enum Coin: String, CaseIterable, Identifiable {
    case yen500 = "500円玉"
    case yen100 = "100円玉"
    case yen50 = "50円玉"
    case yen10 = "10円玉"
    case yen5 = "5円玉"
    case yen1 = "1円玉"

    var id: String { rawValue }

    /// 直径（ミリ）
    var diameterMM: Double {
        switch self {
        case .yen500: return 26.5
        case .yen100: return 22.6
        case .yen50:  return 21.0
        case .yen10:  return 23.5
        case .yen5:   return 22.0
        case .yen1:   return 20.0
        }
    }

    /// 見分け用の色味（円オーバーレイの色）
    var tint: Color {
        switch self {
        case .yen500, .yen5: return Color(red: 0.83, green: 0.68, blue: 0.32) // 黄銅っぽい金
        case .yen10:         return Color(red: 0.72, green: 0.45, blue: 0.30) // 銅の赤茶
        default:             return Color(red: 0.70, green: 0.72, blue: 0.75) // 白銅の銀
        }
    }

    var short: String {
        switch self {
        case .yen500: return "500"
        case .yen100: return "100"
        case .yen50:  return "50"
        case .yen10:  return "10"
        case .yen5:   return "5"
        case .yen1:   return "1"
        }
    }
}
