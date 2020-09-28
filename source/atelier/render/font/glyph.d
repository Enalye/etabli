/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.font.glyph;

import atelier.core;
import atelier.render.texture, atelier.render.window;

/// Information about a single character
struct Glyph {
	@property {
		/// Is the character defined ?
		bool exists() const { return _exists; }
		/// Width to advance cursor from previous position.
		int advance() const { return _advance; }
		/// Offset
		int offsetX() const { return _offsetX; }
		/// Ditto
		int offsetY() const { return _offsetY; }
		/// Character size
		int width() const { return _width; }
		/// Ditto
		int height() const { return _height; }
	}

	private {
		bool _exists;
		/// Width to advance cursor from previous position.
		int _advance;
		/// Offset
		int _offsetX, _offsetY;
		/// Character size
		int _width, _height;
		/// Coordinates in texture
		int _packX, _packY, _packWidth, _packHeight;
		/// Texture
		Texture _texture;
	}

	/// Render glyph
	void draw(Vec2f position, int scale, Color color, float alpha) {
		const Vec2f finalSize = Vec2f(_width, _height) * scale * transformScale();
		_texture.setColorMod(color, Blend.alpha);
		_texture.setAlpha(alpha);
		_texture.draw(
			transformRenderSpace(position),
			finalSize,
			Vec4i(_packX, _packY, _packWidth, _packHeight),
			Vec2f.zero);
		_texture.setColorMod(Color.white, Blend.alpha);
		_texture.setAlpha(1f);
	}
}