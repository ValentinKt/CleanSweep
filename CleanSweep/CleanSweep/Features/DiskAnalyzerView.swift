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
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Disk Analyzer")
                        .font(.largeTitle.bold())

                    Text("Review storage distribution inside the same Smart Scan inspired glass shell.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 560)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .glassEffect(.regular, in: Capsule())

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
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack(spacing: 16) {
                    metricCard(
                        title: "Used Space",
                        value: formattedBytes(usedSpace),
                        systemImage: "externaldrive.fill"
                    )
                    metricCard(
                        title: "Largest Category",
                        value: largestCategory.name,
                        systemImage: "chart.pie.fill"
                    )
                }

                HStack(spacing: 12) {
                    featurePill("Usage Breakdown", systemImage: "chart.pie")
                    featurePill("Largest Areas", systemImage: "arrow.up.forward.circle")
                    featurePill("Space Review", systemImage: "internaldrive")
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(diskUsage.filter { $0.name != "Free" }) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.name)
                            Spacer()
                            Text(formattedBytes(item.size))
                                .font(.body.monospacedDigit())
                        }
                    }
                }
                .padding()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(32)
            .frame(maxWidth: 760)
        }
    }

    private var usedSpace: Int64 {
        diskUsage
            .filter { $0.name != "Free" }
            .map(\.size)
            .reduce(0, +)
    }

    private var largestCategory: DiskUsageCategory {
        diskUsage
            .filter { $0.name != "Free" }
            .max(by: { $0.size < $1.size }) ?? diskUsage[0]
    }

    private func formattedBytes(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func metricCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func featurePill(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
    }
}

struct DiskUsageCategory: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let color: Color
}
