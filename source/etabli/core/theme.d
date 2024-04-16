/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.core.theme;

import etabli.common;
import etabli.render;
import etabli.core.data.vera;

final class Theme {
    Font font;
    Color background;
    Color surface;
    Color container;
    Color foreground;
    Color neutral;
    Color accent;
    Color danger;
    Color onNeutral;
    Color onAccent;
    Color onDanger;
    float corner;
    float activeOpacity;
    float inactiveOpacity;

    this() {
        setDefault();
    }

    void setDefault() {
        font = TrueTypeFont.fromMemory(veraFontData, 12, 0);
        background = Color.fromHex(0x1e1e1e);
        surface = Color.fromHex(0x252526);
        container = Color.fromHex(0x2d2d30);
        foreground = Color.fromHex(0x3e3e42);
        neutral = Color.fromHex(0x57575c);
        accent = Color.fromHex(0x007acc);
        danger = Color.fromHex(0xcc0000);
        onNeutral = Color.fromHex(0xffffff);
        onAccent = Color.fromHex(0xffffff);
        onDanger = Color.fromHex(0xffffff);
        corner = 8f;
        activeOpacity = 1f;
        inactiveOpacity = 0.25f;
    }
}
