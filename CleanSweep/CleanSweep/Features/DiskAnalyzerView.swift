import SwiftUI
import Charts

@available(macOS 26.0, *)
struct DiskAnalyzerView: View {
    @State private var diskUsage: [DiskUsageCategory] = [
        DiskUsageCategory(name: "System", size: 40_000_000_000, color: .gray),
        DiskUsageCategory(name: "Apps", size: 80_000_000_000, color: .blue),
        DiskUsageCategory(name: "Documents", size: 150_000_000_000, color: .orange),
        DiskUsageCategory(name: "Media", size: 100_000_000_000, color: .purple),
        DiskUsageCategory(name: "Other", size: 30_000_000_000, color: .green),
        DiskUsageCategory(name: "Free", size: 200_000_000_000, color: .clear)
    ]

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Disk Analyzer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Chart(diskUsage) { item in
                    SectorMark(
                        angle: .value("Size", item.size),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(item.color)
                }
                .frame(height: 300)
                .padding()

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(diskUsage.filter { $0.name != "Free" }) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.name)
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                .font(.body.monospacedDigit())
                        }
                    }
                }
                .padding()
            }
            .padding(40)
        }
    }
}

struct DiskUsageCategory: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let color: Color
}
