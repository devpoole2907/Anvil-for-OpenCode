import SwiftUI

struct DiffLinesView: View {
    let lines: [DiffLine]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    DiffLineRow(line: line)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 320)
    }
}
