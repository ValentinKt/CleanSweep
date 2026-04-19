import SwiftUI
import Charts

struct DiskAnalyzerView: View {
    @State private var diskUsage: [DiskUsageCategory] = [
        DiskUsageCategory(name: "System", size: 40_000_000_000, color: Color(hex: UInt32(0x8E8E93))),
        DiskUsageCategory(name: "Apps", size: 80_000_000_000, color: CleanSweepPalette.accentBlue),
        DiskUsageCategory(name: "Documents", size: 150_000_000_000, color: Color(hex: UInt32(0xFF9F0A))),
        DiskUsageCategory(name: "Media", size: 100_000_000_000, color: Color(hex: UInt32(0xBF5AF2))),
        DiskUsageCategory(name: "Other", size: 30_000_000_000, color: CleanSweepPalette.accentTeal),
        DiskUsageCategory(name: "Free", size: 200_000_000_000, color: .clear)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection

                HStack(spacing: 16) {
                    metricCard(
                        title: "Used Space",
                        value: formattedBytes(usedSpace),
                        systemImage: "externaldrive.fill",
                        accent: CleanSweepPalette.accentBlue
                    )
                    metricCard(
                        title: "Largest Category",
                        value: largestCategory.name,
                        systemImage: "chart.pie.fill",
                        accent: largestCategory.color
                    )
                    metricCard(
                        title: "Available",
                        value: formattedBytes(freeSpace),
                        systemImage: "internaldrive.fill.badge.checkmark",
                        accent: CleanSweepPalette.success
                    )
                }

                chartSection
                legendSection
            }
            .padding(28)
        }
    }

    private var heroSection: some View {
        CleanSweepSurface(cornerRadius: 26, padding: 28, variant: .panel) {
            HStack(spacing: 24) {
                CleanSweepHeroIcon(systemImage: "internaldrive.fill", size: 104)

                VStack(alignment: .leading, spacing: 14) {
                    CleanSweepSectionEyebrow(title: "Disk")
                    Text("See exactly where your storage goes.")
                        .font(.system(size: 34, weight: .bold))
                    Text(
                        "Review storage distribution with a premium, card-based analyzer " +
                            "that mirrors the confidence of the best Mac maintenance tools."
                    )
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        CleanSweepTag(title: "Usage Breakdown", systemImage: "chart.pie.fill")
                        CleanSweepTag(title: "Largest Areas", systemImage: "arrow.up.forward.circle.fill")
                        CleanSweepTag(title: "Space Review", systemImage: "sparkles")
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var chartSection: some View {
        CleanSweepSurface(cornerRadius: 26, padding: 24, variant: .panel) {
            HStack(spacing: 24) {
                Chart(diskUsage) { item in
                    SectorMark(
                        angle: .value("Size", item.size),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .cornerRadius(6)
                    .foregroundStyle(item.color)
                }
                .frame(width: 320, height: 320)

                VStack(alignment: .leading, spacing: 16) {
                    CleanSweepSectionEyebrow(title: "Storage Map")
                    Text("Largest storage footprint: \(largestCategory.name)")
                        .font(.title2.weight(.bold))
                    Text(
                        "Use the donut chart to compare major categories at a glance " +
                            "before jumping into more focused cleanup areas."
                    )
                        .font(.body)
                        .foregroundStyle(.secondary)

                    CleanSweepSurface(cornerRadius: 18, padding: 16, variant: .card) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Free Space", systemImage: "internaldrive.fill.badge.checkmark")
                                .font(.headline)
                                .foregroundStyle(CleanSweepPalette.success)
                            Text(formattedBytes(freeSpace))
                                .font(.title3.weight(.bold))
                                .monospacedDigit()
                            Text(
                                "Healthy free space helps macOS stay responsive during scans, " +
                                    "installs, and cache cleanup."
                            )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var legendSection: some View {
        CleanSweepSurface(cornerRadius: 24, padding: 22, variant: .card) {
            VStack(alignment: .leading, spacing: 14) {
                CleanSweepSectionEyebrow(title: "Categories")
                ForEach(nonFreeCategories) { item in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text(formattedBytes(item.size))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var usedSpace: Int64 {
        nonFreeCategories.map(\.size).reduce(0, +)
    }

    private var freeSpace: Int64 {
        diskUsage.first(where: { $0.name == "Free" })?.size ?? 0
    }

    private var largestCategory: DiskUsageCategory {
        nonFreeCategories.max(by: { $0.size < $1.size }) ?? diskUsage[0]
    }

    private var nonFreeCategories: [DiskUsageCategory] {
        diskUsage.filter { $0.name != "Free" }
    }

    private func formattedBytes(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func metricCard(title: String, value: String, systemImage: String, accent: Color) -> some View {
        CleanSweepSurface(cornerRadius: 20, padding: 18, variant: .card) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.14))
                    Image(systemName: systemImage)
                        .foregroundStyle(accent)
                        .font(.title3)
                }
                .frame(width: 42, height: 42)

                Text(value)
                    .font(.title2.bold().monospacedDigit())
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DiskUsageCategory: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let color: Color
}
