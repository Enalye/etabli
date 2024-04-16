/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.font.pixelfont;

import std.conv : to;
import etabli.common;
import etabli.render.font.font;
import etabli.render.font.glyph;
import etabli.render.imagedata;
import etabli.render.util;
import etabli.render.writabletexture;

abstract class PixelFont : Font {
    void addCharacter(dchar ch, int[] glyphData, int width, int height, int descent);
}
