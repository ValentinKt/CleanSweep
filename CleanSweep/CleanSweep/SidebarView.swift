//
//  SidebarView.swift
//  CleanSweep
//

import SwiftUI

@available(macOS 26.0, *)
struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        CleanSweepSidebarPanel(padding: 16) {
            VStack(spacing: 14) {
                sidebarHeader
                sidebarList
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            CleanSweepWindowBackground()
        }
    }

    private var sidebarList: some View {
        List(selection: $selection) {
            Section {
                SidebarRow(item: .dashboard, isSelected: selection == .dashboard)
                SidebarRow(item: .smartScan, isSelected: selection == .smartScan)
            } header: {
                sectionHeader("Overview")
            }
            Section {
                SidebarRow(item: .systemJunk, isSelected: selection == .systemJunk)
                SidebarRow(item: .largeFiles, isSelected: selection == .largeFiles)
                SidebarRow(item: .duplicates, isSelected: selection == .duplicates)
                SidebarRow(item: .screenshots, isSelected: selection == .screenshots)
                SidebarRow(item: .development, isSelected: selection == .development)
                SidebarRow(item: .trash, isSelected: selection == .trash)
                SidebarRow(item: .mailAttachments, isSelected: selection == .mailAttachments)
            } header: {
                sectionHeader("Clean")
            }
            Section {
                SidebarRow(item: .privacy, isSelected: selection == .privacy)
                SidebarRow(item: .networkCache, isSelected: selection == .networkCache)
            } header: {
                sectionHeader("Protect")
            }
            Section {
                SidebarRow(item: .uninstaller, isSelected: selection == .uninstaller)
                SidebarRow(item: .startup, isSelected: selection == .startup)
                SidebarRow(item: .memory, isSelected: selection == .memory)
                SidebarRow(item: .disk, isSelected: selection == .disk)
                SidebarRow(item: .fonts, isSelected: selection == .fonts)
            } header: {
                sectionHeader("Manage")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private var sidebarHeader: some View {
        CleanSweepSurface(cornerRadius: 22, padding: 16) {
            HStack(spacing: 14) {
                CleanSweepHeroIcon(systemImage: "sparkles.rectangle.stack.fill", size: 44)
                VStack(alignment: .leading, spacing: 5) {
                    Text("CleanSweep")
                        .font(.headline.weight(.bold))
                    Text("Calm cleanup for your Mac")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

@available(macOS 26.0, *)
struct SidebarRow: View {
    let item: SidebarItem
    var isSelected: Bool
    var badge: String?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        NavigationLink(value: item) {
            HStack(spacing: 12) {
                iconView

                Text(item.localizedName)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(CleanSweepPalette.accentBlue.opacity(0.16)))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                rowBackground
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isSelected
                                ? [
                                    Color.white.opacity(colorScheme == .dark ? 0.20 : 0.60),
                                    CleanSweepPalette.accentBlue.opacity(0.18)
                                ]
                                : isHovered
                                    ? [
                                        Color.white.opacity(colorScheme == .dark ? 0.10 : 0.30),
                                        Color.clear
                                    ]
                                    : [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: isSelected
                    ? CleanSweepPalette.accentBlue.opacity(colorScheme == .dark ? 0.22 : 0.14)
                    : .clear,
                radius: 16,
                y: 8
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isHovered)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var iconView: some View {
        let iconShape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        ZStack {
            iconShape
                .fill(
                    isSelected
                        ? LinearGradient(
                            colors: [
                                CleanSweepPalette.accentTeal.opacity(0.92),
                                CleanSweepPalette.accentBlue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.10 : 0.42),
                                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
            iconShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isSelected ? 0.28 : 0.16),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .frame(width: 30, height: 30)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isSelected
                        ? [
                            Color.white.opacity(colorScheme == .dark ? 0.14 : 0.58),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.24)
                        ]
                        : isHovered
                            ? [
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.28),
                                Color.white.opacity(colorScheme == .dark ? 0.02 : 0.10)
                            ]
                            : [Color.clear, Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
