/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module render.tileset;

import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import core.all;
import render.window;
import render.texture;
import render.sprite;
import render.drawable;

struct Tileset {
	private {
		Texture _texture;
		Vec2i _grid, _tileSize;
		int _nbTiles;
	}

	@property {
		Texture texture() const { return cast(Texture)_texture; }
		bool isLoaded() const { return _texture.isLoaded; }
		Color color(const Color newColor) { _texture.setColorMod(newColor); return newColor; };
		Vec2f tileSize() const { return cast(Vec2f)_tileSize; }
	}

	Vec2f scale = Vec2f.one;
	float angle = 0f;
	Flip flip = Flip.NoFlip;
	Vec2f anchor = Vec2f.half;

	this(Texture newTexture, Vec2i grid, Vec2i tileSize) {
		_texture = newTexture;
		_grid = grid;
		_tileSize = tileSize;
		_nbTiles = _grid.x * _grid.y;
	}

	Sprite[] asSprites() {
		Sprite[] sprites;
		foreach(id; 0.. _nbTiles) {
			Vec2i coord = Vec2i(id % _grid.x, id / _grid.x);
			Vec4i clip = Vec4i(coord.x * _tileSize.x, coord.y * _tileSize.y, _tileSize.x, _tileSize.y);
			sprites ~= Sprite(_texture, clip);
		}
		return sprites;
	}

	void drawRotated(Timer timer, const Vec2f position) const {
		float id = floor(lerp(0f, to!float(_nbTiles), timer.time));
		drawRotated(to!uint(id), position);
	}

	void drawRotated(uint id, const Vec2f position) const {
		if(id >= _nbTiles)
			return;

		Vec2i coord = Vec2i(id % _grid.x, id / _grid.x);
		if(coord.y > _grid.y)
			throw new Exception("Tileset id out of bounds");

		Vec2f finalSize = scale * cast(Vec2f)(_tileSize) * getViewScale();
		Vec2f dist = (anchor - Vec2f.half).rotated(angle) * cast(Vec2f)(_tileSize) * scale;

		Vec4i clip = Vec4i(coord.x * _tileSize.x, coord.y * _tileSize.y, _tileSize.x, _tileSize.y);
		if (isVisible(position, finalSize)) {
			_texture.draw(getViewRenderPos(position - dist), finalSize, clip, angle, flip);
		}
	}

	void draw(Timer timer, const Vec2f position) const {
		float id = floor(lerp(0f, to!float(_nbTiles), timer.time));
		draw(to!uint(id), position);
	}

	void draw(uint id, const Vec2f position) const {
		if(id >= _nbTiles)
			return;

		Vec2f finalSize = scale * to!Vec2f(_tileSize) * getViewScale();
		Vec2i coord = Vec2i(id % _grid.x, id / _grid.x);
		if(coord.y > _grid.y)
			throw new Exception("Tileset id out of bounds");
		Vec4i clip = Vec4i(coord.x * _tileSize.x, coord.y * _tileSize.y, _tileSize.x, _tileSize.y);
		if (isVisible(position, finalSize)) {
			_texture.draw(getViewRenderPos(position), finalSize, clip, angle, flip, anchor);
		}
	}
}