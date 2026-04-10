//
//  DashboardView.swift
//  CleanSweep
//

import SwiftUI

struct DashboardView: View {
    @State private var viewModel = HealthDashboardViewModel()

    var body: some View {
        VStack {
            HealthDashboardRow(viewModel: viewModel)

            Spacer()

            ContentUnavailableView(
                "Ready to Scan",
                systemImage: "sparkles",
                description: Text("Click Scan Now to find junk files and free up space.")
            )
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            Spacer()
        }
        .onAppear {
            viewModel.updateStats()
        }
    }
}

struct HealthDashboardRow: View {
    var viewModel: HealthDashboardViewModel

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            MetricCard(symbol: "internaldrive", label: "Free Space", value: viewModel.freeSpace, tint: .blue)
            MetricCard(symbol: "memorychip", label: "Memory", value: viewModel.memoryStatus, tint: .green)
            MetricCard(symbol: "battery.100percent", label: "Battery", value: "Good", tint: .green)
            MetricCard(symbol: "clock.arrow.circlepath", label: "Last Cleaned", value: viewModel.lastCleaned, tint: .secondary)
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
    
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.title2)
                .symbolEffect(.bounce, value: isHovered)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.monospacedDigit())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(minWidth: 140, alignment: .leading)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    DashboardView()
        .padding()
}
