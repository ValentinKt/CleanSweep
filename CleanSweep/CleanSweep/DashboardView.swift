//
//  DashboardView.swift
//  CleanSweep
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack {
            HealthDashboardRow()

            Spacer()

            ContentUnavailableView(
                "Ready to Scan",
                systemImage: "sparkles",
                description: Text("Click Scan Now to find junk files and free up space.")
            )

            Spacer()
        }
    }
}

struct HealthDashboardRow: View {
    var body: some View {
        GlassEffectContainer(spacing: 10) {
            MetricCard(symbol: "internaldrive", label: "Storage", value: "245 GB", tint: .blue)
            MetricCard(symbol: "memorychip", label: "Memory", value: "Normal", tint: .green)
            MetricCard(symbol: "battery.100percent", label: "Battery", value: "100%", tint: .green)
            MetricCard(symbol: "clock.arrow.circlepath", label: "Last Cleaned", value: "2 days ago", tint: .secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct MetricCard: View {
    let symbol: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.title3)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(minWidth: 120, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .padding()
}
