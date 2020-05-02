/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.font.truetype;

import std.conv: to;
import std.string: toStringz, fromStringz;
import bindbc.sdl, bindbc.sdl.ttf;
import atelier.core;
import atelier.render.texture;
import atelier.render.font.font, atelier.render.font.glyph;

/// Font that load a TTF file.
final class TrueTypeFont: Font {
	private {
		TTF_Font* _trueTypeFont;
		bool _ownData;
		string _name;
		int _size, _outline;
		Glyph[dchar] _cache;
	}

	@property {
		/// Font name
        string name() const { return _name; }
        /// Default font size
        int size() const { return TTF_FontHeight(_trueTypeFont); }
        /// Where the top is above the baseline
        int ascent() const { return TTF_FontAscent(_trueTypeFont); }
        /// Where the bottom is below the baseline
        int descent() const { return TTF_FontDescent(_trueTypeFont); }
		/// Distance between each baselines
        int lineSkip() const { return TTF_FontLineSkip(_trueTypeFont); }
	}

	/// Copy ctor
    this(TrueTypeFont font) {
        _trueTypeFont = font._trueTypeFont;
		_name = font._name;
		_size = font._size;
		_outline = font._outline;
        _ownData = false;
	}

	/// Ctor
	this(const string path, int size_ = 16u, int outline_ = 0) {
		load(path, size_, outline_);
	}

	~this() {
		unload();
	}

	/// Load
	private void load(string path, int size_, int outline_) {
		assert(size_ != 0u, "Cannot render a font with no size");
		if(null != _trueTypeFont)
			TTF_CloseFont(_trueTypeFont);

		_size = size_;
		_outline = outline_;
		_trueTypeFont = TTF_OpenFont(toStringz(path), size_);
		assert(_trueTypeFont, "Cannot load \'" ~ path ~ "\' font.");

		TTF_SetFontKerning(_trueTypeFont, 0);

		_name = to!string(fromStringz(TTF_FontFaceFamilyName(_trueTypeFont)));
        _ownData = true;
	}

	/// Unload
	private void unload() {
        if(!_ownData)
            return;
		if (null != _trueTypeFont)
			TTF_CloseFont(_trueTypeFont);
	}

	private Glyph cache(dchar ch) {
		int xmin, xmax, ymin, ymax, advance;
		if(_outline == 0) {
			if(-1 == TTF_GlyphMetrics(_trueTypeFont, cast(wchar) ch, &xmin, &xmax, &ymin, &ymax, &advance))
				return Glyph();

			SDL_Surface* surface = TTF_RenderGlyph_Blended(_trueTypeFont, cast(wchar) ch, Color.white.toSDL());
			assert(surface);
			Texture texture = new Texture(surface);
			assert(texture);
			SDL_FreeSurface(surface);
			Glyph metrics = Glyph(
				true,
				advance,
				0, 0,
				texture.width, texture.height,
				0, 0,
				texture.width, texture.height,
				texture);
			_cache[ch] = metrics;
			return metrics;
		}
		else {
			if(-1 == TTF_GlyphMetrics(_trueTypeFont, cast(wchar) ch, &xmin, &xmax, &ymin, &ymax, &advance))
				return Glyph();

			TTF_SetFontOutline(_trueTypeFont, _outline);
			SDL_Surface* surfaceOutline = TTF_RenderGlyph_Blended(_trueTypeFont, cast(wchar) ch, Color.black.toSDL());
			assert(surfaceOutline);
			
			TTF_SetFontOutline(_trueTypeFont, 0);

			SDL_Surface* surface = TTF_RenderGlyph_Blended(_trueTypeFont, cast(wchar) ch, Color.white.toSDL());
			assert(surface);

			SDL_Rect srcRect = {
				0, 0, surface.w, surface.h
			};

			SDL_Rect dstRect = {
				(surfaceOutline.w - surface.w) / 2,
				(surfaceOutline.h - surface.h) / 2,
				surface.w, surface.h
			};

			SDL_BlitSurface(surface, &srcRect, surfaceOutline, &dstRect);

			Texture texture = new Texture(surfaceOutline);
			assert(texture);
			SDL_FreeSurface(surface);
			SDL_FreeSurface(surfaceOutline);
			Glyph metrics = Glyph(
				true,
				advance,
				0, 0,
				texture.width, texture.height,
				0, 0,
				texture.width, texture.height,
				texture);
			_cache[ch] = metrics;
			return metrics;
		}
	}

    int getKerning(dchar prevChar, dchar currChar) {
        return 0;
    }

    Glyph getMetrics(dchar ch) {
		Glyph* metrics = ch in _cache;
		if(metrics)
			return *metrics;
		return cache(ch);
    }
}