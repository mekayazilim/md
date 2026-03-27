//
//  ThemeDefinitions.swift
//  mdviewer
//

internal import AppKit
internal import SwiftUI

// MARK: - Theme Definitions

/// Concrete color values for each `AppTheme` / `ColorScheme` combination.
/// All themes support both light and dark appearance modes with consistent spacing.
extension NativeThemePalette {
    init(theme: AppTheme, scheme: ColorScheme) {
        self.theme = theme
        self.scheme = scheme

        let data = theme.colorData(for: scheme)

        // Text Colors
        textPrimary = data.textPrimary
        textSecondary = data.textSecondary
        textTertiary = data.textTertiary

        // Structural Colors
        background = data.background

        // Interactive Colors
        link = data.link
        linkHover = data.linkHover
        accent = data.accent

        // Heading Colors
        heading = data.heading
        heading1 = data.heading
        heading2 = data.heading
        heading3 = data.heading

        // Code Colors
        codeBackground = data.codeBackground
        codeBorder = data.codeBorder
        inlineCodeBackground = data.inlineCodeBackground
        codeText = data.codeText

        // Blockquote Colors
        blockquoteAccent = data.blockquoteAccent
        blockquoteBackground = data.blockquoteBackground
        blockquoteText = data.blockquoteText

        // Table Colors
        tableHeaderBackground = data.tableHeaderBackground
        tableBorder = data.tableBorder
        tableRowAlternating = data.tableRowAlternating

        // List Colors
        listMarker = data.listMarker
        taskListUnchecked = data.taskListUnchecked
        taskListChecked = data.taskListChecked

        // Rule Color
        horizontalRule = data.horizontalRule

        // Selection Color
        selectionBackground = data.selectionBackground
        selectionText = data.selectionText

        // Normalize explicit raw heading level tokens for every theme.
        // This keeps level tokens differentiated at the definition layer.
        let rawHeadingLevels = Self.rawHeadingLevels(
            base: heading,
            accent: accent,
            primary: textPrimary,
            scheme: scheme
        )
        heading1 = rawHeadingLevels.h1
        heading2 = rawHeadingLevels.h2
        heading3 = rawHeadingLevels.h3

        let rawBlockquote = Self.rawBlockquoteTokens(
            accent: blockquoteAccent,
            background: blockquoteBackground,
            text: blockquoteText,
            link: link,
            textSecondary: textSecondary,
            scheme: scheme
        )
        blockquoteAccent = rawBlockquote.accent
        blockquoteBackground = rawBlockquote.background
        blockquoteText = rawBlockquote.text

        let rawTable = Self.rawTableTokens(
            header: tableHeaderBackground,
            border: tableBorder,
            rowAlternating: tableRowAlternating,
            accent: accent,
            codeBackground: codeBackground,
            inlineCodeBackground: inlineCodeBackground,
            scheme: scheme
        )
        tableHeaderBackground = rawTable.header
        tableBorder = rawTable.border
        tableRowAlternating = rawTable.rowAlternating

        // Cache derived formatting tokens so render passes avoid repeated blending.
        formattedHeading = Self.derivedHeadingColor(
            base: heading,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 0
        )
        formattedHeading1 = Self.derivedHeadingColor(
            base: heading1,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 1
        )
        formattedHeading2 = Self.derivedHeadingColor(
            base: heading2,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 2
        )
        formattedHeading3 = Self.derivedHeadingColor(
            base: heading3,
            accent: accent,
            link: link,
            textPrimary: textPrimary,
            theme: theme,
            scheme: scheme,
            level: 3
        )
        formattedTableHeaderSurface = Self.derivedTableHeaderBackground(
            base: tableHeaderBackground,
            codeBackground: codeBackground,
            scheme: scheme
        )
        formattedTableHeaderText = Self.derivedTableHeaderText(
            base: heading,
            textPrimary: textPrimary,
            scheme: scheme
        )
        formattedTableBodySurface = Self.derivedTableBodyBackground(
            header: tableHeaderBackground,
            codeBackground: codeBackground,
            rowAlternating: tableRowAlternating,
            scheme: scheme
        )
        formattedTableRowSurface = Self.derivedTableRowBackground(
            base: tableRowAlternating,
            body: formattedTableBodySurface,
            inlineCodeBackground: inlineCodeBackground,
            scheme: scheme
        )
        formattedTableBorderStroke = Self.derivedTableBorder(
            base: tableBorder,
            accent: accent,
            theme: theme,
            scheme: scheme
        )
        formattedLinkUnderline = Self.derivedLinkUnderline(
            link: link,
            textPrimary: textPrimary,
            scheme: scheme
        )
    }
}

// MARK: - Formatting Integration

