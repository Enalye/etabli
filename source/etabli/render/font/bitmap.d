/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.font.bitmap;

import bindbc.sdl;

import etabli.common;
import etabli.render.imagedata;
import etabli.render.font.font;
import etabli.render.font.glyph;

/// Police de caractères formé depuis une texture
final class BitmapFont : Font, Resource!BitmapFont {
    private {
        ImageData _imageData;

        /// Taille de la police;
        int _size;

        /// Hauteur depuis la ligne (positif)
        int _ascent;

        /// Descente sous la ligne (négatif)
        int _descent;

        Metrics[dchar] _metrics;
        Glyph[dchar] _cache;
    }

    private final class Metrics {
        /// Distance horizontale depuis l’origine du caractère jusqu’au suivant
        int advance;

        /// Distance depuis l’origine du caractère à dessiner
        int offsetX, offsetY;

        /// Taille totale du caractère
        int width, height;

        /// Coordonnées dans la texture
        int posX, posY;

        /// Kerning
        int[dchar] kerning;
    }

    @property {
        /// Taille de la police
        int size() const {
            return _size;
        }
        /// Hauteur au dessus de la ligne
        int ascent() const {
            return _ascent;
        }
        /// Descente au dessous de la ligne
        int descent() const {
            return _descent;
        }
        /// Distance verticale entre chaque lignes
        int lineSkip() const {
            return (_ascent - _descent) + 1;
        }
        /// Taille de la bordure
        int outline() const {
            return 0;
        }
    }

    /// Init
    this(ImageData imageData, int size_, int ascent_, int descent_) {
        _imageData = imageData;
        _size = size_;
        _ascent = ascent_;
        _descent = descent_;
    }

    BitmapFont fetch() {
        return this;
    }

    void addCharacter(dchar ch, int advance, int offsetX, int offsetY, int width,
        int height, int posX, int posY, dchar[] kerningChar, int[] kerningOffset) {
        Metrics metrics = new Metrics;
        metrics.advance = advance;
        metrics.offsetX = offsetX;
        metrics.offsetY = offsetY;
        metrics.width = width;
        metrics.height = height;
        metrics.posX = posX;
        metrics.posY = posY;

        int count = cast(int) kerningChar.length;
        if (count > kerningOffset.length)
            count = cast(int) kerningOffset.length;

        for (int i; i < count; i++) {
            metrics.kerning[kerningChar[i]] = kerningOffset[i];
        }
        _metrics[ch] = metrics;
    }

    int getKerning(dchar prevChar, dchar currChar) {
        Metrics* metrics = currChar in _metrics;

        if (!metrics)
            return 0;

        int* kerning = prevChar in metrics.kerning;
        return kerning ? *kerning : 0;
    }

    private Glyph _cacheGlyph(dchar ch) {
        Metrics* metrics = ch in _metrics;
        Glyph glyph;

        if (metrics) {
            glyph = new BasicGlyph(true, metrics.advance, metrics.offsetX, metrics.offsetY,
                metrics.width, metrics.height, metrics.posX, metrics.posY,
                metrics.width, metrics.height, _imageData);
        }
        else {
            glyph = new BasicGlyph();
        }
        _cache[ch] = glyph;
        return glyph;
    }

    Glyph getGlyph(dchar ch) {
        Glyph* glyph = ch in _cache;
        if (glyph)
            return *glyph;
        return _cacheGlyph(ch);
    }
}
