//
//  DashboardView.swift
//  CleanSweep
//

import SwiftUI

struct DashboardView: View {
    @State private var viewModel = HealthDashboardViewModel()
    var onStartSmartScan: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                HealthDashboardRow(viewModel: viewModel)
                healthHighlights
                quickActions
            }
            .padding(28)
        }
        .onAppear {
            viewModel.updateStats()
        }
    }

    private var heroSection: some View {
        CleanSweepSurface(cornerRadius: 24, padding: 28, variant: .panel) {
            HStack(spacing: 24) {
                CleanSweepHeroIcon(systemImage: "sparkles", size: 108)

                VStack(alignment: .leading, spacing: 14) {
                    CleanSweepSectionEyebrow(title: "Dashboard")
                    Text("Your Mac looks healthy and ready for a polished cleanup pass.")
                        .font(.system(size: 34, weight: .bold))
                        .lineLimit(2)
                    Text(
                        "Track storage, memory, and maintenance status in one calm overview " +
                            "inspired by the best Mac utility experiences."
                    )
                    .font(.title3)
                    .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            onStartSmartScan()
                        } label: {
                            Label("Start Smart Scan", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(CleanSweepPrimaryButtonStyle())

                        Button(action: viewModel.updateStats) {
                            Label("Refresh Status", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(CleanSweepSecondaryButtonStyle())
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var healthHighlights: some View {
        HStack(spacing: 18) {
            CleanSweepSurface(cornerRadius: 20, padding: 20, variant: .card) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Protection & Privacy", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(CleanSweepPalette.accentBlue)
                    Text(
                        "Network cache, privacy traces, and attachments are ready for review when you need them."
                    )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    CleanSweepTag(title: "Trusted", systemImage: "lock.fill")
                }
            }

            CleanSweepSurface(cornerRadius: 20, padding: 20, variant: .card) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Performance Focus", systemImage: "bolt.heart.fill")
                        .font(.headline)
                        .foregroundStyle(CleanSweepPalette.success)
                    Text(
                        "Memory and startup tools are one click away to keep your Mac responsive and tidy."
                    )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    CleanSweepTag(title: "Ready", systemImage: "sparkles")
                }
            }
        }
    }

    private var quickActions: some View {
        CleanSweepSurface(cornerRadius: 22, padding: 22, variant: .card) {
            VStack(alignment: .leading, spacing: 18) {
                CleanSweepSectionEyebrow(title: "Recommended")
                Text("Everything is set for a safe cleanup")
                    .font(.title2.weight(.bold))
                Text(
                    "Use Smart Scan for a balanced pass, or jump into the Clean, Protect, " +
                        "and Manage areas for focused maintenance."
                )
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    CleanSweepTag(title: "Clean", systemImage: "bubbles.and.sparkles")
                    CleanSweepTag(title: "Protect", systemImage: "hand.raised.fill")
                    CleanSweepTag(title: "Manage", systemImage: "slider.horizontal.3")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HealthDashboardRow: View {
    var viewModel: HealthDashboardViewModel

    var body: some View {
        HStack(spacing: 16) {
            MetricCard(
                symbol: "internaldrive.fill",
                label: "Free Space",
                value: viewModel.freeSpace,
                tint: CleanSweepPalette.accentBlue
            )
            MetricCard(
                symbol: "memorychip.fill",
                label: "Memory",
                value: viewModel.memoryStatus,
                tint: CleanSweepPalette.success
            )
            MetricCard(
                symbol: "battery.100percent.bolt",
                label: "Battery",
                value: viewModel.batteryStatus,
                tint: CleanSweepPalette.success
            )
            MetricCard(
                symbol: "clock.arrow.circlepath",
                label: "Last Cleaned",
                value: viewModel.lastCleaned,
                tint: CleanSweepPalette.accentTeal
            )
        }
    }
}

struct MetricCard: View {
    let symbol: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        CleanSweepSurface(cornerRadius: 20, padding: 18, variant: .card) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.6)
                        )
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                        .font(.title3.weight(.semibold))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 140, alignment: .leading)
    }
}

#Preview {
    DashboardView()
}
