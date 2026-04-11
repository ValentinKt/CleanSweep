//
//  SidebarView.swift
//  CleanSweep
//

import SwiftUI

@available(macOS 26.0, *)
struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        CleanSweepSidebarPanel(padding: 16) {
            VStack(spacing: 18) {
                sidebarHeader
                sidebarList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 280, idealWidth: 300, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            CleanSweepWindowBackground()
        }
    }

    private var sidebarList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sidebarSection(
                    title: "Overview",
                    items: [.dashboard, .smartScan]
                )
                sidebarSection(
                    title: "Clean",
                    items: [
                        .systemJunk,
                        .largeFiles,
                        .duplicates,
                        .screenshots,
                        .development,
                        .trash,
                        .mailAttachments
                    ]
                )
                sidebarSection(
                    title: "Protect",
                    items: [.privacy, .networkCache]
                )
                sidebarSection(
                    title: "Manage",
                    items: [.uninstaller, .startup, .memory, .disk, .fonts]
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, 2, for: .scrollContent)
    }

    private func sidebarSection(title: String, items: [SidebarItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title)

            VStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    SidebarRow(
                        item: item,
                        isSelected: selection == item,
                        action: { selection = item }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Capsule(style: .continuous)
                .fill(CleanSweepPalette.accentBlue.opacity(0.75))
                .frame(width: 18, height: 3)

            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(.secondary.opacity(0.9))
        }
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                CleanSweepHeroIcon(systemImage: "bubbles.and.sparkles", size: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text("CleanSweep")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Mac Health Suite")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }     
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(headerBackground)
    }

    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.58),
                        colorScheme == .dark
                            ? Color.white.opacity(0.04)
                            : Color.white.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.24),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }

    private func statusPill(title: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        }
    }
}

@available(macOS 26.0, *)
struct SidebarRow: View {
    let item: SidebarItem
    var isSelected: Bool
    var badge: String?
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconView

                Text(item.localizedName)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected
                                        ? Color.white.opacity(0.18)
                                        : CleanSweepPalette.accentBlue.opacity(0.16)
                                )
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                rowBackground
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isSelected
                                ? [
                                    Color.white.opacity(colorScheme == .dark ? 0.34 : 0.72),
                                    CleanSweepPalette.accentTeal.opacity(0.24)
                                ]
                                : isHovered
                                    ? [
                                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.30),
                                        Color.clear
                                    ]
                                    : [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1 : 0.5
                    )
            }
            .shadow(
                color: isSelected
                    ? CleanSweepPalette.accentBlue.opacity(colorScheme == .dark ? 0.34 : 0.18)
                    : .clear,
                radius: 20,
                y: 10
            )
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isHovered)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
        }
        .buttonStyle(.plain)
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
                                Color.white.opacity(colorScheme == .dark ? 0.16 : 0.42),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.14)
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
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(width: 32, height: 32)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isSelected
                        ? [
                            CleanSweepPalette.accentBlue.opacity(colorScheme == .dark ? 0.48 : 0.20),
                            CleanSweepPalette.accentTeal.opacity(colorScheme == .dark ? 0.30 : 0.12)
                        ]
                        : isHovered
                            ? [
                                Color.white.opacity(colorScheme == .dark ? 0.10 : 0.26),
                                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08)
                            ]
                            : [
                                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.10),
                                Color.white.opacity(colorScheme == .dark ? 0.01 : 0.03)
                            ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
