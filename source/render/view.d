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

module render.view;

import std.conv: to;

import derelict.sdl2.sdl;

import core.all;
import render.window;
import render.texture;

class View {
	private {
		SDL_Texture* _target;
		Vec2u _renderSize;
	}

	@property {
		const(SDL_Texture*) target() const { return _target; }

		Vec2u renderSize() const { return _renderSize; }
		Vec2u renderSize(Vec2u newRenderSize) {
			if(newRenderSize.x >= 2048u || newRenderSize.y >= 2048u)
				throw new Exception("View render size exceeds limits.");
			_renderSize = newRenderSize;
			if(_target !is null)
				SDL_DestroyTexture(_target);
			_target = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
			return _renderSize;
		}
	}

	Vec2f position = Vec2f.zero, size = Vec2f.zero;
	bool isCentered = true;
	Color clearColor = Color.clear;

	this(Vec2f newRenderSize) {
		this(to!Vec2u(newRenderSize));
	}

	this(Vec2u newRenderSize) {
		if(newRenderSize.x >= 2048u || newRenderSize.y >= 2048u)
			throw new Exception("View render size exceeds limits.");
		_renderSize = newRenderSize;
		_target = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);

		size = cast(Vec2f)_renderSize;
		position = size * 0.5f;
		isCentered = true;
	}

	this(const View view) {
		_renderSize = view._renderSize;
		size = view.size;
		position = view.position;
		isCentered = view.isCentered;
		_target = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
	}

	~this() {
		if(_target !is null)
			SDL_DestroyTexture(_target);
	}

	View copy(const View v) {
		_renderSize = v._renderSize;
		size = v.size;
		position = v.position;
		isCentered = v.isCentered;

		if(_target !is null)
			SDL_DestroyTexture(_target);
		_target = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
		return this;
	}

	void setColorMod(const Color color, Blend blend = Blend.AlphaBlending) {
		SDL_SetTextureBlendMode(_target,
			((blend == Blend.AlphaBlending) ? SDL_BLENDMODE_BLEND :
				((blend == Blend.AdditiveBlending) ? SDL_BLENDMODE_ADD :
					((blend == Blend.ModularBlending) ? SDL_BLENDMODE_MOD :
						SDL_BLENDMODE_NONE))));
		
		auto sdlColor = color.toSDL();
		SDL_SetTextureColorMod(_target, sdlColor.r, sdlColor.g, sdlColor.b);
		SDL_SetTextureAlphaMod(_target, sdlColor.a);
	}

	void draw(const Vec2f renderPosition) const {
		Vec2f pos = getViewRenderPos(renderPosition);
		Vec2f scale = getViewScale();

		SDL_Rect destRect = {
			cast(uint)(pos.x - (_renderSize.x / 2) * scale.x),
			cast(uint)(pos.y - (_renderSize.y / 2) * scale.y),
			cast(uint)(_renderSize.x * scale.x),
			cast(uint)(_renderSize.y * scale.y)
		};

		SDL_RenderCopy(renderer, cast(SDL_Texture*)_target, null, &destRect);
	}

	void draw(const Vec2f renderPosition, const Vec2f scale) const {
		Vec2f pos = getViewRenderPos(renderPosition);
		Vec2f rscale = getViewScale() * scale;

		SDL_Rect destRect = {
			cast(uint)(pos.x - (_renderSize.x / 2) * rscale.x),
			cast(uint)(pos.y - (_renderSize.y / 2) * rscale.y),
			cast(uint)(_renderSize.x * rscale.x),
			cast(uint)(_renderSize.y * rscale.y)
		};

		SDL_RenderCopy(renderer, cast(SDL_Texture*)_target, null, &destRect);
	}

	bool isInside(const Vec2f pos, const Vec2f renderPosition) const {
		return (isCentered) ?
			pos.isBetween(renderPosition - cast(Vec2f)(_renderSize) * 0.5f, renderPosition + cast(Vec2f)(_renderSize) * 0.5f):
			pos.isBetween(renderPosition, renderPosition + cast(Vec2f)(_renderSize));
	}
}