import SwiftUI

#if os(iOS)
import UIKit
import MediaPlayer

// MARK: - Apple Music 风格 A-Z 与五十音（假名）分段索引助手
struct SectionIndexHelper {
    static var isJapaneseLanguage: Bool {
        if let preferred = Locale.preferredLanguages.first, preferred.hasPrefix("ja") {
            return true
        }
        if Locale.current.language.languageCode?.identifier == "ja" {
            return true
        }
        return false
    }

    // 索引字母列表：日语界面包含假名行首字，中英文界面使用 A-Z + #
    static var indexTitles: [String] {
        if isJapaneseLanguage {
            return [
                "あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ",
                "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"
            ]
        } else {
            return [
                "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"
            ]
        }
    }

    // 根据字符串首字符提取分段键
    static func sectionKey(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstChar = trimmed.first else { return "#" }
        let charString = String(firstChar)

        // 1. 判断日语平假名与片假名行首字
        let kanaGroups: [(String, [Character])] = [
            ("あ", ["あ","い","う","え","お","ア","イ","ウ","エ","オ","ぁ","ぃ","ぅ","ぇ","ぉ","ァ","ィ","ゥ","ェ","ォ"]),
            ("か", ["か","き","く","け","こ","カ","キ","ク","ケ","コ","が","ぎ","ぐ","げ","ご","ガ","ギ","グ","ゲ","ゴ"]),
            ("さ", ["さ","し","す","せ","そ","サ","シ","ス","セ","ソ","ざ","じ","ず","ぜ","ぞ","ザ","ジ","ズ","ゼ","ゾ"]),
            ("た", ["た","ち","つ","て","と","タ","チ","ツ","テ","ト","だ","ぢ","づ","で","ど","ダ","ヂ","ヅ","デ","ド","っ","ッ"]),
            ("な", ["な","に","ぬ","ね","の","ナ","ニ","ヌ","ネ","ノ"]),
            ("は", ["は","ひ","ふ","へ","ほ","ハ","ヒ","フ","ヘ","ホ","ば","び","ぶ","べ","ぼ","バ","ビ","ブ","ベ","ボ","ぱ","ぴ","ぷ","ぺ","ぽ","パ","ピ","プ","ペ","ポ"]),
            ("ま", ["ま","み","む","め","も","マ","ミ","ム","メ","モ"]),
            ("や", ["や","ゆ","よ","ヤ","ユ","ヨ","ゃ","ゅ","ょ","ャ","ュ","ョ"]),
            ("ら", ["ら","り","る","れ","ろ","ラ","リ","ル","レ","ロ"]),
            ("わ", ["わ","を","ん","ワ","ヲ","ン"])
        ]

        for (group, chars) in kanaGroups {
            if chars.contains(firstChar) {
                return group
            }
        }

        // 2. 判断拉丁英文字母 A-Z
        if charString.rangeOfCharacter(from: CharacterSet.letters) != nil {
            let latin = charString.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).uppercased()
            if let first = latin.first, ("A"..."Z").contains(first) {
                return String(first)
            }
        }

        // 3. 汉字转拼音首字母（中文歌曲归入 A-Z 索引）
        let mutable = NSMutableString(string: charString) as CFMutableString
        if CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false) {
            if CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false) {
                let res = (mutable as String).uppercased()
                if let first = res.first, ("A"..."Z").contains(first) {
                    return String(first)
                }
            }
        }

        return "#"
    }

    // 通用多实体分组
    static func groupItems<T>(_ items: [T], titleSelector: (T) -> String) -> [(key: String, items: [T])] {
        var dict: [String: [T]] = [:]
        for item in items {
            let title = titleSelector(item)
            let key = sectionKey(for: title)
            dict[key, default: []].append(item)
        }

        let allKeys = indexTitles
        var result: [(key: String, items: [T])] = []
        for key in allKeys {
            if let group = dict[key], !group.isEmpty {
                result.append((key: key, items: group))
            }
        }
        return result
    }
}

// MARK: - Apple Music 风格侧边悬浮滑动索引栏
struct SectionIndexBar: View {
    let sections: [String]
    let onSelect: (String) -> Void

    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var selectedIndexTitle: String?

    var body: some View {
        VStack(spacing: 1.5) {
            ForEach(sections, id: \.self) { title in
                Text(title)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 14, height: 11)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
        )
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let frame = geo.frame(in: .local)
                                let totalHeight = frame.height
                                let itemHeight = totalHeight / CGFloat(max(1, sections.count))
                                let index = Int(value.location.y / itemHeight)
                                if index >= 0 && index < sections.count {
                                    let key = sections[index]
                                    if key != selectedIndexTitle {
                                        selectedIndexTitle = key
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        onSelect(key)
                                    }
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                selectedIndexTitle = nil
                            }
                    )
            }
        )
        .overlay(
            // 拖拽时的放大提示气泡
            Group {
                if isDragging, let title = selectedIndexTitle {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 44, height: 44)
                                .shadow(radius: 4)
                            Text(title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -60)
                        Spacer()
                    }
                }
            }
        )
        .padding(.trailing, 2)
    }
}
#endif
