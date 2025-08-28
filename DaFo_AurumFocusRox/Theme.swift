//
//  Theme.swift
//  AurumFocus
//

import SwiftUI

struct AurumTheme {
    // MARK: - Colors
    
    static let backgroundPrimary = Color(hex: "0B0F14")
    static let backgroundElevated = Color(hex: "11161D")
    static let surfaceCard = Color(hex: "151B23")
    static let goldAccent = Color(hex: "D4AF37")
    static let secondaryGold = Color(hex: "C19A2B")
    static let primaryText = Color(hex: "FFFFFF")
    static let secondaryText = Color(hex: "C9D1D9")
    static let dividers = Color(hex: "232B34")
    static let success = Color(hex: "16A34A")
    static let warning = Color(hex: "F59E0B")
    static let danger = Color(hex: "EF4444")
    static let positiveChart = Color(hex: "22C55E")
    static let negativeChart = Color(hex: "EF4444")
    static let secondaryButton = Color(hex: "1C2430")
    static let inputBackground = Color(hex: "0F141A")
    static let inputField = Color(hex: "0F141A")
    
    // MARK: - Gradients
    
    static let primaryGradient = LinearGradient(
        colors: [goldAccent, secondaryGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = RadialGradient(
        colors: [backgroundElevated, backgroundPrimary],
        center: .topTrailing,
        startRadius: 100,
        endRadius: 400
    )
    
    // MARK: - Shadows
    
    static let cardShadow = Color.black.opacity(0.3)
    
    // MARK: - Corner Radius
    
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 24
    static let smallRadius: CGFloat = 8
    
    // MARK: - Spacing
    
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let largePadding: CGFloat = 24
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AurumTheme.surfaceCard)
            .cornerRadius(AurumTheme.cardRadius)
            .shadow(color: AurumTheme.cardShadow, radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: AurumTheme.cardRadius)
                    .stroke(AurumTheme.goldAccent.opacity(0.1), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(AurumTheme.backgroundPrimary)
            .padding(.horizontal, AurumTheme.largePadding)
            .padding(.vertical, AurumTheme.padding)
            .background(
                Group {
                    if isEnabled {
                        AurumTheme.primaryGradient
                    } else {
                        AurumTheme.secondaryButton
                    }
                }
            )
            .cornerRadius(AurumTheme.buttonRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(AurumTheme.primaryText)
            .padding(.horizontal, AurumTheme.padding)
            .padding(.vertical, AurumTheme.smallPadding)
            .background(AurumTheme.secondaryButton)
            .cornerRadius(AurumTheme.smallRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButtonStyle() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
}

// MARK: - Typography

extension Font {
    static let aurumTitle = Font.largeTitle.weight(.bold)
    static let aurumHeadline = Font.title2.weight(.semibold)
    static let aurumSubheadline = Font.headline.weight(.medium)
    static let aurumBody = Font.body.weight(.regular)
    static let aurumCaption = Font.caption.weight(.medium)
    static let aurumMoney = Font.body.weight(.semibold).monospacedDigit()
    static let aurumLargeMoney = Font.title2.weight(.bold).monospacedDigit()
}
