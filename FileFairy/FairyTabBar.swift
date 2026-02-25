// FairyTabBar.swift
// FileFairy
//
// Glassmorphic tab bar using .ultraThinMaterial with floating appearance.
// Floats above content via .safeAreaInset(edge: .bottom) pattern.
// Selected state: filled capsule behind icon. Spring animation on switch.

import SwiftUI

// MARK: - FairyTabBar

struct FairyTabBar: View {

    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var router = env.router

        HStack(alignment: .center, spacing: 0) {
            ForEach(TabDestination.allCases) { tab in
                FairyTabItem(
                    tab: tab,
                    isSelected: router.selectedTab == tab
                ) {
                    handleTabTap(tab, router: router)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background {
            ZStack {
                // Glassmorphic material base
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Subtle white overlay to lighten the glass
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .fill(Color.white.opacity(0.1))

                // Thin top border for glass edge highlight
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: -4)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }

    // MARK: - Tab Switch

    private func handleTabTap(_ tab: TabDestination, router: AppRouter) {
        env.haptics.light()
        env.sounds.play(.tabSwitch)
        withAnimation(.fairySnappy) {
            router.switchTab(tab)
        }
    }
}

// MARK: - FairyTabItem

private struct FairyTabItem: View {

    let tab: TabDestination
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxxs) {
                // Icon with capsule indicator
                ZStack {
                    // Selected capsule background
                    if isSelected {
                        Capsule()
                            .fill(tab.activeColor.opacity(0.15))
                            .frame(width: 56, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: tab.systemImageName)
                        .font(.system(size: isSelected ? 20 : 22, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? tab.activeColor : Color.secondary)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 56, height: 32)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)

                // Label
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected ? tab.activeColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(FairyTabButtonStyle(isSelected: isSelected))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - FairyTabButtonStyle

private struct FairyTabButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Glassmorphic Tab Bar") {
    let env = AppEnvironment()

    return ZStack(alignment: .bottom) {
        LinearGradient(
            colors: [Color.Fairy.dust, Color.Fairy.lavenderMist.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            FairyTabBar()
        }
    }
    .environment(env)
}
