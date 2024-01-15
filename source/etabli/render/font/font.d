/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.font.font;

import etabli.common;

import etabli.render.texture;

import etabli.render.font.glyph, etabli.render.font.truetype, etabli.render.font.vera;

private {
    Font _defaultFont, _veraFont;
}

/// Initialize the default font
void initFont() {
    _veraFont = new TrueTypeFont(veraFontData, 16);
    _defaultFont = _veraFont;
}

void setDefaultFont(Font font) {
    if (!font) {
        _defaultFont = _veraFont;
        return;
    }
    _defaultFont = font;
}

Font getDefaultFont() {
    return _defaultFont;
}

/// Font that renders text to texture.
interface Font {
    @property {
        /// Font name
        string name() const;
        /// Default font size
        int size() const;
        /// Where the top is above the baseline
        int ascent() const;
        /// Where the bottom is below the baseline
        int descent() const;
        /// Distance between each baselines
        int lineSkip() const;
    }

    int getKerning(dchar prevChar, dchar currChar);

    Glyph getMetrics(dchar character);
}
