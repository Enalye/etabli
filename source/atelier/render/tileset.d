/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.tileset;

import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import atelier.core;
import atelier.render.window;
import atelier.render.texture;
import atelier.render.sprite;
import atelier.render.drawable;

/// Series of aligned tiles.
final class Tileset {
	@property {
        /// loaded ?
		bool isLoaded() const { return texture.isLoaded; }
        /// Number of tiles
        int maxtiles() const { return _maxtiles; }
        /// Ditto
        int maxtiles(int newMaxTiles) {
            _maxtiles = newMaxTiles;
            if(_maxtiles <= 0 || _maxtiles > columns * lines)
                _maxtiles = columns * lines;
            return _maxtiles;
        }
	}

    /// The maximum number of tile, cannot be more than columns * lines, cannot be less than 0.
    private int _maxtiles;

	/// Texture region of the first tile (the source size).
	Vec4i clip;

    /// Spacing between each tiles.
    Vec2i margin;

    /// Number of tiles on the horizontal axis.
	int columns = 1,
    /// Number of tiles on the vertical axis.
        lines = 1;

    /// Source material.
    Texture texture;

    /// Destination size.
	Vec2f size = Vec2f.zero, scale = Vec2f.one;

	/// Angle in which the sprite will be rendered.
	float angle = 0f;

	/// Mirroring property.
	Flip flip = Flip.none;

    /// Anchor.
	Vec2f anchor = Vec2f.half;

	/// Color added to the tile.
    Color color = Color.white;

	/// Blending algorithm.
    Blend blend = Blend.alpha;

    /// Ctor
    this() {}

    /// Copy ctor
    this(Tileset tileset) {
        _maxtiles = tileset._maxtiles;
        clip = tileset.clip;
        columns = tileset.columns;
        lines = tileset.lines;
        texture = tileset.texture;
        size = tileset.size;
        scale = tileset.scale;
        angle = tileset.angle;
        flip = tileset.flip;
        anchor = tileset.anchor;
        color = tileset.color;
        blend = tileset.blend;
    }

    /// Ctor
	this(Texture newTexture, Vec4i newClip, int newColumns, int newLines, int newMaxTiles = -1) {
		texture = newTexture;
		clip = newClip;
		columns = newColumns;
		lines = newLines;
        size = to!Vec2f(clip.zw);
        maxtiles(newMaxTiles);
	}

    /// Create a new Sprite from the tile id.
    Sprite getSprite(int id) {
        if(id >= _maxtiles)
			id = _maxtiles - 1;
        if(id < 0)
            id = 0;
        Vec2i coord = Vec2i(id % columns, id / columns);
        Vec4i spriteClip = Vec4i(clip.x + coord.x * clip.z, clip.y + coord.y * clip.w, clip.z, clip.w);
        Sprite sprite = new Sprite(texture, spriteClip);
        sprite.flip = flip;
        sprite.blend = blend;
        sprite.color = color;
        sprite.anchor = anchor;
        sprite.angle = angle;
        sprite.size = size;
        return sprite;
    }

    /// Return each tile as a Sprite.
	Sprite[] asSprites() {
		Sprite[] sprites;
		foreach(id; 0.. _maxtiles)
			sprites ~= getSprite(id);
		return sprites;
	}

    /// Set the sprite's size to fit inside the specified size.
	void fit(Vec2f size_) {
		size = to!Vec2f(clip.zw).fit(size_);
	}

    /// Render a tile
	void drawRotated(int id, const Vec2f position) {
		if(id >= _maxtiles)
			id = _maxtiles - 1;
        if(id < 0)
            id = 0;

		Vec2i coord = Vec2i(id % columns, id / columns);
		if(coord.y > lines)
			throw new Exception("Tileset id out of bounds");

		Vec2f finalSize = scale * size * transformScale();
		Vec2f dist = (anchor - Vec2f.half).rotated(angle) * size * scale;

		Vec4i currentClip = Vec4i(
            clip.x + coord.x * (clip.z + margin.x),
            clip.y + coord.y * (clip.w + margin.y),
            clip.z, clip.w);
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position - dist), finalSize, currentClip, angle, flip);
        texture.setColorMod(Color.white);
	}

    /// Ditto
	void draw(int id, const Vec2f position) {
		if(id >= _maxtiles)
			id = _maxtiles - 1;
        if(id < 0)
            id = 0;

		Vec2f finalSize = scale * size * transformScale();
		Vec2i coord = Vec2i(id % columns, id / columns);
		if(coord.y > lines)
			throw new Exception("Tileset id out of bounds");
		Vec4i currentClip = Vec4i(
            clip.x + coord.x * (clip.z + margin.x),
            clip.y + coord.y * (clip.w + margin.y),
            clip.z, clip.w);
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position), finalSize, currentClip, angle, flip, anchor);
        texture.setColorMod(Color.white);
	}
}