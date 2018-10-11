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

struct Tileset {
	private {
		Texture _texture;
		Vec2i _grid, _tileSize, _offset;
		int _nbTiles;
	}

	@property {
		Texture texture() const { return cast(Texture)_texture; }
		bool isLoaded() const { return _texture.isLoaded; }
		Vec2f tileSize() const { return cast(Vec2f)_tileSize; }
		Vec2i grid() const { return _grid; }
		Vec2i offset() const { return _offset; }
	}

	Vec2f scale = Vec2f.one;
	float angle = 0f;
	Flip flip = Flip.NoFlip;
	Vec2f anchor = Vec2f.half;
    Color color = Color.white;
    Blend blend = Blend.AlphaBlending;

	this(Texture newTexture, Vec2i newOffset, Vec2i newGrid, Vec2i newTileSize, int newNbTiles = -1) {
		_texture = newTexture;
		_offset = newOffset;
		_grid = newGrid;
		_tileSize = newTileSize;
        if(newNbTiles != -1)
            _nbTiles = newNbTiles;
        else
		    _nbTiles = _grid.x * _grid.y;
	}

	Sprite[] asSprites() {
		Sprite[] sprites;
		foreach(id; 0.. _nbTiles) {
			Vec2i coord = Vec2i(id % _grid.x, id / _grid.x);
			Vec4i clip = Vec4i(_offset.x + coord.x * _tileSize.x, _offset.y + coord.y * _tileSize.y, _tileSize.x, _tileSize.y);
			sprites ~= Sprite(_texture, clip);
		}
		return sprites;
	}

	void drawRotated(Timer timer, const Vec2f position) {
		float id = floor(lerp(0f, to!float(_nbTiles), timer.time));
		drawRotated(to!uint(id), position);
	}

	void drawRotated(uint id, const Vec2f position) {
		if(id >= _nbTiles)
			return;

		Vec2i coord = Vec2i(id % _grid.x, id / _grid.x);
		if(coord.y > _grid.y)
			throw new Exception("Tileset id out of bounds");

		Vec2f finalSize = scale * cast(Vec2f)(_tileSize) * getViewScale();
		Vec2f dist = (anchor - Vec2f.half).rotated(angle) * cast(Vec2f)(_tileSize) * scale;

		Vec4i clip = Vec4i(_offset.x + coord.x * _tileSize.x, _offset.y + coord.y * _tileSize.y, _tileSize.x, _tileSize.y);
		//if (isVisible(position, finalSize)) {
            _texture.setColorMod(color, blend);
			_texture.draw(getViewRenderPos(position - dist), finalSize, clip, angle, flip);
            _texture.setColorMod(Color.white);
		//}
	}

	void draw(Timer timer, const Vec2f position) {
		float id = floor(lerp(0f, to!float(_nbTiles), timer.time));
		draw(to!uint(id), position);
	}

	void draw(uint id, const Vec2f position) {
		if(id >= _nbTiles)
			return;

		Vec2f finalSize = scale * to!Vec2f(_tileSize) * getViewScale();
		Vec2i coord = Vec2i(id % _grid.x, id / _grid.x);
		if(coord.y > _grid.y)
			throw new Exception("Tileset id out of bounds");
		Vec4i clip = Vec4i(_offset.x + coord.x * _tileSize.x, _offset.y + coord.y * _tileSize.y, _tileSize.x, _tileSize.y);
		//if (isVisible(position, finalSize)) {
            _texture.setColorMod(color, blend);
			_texture.draw(getViewRenderPos(position), finalSize, clip, angle, flip, anchor);
            _texture.setColorMod(Color.white);
		//}
	}
}