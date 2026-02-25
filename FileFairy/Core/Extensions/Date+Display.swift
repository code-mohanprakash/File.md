// Date+Display.swift
// FileFairy
//
// Consistent, locale-aware date display throughout the app.
// Three formatting tiers: relative ("2 hours ago"), short ("Feb 20"), full ("February 20, 2026").

import Foundation

// MARK: - Date Display

extension Date {

    // MARK: - Relative ("2 hours ago", "Yesterday", "3 days ago")

    /// Returns a relative time string using RelativeDateTimeFormatter.
    ///
    /// - Within 1 minute:  "just now"
    /// - Within 1 hour:    "5 minutes ago"
    /// - Within 24 hours:  "3 hours ago"
    /// - Within 2 days:    "Yesterday"
    /// - Within 7 days:    "3 days ago"
    /// - Beyond 7 days:    falls back to shortDisplay
    var relativeDisplay: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "just now"
        }

        if interval < 60 * 60 * 24 * 7 {
            return Date.relativeFormatter.localizedString(for: self, relativeTo: now)
        }

        // Older than a week — show a short date instead of "3 weeks ago"
        return shortDisplay
    }

    /// Returns a relative time string always, with no fallback to absolute dates.
    var relativeDisplayAlways: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        if interval < 60 { return "just now" }
        return Date.relativeFormatter.localizedString(for: self, relativeTo: now)
    }

    // MARK: - Short ("Feb 20", "Jan 1, 2024")

    /// Abbreviated month + day, with year only if it differs from today's year.
    /// e.g. "Feb 20" (same year) or "Jan 1, 2024" (different year)
    var shortDisplay: String {
        let calendar = Calendar.current
        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            return Date.shortNoYearFormatter.string(from: self)
        } else {
            return Date.shortWithYearFormatter.string(from: self)
        }
    }

    /// Always includes the year, regardless of how recent the date is.
    var shortDisplayWithYear: String {
        Date.shortWithYearFormatter.string(from: self)
    }

    // MARK: - Full ("February 20, 2026")

    /// Long form: full month name, day, and four-digit year.
    var fullDisplay: String {
        Date.fullFormatter.string(from: self)
    }

    // MARK: - Time ("3:45 PM")

    /// Localized time string using the device's 12/24h preference.
    var timeDisplay: String {
        Date.timeFormatter.string(from: self)
    }

    // MARK: - Date + Time ("Feb 20 at 3:45 PM")

    /// Short date followed by a localized time.
    var dateTimeDisplay: String {
        "\(shortDisplay) at \(timeDisplay)"
    }

    // MARK: - Today / Yesterday / Date

    /// Returns "Today", "Yesterday", or the shortDisplay string.
    var todayYesterdayOrDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return shortDisplay
        }
    }

    // MARK: - ISO 8601

    /// ISO 8601 UTC string for serialization or logging.
    var iso8601String: String {
        Date.iso8601Formatter.string(from: self)
    }

    // MARK: - Formatters (Cached)

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        f.dateTimeStyle = .named
        return f
    }()

    private static let shortNoYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let shortWithYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: - Group-By Helper

extension Date {
    /// Returns a section header string for grouping items in a list by date.
    /// Logic: "Today", "Yesterday", then the short date.
    var sectionHeaderDisplay: String {
        todayYesterdayOrDate
    }
}
