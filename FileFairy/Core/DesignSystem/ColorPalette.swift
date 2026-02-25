// ColorPalette.swift
// FileFairy
//
// Refined "moonlight magic" palette — sophisticated, barely-there color
// that feels premium. Accents are vivid but used sparingly; surfaces
// breathe with subtle lavender/violet undertones.
// Every color in the app flows through these tokens.

import SwiftUI

// MARK: - Brand Colors

extension Color {

    /// FileFairy brand color namespace
    enum Fairy {

        // MARK: Primary

        /// Navigation, primary buttons, active tabs — deep violet
        static let violet = Color(hex: "#6D28D9")

        /// Soft pressed/hover tint — pale amethyst
        static let lavenderMist = Color(.sRGB, red: 0.800, green: 0.753, blue: 0.976)      // #CCBFF9

        /// Main app background — a breath of lavender, barely perceptible
        static let dust = Color(hex: "#F7F6FF")

        // MARK: Scanner Module

        /// Scanner — refined rose, not neon
        static let rose = Color(hex: "#BE185D")

        /// Scanner section backgrounds — whisper pink
        static let blush = Color(.sRGB, red: 0.994, green: 0.953, blue: 0.976)             // #FDF2F9

        // MARK: MBOX Module

        /// MBOX — deep cerulean, confident and clear
        static let teal = Color(hex: "#0E7490")

        /// MBOX section backgrounds — ice wash
        static let iceBlue = Color(.sRGB, red: 0.929, green: 0.980, blue: 0.992)           // #EDFAFE

        // MARK: Converter Module

        /// Converter — warm amber, like old gold
        static let amber = Color(hex: "#B45309")

        /// Converter section backgrounds — warm parchment
        static let sunrise = Color(.sRGB, red: 1.000, green: 0.980, blue: 0.933)           // #FFF9EE

        // MARK: PDF Module

        /// PDF — forest green, professional
        static let green = Color(hex: "#047857")

        // MARK: Files Module

        /// Files — midnight indigo, trustworthy
        static let indigo = Color(hex: "#4338CA")

        // MARK: Semantic States

        /// Success — soft emerald
        static let mint = Color(.sRGB, red: 0.133, green: 0.773, blue: 0.529)              // #22C587

        /// Warning — soft peach
        static let coral = Color(.sRGB, red: 0.976, green: 0.533, blue: 0.200)             // #F98833

        /// Error — warm rose red, never harsh
        static let softRed = Color(.sRGB, red: 0.945, green: 0.369, blue: 0.369)           // #F15E5E

        // MARK: Surfaces

        /// Card backgrounds, modals — pure white (pops against lavender bg)
        static let cream = Color(hex: "#FFFFFF")

        /// Alternate warm card — barely-warm white
        static let cloud = Color(hex: "#FEFEFF")

        // MARK: Text

        /// Headlines, file names, primary labels — soft black (not harsh)
        static let ink = Color(hex: "#1A1628")

        /// Descriptions, metadata, secondary info
        static let slate = Color(hex: "#6B7280")

        /// Timestamps, disabled text, placeholders
        static let mist = Color(hex: "#A1A1AA")

        // MARK: Dividers

        /// List separators, card borders — lavender-tinted edge
        static let softEdge = Color(.sRGB, red: 0.898, green: 0.890, blue: 0.945)          // #E5E3F1
    }
}

// MARK: - Module Color Themes

struct ModuleTheme {
    let primary: Color
    let light: Color
    let gradient: LinearGradient

    /// Scanner: deep rose → warm crimson (ombre, not neon)
    static let scanner = ModuleTheme(
        primary: .Fairy.rose,
        light: .Fairy.blush,
        gradient: LinearGradient(
            colors: [
                Color(hex: "#BE185D"),
                Color(hex: "#E11D74")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    /// MBOX: deep cerulean → sky (trustworthy, clear)
    static let mbox = ModuleTheme(
        primary: .Fairy.teal,
        light: .Fairy.iceBlue,
        gradient: LinearGradient(
            colors: [
                Color(hex: "#0E7490"),
                Color(hex: "#0891B2")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    /// Converter: old gold → warm amber (rich, not garish)
    static let converter = ModuleTheme(
        primary: .Fairy.amber,
        light: .Fairy.sunrise,
        gradient: LinearGradient(
            colors: [
                Color(hex: "#B45309"),
                Color(hex: "#D97706")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    /// PDF: forest → emerald (calm, professional)
    static let pdf = ModuleTheme(
        primary: .Fairy.green,
        light: Color(.sRGB, red: 0.863, green: 0.969, blue: 0.922),
        gradient: LinearGradient(
            colors: [
                Color(hex: "#047857"),
                Color(hex: "#059669")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    /// Files: midnight indigo → periwinkle (deep, trustworthy)
    static let fileOpener = ModuleTheme(
        primary: .Fairy.indigo,
        light: Color(.sRGB, red: 0.929, green: 0.929, blue: 0.992),
        gradient: LinearGradient(
            colors: [
                Color(hex: "#4338CA"),
                Color(hex: "#4F46E5")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
