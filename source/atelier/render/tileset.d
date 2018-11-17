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
	int columns = 1, lines = 1;
    Texture texture;

	Vec2f size = Vec2f.zero, scale = Vec2f.one;
	float angle = 0f;
	Flip flip = Flip.NoFlip;
	Vec2f anchor = Vec2f.half;
    Color color = Color.white;
    Blend blend = Blend.AlphaBlending;

    this() {}

	this(Texture newTexture, Vec4i newClip, int newColumns, int newLines, int newMaxTiles = -1) {
		texture = newTexture;
		clip = newClip;
		columns = newColumns;
		lines = newLines;
        size = to!Vec2f(clip.zw);
        maxtiles(newMaxTiles);
	}

	Sprite[] asSprites() {
		Sprite[] sprites;
		foreach(id; 0.. _maxtiles) {
			Vec2i coord = Vec2i(id % columns, id / columns);
			Vec4i spriteClip = Vec4i(clip.x + coord.x * clip.z, clip.y + coord.y * clip.w, clip.z, clip.w);
			sprites ~= new Sprite(texture, spriteClip);
		}
		return sprites;
	}

	void drawRotated(Timer timer, const Vec2f position) {
		float id = floor(lerp(0f, to!float(_maxtiles), timer.time));
		drawRotated(to!uint(id), position);
	}

	void drawRotated(uint id, const Vec2f position) {
		if(id >= _maxtiles)
			return;

		Vec2i coord = Vec2i(id % columns, id / columns);
		if(coord.y > lines)
			throw new Exception("Tileset id out of bounds");

		Vec2f finalSize = scale * size * transformScale();
		Vec2f dist = (anchor - Vec2f.half).rotated(angle) * size * scale;

		Vec4i currentClip = Vec4i(clip.x + coord.x * clip.z, clip.y + coord.y * clip.w, clip.z, clip.w);
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position - dist), finalSize, currentClip, angle, flip);
        texture.setColorMod(Color.white);
	}

	void draw(Timer timer, const Vec2f position) {
		float id = floor(lerp(0f, to!float(_maxtiles), timer.time));
		draw(to!uint(id), position);
	}

	void draw(uint id, const Vec2f position) {
		if(id >= _maxtiles)
			return;

		Vec2f finalSize = scale * size * transformScale();
		Vec2i coord = Vec2i(id % columns, id / columns);
		if(coord.y > lines)
			throw new Exception("Tileset id out of bounds");
		Vec4i currentClip = Vec4i(clip.x + coord.x * clip.z, clip.y + coord.y * clip.w, clip.z, clip.w);
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position), finalSize, currentClip, angle, flip, anchor);
        texture.setColorMod(Color.white);
	}
}