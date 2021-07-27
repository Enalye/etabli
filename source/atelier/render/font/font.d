/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.font.font;

import atelier.core;
import atelier.render.texture;
import atelier.render.font.glyph, atelier.render.font.truetype, atelier.render.font.vera;

private {
    Font _defaultFont, _veraFont;
}

/// Initialize the default font
void initFont() {
    _veraFont = new TrueTypeFont(veraFontData);
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