extension NativeThemePalette {
    fileprivate static func rawHeadingLevels(
        base: NSColor,
        accent: NSColor,
        primary: NSColor,
        scheme: ColorScheme
    ) -> (h1: NSColor, h2: NSColor, h3: NSColor) {
        let h1AccentMix: CGFloat = scheme == .dark ? 0.14 : 0.02
        let h2AccentMix: CGFloat = scheme == .dark ? 0.09 : 0.06
        let h3AccentMix: CGFloat = scheme == .dark ? 0.05 : 0.03
        let h2TextMix: CGFloat = scheme == .dark ? 0.06 : 0.03
        let h3TextMix: CGFloat = scheme == .dark ? 0.10 : 0.06

        let h1 = base.blended(withFraction: h1AccentMix, of: accent) ?? base
        let h2Accent = base.blended(withFraction: h2AccentMix, of: accent) ?? base
        let h2 = h2Accent.blended(withFraction: h2TextMix, of: primary) ?? h2Accent
        let h3Accent = base.blended(withFraction: h3AccentMix, of: accent) ?? base
        let h3 = h3Accent.blended(withFraction: h3TextMix, of: primary) ?? h3Accent

        return (h1, h2, h3)
    }

    fileprivate static func rawBlockquoteTokens(
        accent: NSColor,
        background: NSColor,
        text: NSColor,
        link: NSColor,
        textSecondary: NSColor,
        scheme: ColorScheme
    ) -> (accent: NSColor, background: NSColor, text: NSColor) {
        let accentMix: CGFloat = scheme == .dark ? 0.10 : 0.06
        let bgLinkMix: CGFloat = scheme == .dark ? 0.08 : 0.05
        let textMix: CGFloat = scheme == .dark ? 0.14 : 0.08

        let normalizedAccent = accent.blended(withFraction: accentMix, of: link) ?? accent
        let normalizedBackground = background.blended(withFraction: bgLinkMix, of: normalizedAccent) ?? background
        let normalizedText = text.blended(withFraction: textMix, of: textSecondary) ?? text

        return (normalizedAccent, normalizedBackground, normalizedText)
    }

    fileprivate static func rawTableTokens(
        header: NSColor,
        border: NSColor,
        rowAlternating: NSColor,
        accent: NSColor,
        codeBackground: NSColor,
        inlineCodeBackground: NSColor,
        scheme: ColorScheme
    ) -> (header: NSColor, border: NSColor, rowAlternating: NSColor) {
        let headerCodeMix: CGFloat = scheme == .dark ? 0.12 : 0.08
        let borderAccentMix: CGFloat = scheme == .dark ? 0.14 : 0.08
        let rowInlineMix: CGFloat = scheme == .dark ? 0.07 : 0.04

        let normalizedHeader = header.blended(withFraction: headerCodeMix, of: codeBackground) ?? header
        let normalizedBorder = border.blended(withFraction: borderAccentMix, of: accent) ?? border
        let normalizedRow = rowAlternating
            .blended(withFraction: rowInlineMix, of: inlineCodeBackground) ?? rowAlternating

        return (normalizedHeader, normalizedBorder, normalizedRow)
    }

    fileprivate static func derivedHeadingColor(
        base: NSColor,
        accent: NSColor,
        link: NSColor,
        textPrimary: NSColor,
        theme: AppTheme,
        scheme: ColorScheme,
        level: Int
    ) -> NSColor {
        let accentMix: CGFloat
        let textMix: CGFloat
        switch level {
        case 1:
            accentMix = scheme == .dark ? 0.20 : 0.14
            textMix = 0

        case 2:
            accentMix = scheme == .dark ? 0.12 : 0.08
            textMix = scheme == .dark ? 0.08 : 0.04

        case 3:
            accentMix = scheme == .dark ? 0.06 : 0.03
            textMix = scheme == .dark ? 0.14 : 0.08

        default:
            accentMix = 0
            textMix = scheme == .dark ? 0.10 : 0.06
        }

        let themeBias: CGFloat
        switch theme {
        case .docC:
            themeBias = 0.14

        case .github:
            themeBias = 0.04

        case .solarized, .gruvbox, .dracula, .monokai, .nord, .onedark, .tokyonight, .catppuccin, .rosepine:
            themeBias = 0.08

        default:
            themeBias = 0.05
        }

        let accented = base.blended(withFraction: accentMix, of: accent) ?? base
        let themed = accented.blended(withFraction: themeBias, of: link) ?? accented
        return themed.blended(withFraction: textMix, of: textPrimary) ?? themed
    }

