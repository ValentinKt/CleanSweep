//
//  SidebarView.swift
//  CleanSweep
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let sidebarShape = RoundedRectangle(cornerRadius: 26, style: .continuous)

    var body: some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 24) {
                sidebarHeader
                sidebarList
                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .padding(.bottom, 36)
            .padding(.horizontal, 24)
            .frame(width: 280)
            .liquidGlass(sidebarShape, interactive: false, variant: .sidebar)
            .clipShape(sidebarShape)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                        action: {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82)) {
                                selection = item
                            }
                        }
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
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var sidebarHeader: some View {
        let headerShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return HStack(spacing: 12) {
            Image(systemName: "bubbles.and.sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 2) {
                Text("CleanSweep")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))

                Text("Mac Health Suite")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(headerShape, interactive: false, variant: .clear)
        .clipShape(headerShape)
    }

    private func statusPill(title: String, tint: Color) -> some View {
        let pillShape = Capsule(style: .continuous)

        return HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(pillShape, interactive: false, variant: .clear)
        .clipShape(pillShape)
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    var isSelected: Bool
    var badge: String?
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        let rowShape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let isActive = isSelected || isHovered

        Button(action: action) {
            HStack(spacing: 12) {
                iconView

                Text(item.localizedName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(.white.opacity(isSelected ? 0.92 : 0.78))
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
                                        ? Color.white.opacity(0.16)
                                        : Color.white.opacity(0.08)
                                )
                        )
                        .foregroundStyle(.white.opacity(isSelected ? 0.92 : 0.70))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(rowShape, interactive: isActive, variant: isSelected ? .selection : .clear)
            .clipShape(rowShape)
            .overlay {
                if isSelected {
                    rowShape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    CleanSweepPalette.iconBg.opacity(0.42),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
                }
            }
            .opacity(isSelected || isHovered ? 1 : 0.96)
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
        let iconShape = RoundedRectangle(cornerRadius: 7, style: .continuous)

        ZStack {
            if isSelected {
                iconShape
                    .fill(CleanSweepPalette.iconBg)
                    .shadow(color: CleanSweepPalette.iconBg.opacity(0.4), radius: 8, y: 4)
            } else {
                iconShape
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        iconShape
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }

            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.82))
        }
        .frame(width: 32, height: 32)
    }
}
