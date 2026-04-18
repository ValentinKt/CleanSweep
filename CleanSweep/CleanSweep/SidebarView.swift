//
//  SidebarView.swift
//  CleanSweep
//

import SwiftUI

@available(macOS 26.0, *)
struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        CleanSweepSidebarPanel(padding: 16) {
            VStack(spacing: 18) {
                sidebarHeader
                sidebarList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                    items: [.uninstaller, .leftovers, .startup, .memory, .disk, .fonts]
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
                .fill(CleanSweepPalette.iconBg.opacity(0.75))
                .frame(width: 4, height: 12)

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
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        return Color.clear
            .cleanSweepGlass(
                in: shape,
                tint: colorScheme == .dark
                    ? Color.white.opacity(0.05)
                    : Color.white.opacity(0.18),
                interactive: true,
                reduceTransparency: reduceTransparency
            )
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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false

    var body: some View {
        let rowShape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        Button(action: action) {
            HStack(spacing: 12) {
                iconView

                Text(item.localizedName)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected
                                        ? Color.white.opacity(0.15)
                                        : Color.black.opacity(0.08)
                                )
                        )
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(rowBackground(shape: rowShape))
            .overlay(alignment: .topLeading) {
                if isSelected {
                    rowShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.20),
                                    Color.white.opacity(0.04),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .mask(
                            Rectangle()
                                .frame(height: 20)
                                .frame(maxHeight: .infinity, alignment: .top)
                        )
                        .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }

    @ViewBuilder
    private var iconView: some View {
        let iconShape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        ZStack {
            if isSelected {
                iconShape
                    .fill(CleanSweepPalette.iconBg)
                    .shadow(color: CleanSweepPalette.iconBg.opacity(0.4), radius: 8, y: 4)
            } else {
                iconShape
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.4))
                    .overlay(
                        iconShape
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }

            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? .white : CleanSweepPalette.iconBg)
        }
        .frame(width: 32, height: 32)
    }

    @ViewBuilder
    private func rowBackground(shape: RoundedRectangle) -> some View {
        if isSelected {
            Color.clear
                .cleanSweepGlass(
                    in: shape,
                    tint: colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.18),
                    interactive: true,
                    reduceTransparency: reduceTransparency
                )
                .overlay {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.05),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .allowsHitTesting(false)
                }
        } else if isHovered {
            Color.clear
                .cleanSweepGlass(
                    in: shape,
                    tint: colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.white.opacity(0.10),
                    interactive: true,
                    reduceTransparency: reduceTransparency
                )
        } else {
            shape
                .fill(Color.clear)
        }
    }
}