    fileprivate static func derivedTableHeaderBackground(
        base: NSColor,
        codeBackground: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let blendFraction: CGFloat = scheme == .dark ? 0.14 : 0.18
        let surface = base.blended(withFraction: blendFraction, of: codeBackground) ?? base
        let alphaMultiplier: CGFloat = scheme == .dark ? 0.76 : 0.86
        return surface.withAlphaComponent(surface.alphaComponent * alphaMultiplier)
    }

    fileprivate static func derivedTableHeaderText(
        base: NSColor,
        textPrimary: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let textBlend: CGFloat = scheme == .dark ? 0.52 : 0.34
        return base.blended(withFraction: textBlend, of: textPrimary) ?? base
    }

    fileprivate static func derivedTableRowBackground(
        base: NSColor,
        body: NSColor,
        inlineCodeBackground: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let stripeBlend: CGFloat = scheme == .dark ? 0.60 : 0.24
        let inlineBlend: CGFloat = scheme == .dark ? 0.08 : 0.04
        let striped = body.blended(withFraction: stripeBlend, of: base) ?? body
        let surface = striped.blended(withFraction: inlineBlend, of: inlineCodeBackground) ?? striped
        let alphaMultiplier: CGFloat = scheme == .dark ? 0.78 : 0.84
        return surface.withAlphaComponent(surface.alphaComponent * alphaMultiplier)
    }

    fileprivate static func derivedTableBodyBackground(
        header: NSColor,
        codeBackground: NSColor,
        rowAlternating: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let headerBlend: CGFloat = scheme == .dark ? 0.40 : 0.12
        let stripeBlend: CGFloat = scheme == .dark ? 0.24 : 0.05
        let surfaced = codeBackground.blended(withFraction: headerBlend, of: header) ?? codeBackground
        let surface = surfaced.blended(withFraction: stripeBlend, of: rowAlternating) ?? surfaced
        let alphaMultiplier: CGFloat = scheme == .dark ? 0.68 : 0.78
        return surface.withAlphaComponent(surface.alphaComponent * alphaMultiplier)
    }

    fileprivate static func derivedTableBorder(
        base: NSColor,
        accent: NSColor,
        theme: AppTheme,
        scheme: ColorScheme
    ) -> NSColor {
        let accentForwardThemes: Set<AppTheme> = [
            .dracula, .monokai, .onedark, .tokyonight, .nord, .gruvbox, .solarized,
            .catppuccin, .rosepine,
        ]
        var accentBlend: CGFloat = accentForwardThemes.contains(theme) ? 0.18 : 0.08
        if scheme == .dark {
            accentBlend += 0.05
        }
        return base.blended(withFraction: accentBlend, of: accent) ?? base
    }

    fileprivate static func derivedLinkUnderline(
        link: NSColor,
        textPrimary: NSColor,
        scheme: ColorScheme
    ) -> NSColor {
        let underlineBlend: CGFloat = scheme == .dark ? 0.22 : 0.12
        return link.blended(withFraction: underlineBlend, of: textPrimary) ?? link
    }

    /// Returns a hierarchy-aware heading color derived from theme tokens.
    func formattedHeadingColor(level: Int) -> NSColor {
        switch level {
        case 1: return formattedHeading1
        case 2: return formattedHeading2
        case 3: return formattedHeading3
        default: return formattedHeading
        }
    }

    func formattedTableHeaderBackground() -> NSColor {
        formattedTableHeaderSurface
    }

    func formattedTableHeaderTextColor() -> NSColor {
        formattedTableHeaderText
    }

    func formattedTableRowBackground() -> NSColor {
        formattedTableRowSurface
    }

    func formattedTableBodyBackground() -> NSColor {
        formattedTableBodySurface
    }

    func formattedTableBorder() -> NSColor {
        formattedTableBorderStroke
    }

    func formattedLinkUnderlineColor() -> NSColor {
        formattedLinkUnderline
    }

    /// Opacity multiplier applied to the border color when drawing interior column
    /// dividers. Tuned per theme so minimal/light themes stay subtle and vivid dark
    /// themes retain enough contrast to be legible.
    func tableColumnDividerOpacityMultiplier() -> CGFloat {
        // Base multiplier by theme character
        let base: CGFloat
        switch theme {
        case .basic, .github, .docC:
            // Minimal / system-integrated — column guides should barely register
            base = 0.35

        case .solarized, .gruvbox:
            // Warm-toned retro palettes — moderate presence
            base = 0.40

        case .dracula, .monokai, .onedark, .tokyonight, .nord, .catppuccin, .rosepine:
            // Vivid dark-first themes — borders carry more visual weight
            base = 0.55
        }

        // Dark mode adds a small lift so dividers remain visible against dark surfaces
        let darkBoost: CGFloat = scheme == .dark ? 0.08 : 0.0
        return min(1.0, base + darkBoost)
    }
}
