import SwiftUI

/// 表のように縦にそろえる列の幅。行ごとに文字の長さが違っても、数字と棒の位置をそろえる。
package enum ColumnWidth {
    /// 種族値の名前の列。「とくぼう」（4 文字）や「Sp. Atk」が 1 行に収まる幅。
    package static let statLabel: CGFloat = 72
    /// 種族値の数字の列。3 桁（最大 255）が右そろえで収まる幅。
    package static let statValue: CGFloat = 32
}
