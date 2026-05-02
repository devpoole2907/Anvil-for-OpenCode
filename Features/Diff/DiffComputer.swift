import Foundation

/// Tiny LCS-based line diff. Suitable for edit/write tool previews.
/// NOTE: O(n*m) memory; fine for the sub-1000-line diffs we expect.
enum DiffComputer {
    static func compute(before: String, after: String) -> [DiffLine] {
        let a = before.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let b = after.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        let n = a.count
        let m = b.count
        guard n > 0 || m > 0 else { return [] }

        var lcs = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0..<n {
            for j in 0..<m {
                if a[i] == b[j] {
                    lcs[i + 1][j + 1] = lcs[i][j] + 1
                } else {
                    lcs[i + 1][j + 1] = max(lcs[i + 1][j], lcs[i][j + 1])
                }
            }
        }

        var result: [DiffLine] = []
        var i = n
        var j = m
        while i > 0 && j > 0 {
            if a[i - 1] == b[j - 1] {
                result.append(DiffLine(kind: .context, text: a[i - 1]))
                i -= 1
                j -= 1
            } else if lcs[i - 1][j] >= lcs[i][j - 1] {
                result.append(DiffLine(kind: .deletion, text: a[i - 1]))
                i -= 1
            } else {
                result.append(DiffLine(kind: .addition, text: b[j - 1]))
                j -= 1
            }
        }
        while i > 0 {
            result.append(DiffLine(kind: .deletion, text: a[i - 1]))
            i -= 1
        }
        while j > 0 {
            result.append(DiffLine(kind: .addition, text: b[j - 1]))
            j -= 1
        }
        return result.reversed()
    }
}
