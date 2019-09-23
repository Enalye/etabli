/**
    Tileset

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
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

final class Tileset {
	@property {
		bool isLoaded() const { return texture.isLoaded; }
        int maxtiles() const { return _maxtiles; }
        int maxtiles(int newMaxTiles) {
            _maxtiles = newMaxTiles;
            if(_maxtiles <= 0 || _maxtiles > columns * lines)
                _maxtiles = columns * lines;
            return _maxtiles;
        }
	}

    private int _maxtiles;

	Vec4i clip;
    Vec2i margin;
	int columns = 1, lines = 1;
    Texture texture;

	Vec2f size = Vec2f.zero, scale = Vec2f.one;
	float angle = 0f;
	Flip flip = Flip.NoFlip;
	Vec2f anchor = Vec2f.half;
    Color color = Color.white;
    Blend blend = Blend.AlphaBlending;

    this() {}

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

	this(Texture newTexture, Vec4i newClip, int newColumns, int newLines, int newMaxTiles = -1) {
		texture = newTexture;
		clip = newClip;
		columns = newColumns;
		lines = newLines;
        size = to!Vec2f(clip.zw);
        maxtiles(newMaxTiles);
	}

    Sprite getSprite(Timer timer) {
		const float id = floor(lerp(0f, to!float(_maxtiles), timer.time));
        return getSprite(to!int(id));
    }

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

	Sprite[] asSprites() {
		Sprite[] sprites;
		foreach(id; 0.. _maxtiles)
			sprites ~= getSprite(id);
		return sprites;
	}

    void fit(Vec2f newSize) {
		size = to!Vec2f(clip.zw).fit(newSize);
	}

	void drawRotated(Timer timer, const Vec2f position) {
		float id = floor(lerp(0f, to!float(_maxtiles), timer.time));
		drawRotated(to!int(id), position);
	}

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

		Vec4i currentClip = Vec4i(clip.x + coord.x * (clip.z + margin.x), clip.y + coord.y * (clip.w + margin.y), clip.z, clip.w);
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position - dist), finalSize, currentClip, angle, flip);
        texture.setColorMod(Color.white);
	}

	void draw(Timer timer, const Vec2f position) {
		float id = floor(lerp(0f, to!float(_maxtiles), timer.time));
		draw(to!int(id), position);
	}

	void draw(int id, const Vec2f position) {
		if(id >= _maxtiles)
			id = _maxtiles - 1;
        if(id < 0)
            id = 0;

		Vec2f finalSize = scale * size * transformScale();
		Vec2i coord = Vec2i(id % columns, id / columns);
		if(coord.y > lines)
			throw new Exception("Tileset id out of bounds");
		Vec4i currentClip = Vec4i(clip.x + coord.x * (clip.z + margin.x), clip.y + coord.y * (clip.w + margin.y), clip.z, clip.w);
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position), finalSize, currentClip, angle, flip, anchor);
        texture.setColorMod(Color.white);
	}
}