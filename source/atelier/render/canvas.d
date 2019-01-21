/**
    View

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.canvas;

import std.conv: to;

import derelict.sdl2.sdl;

import atelier.core;
import atelier.render.window;
import atelier.render.texture;

class Canvas {
	private {
		SDL_Texture* _renderTexture;
		Vec2u _renderSize;
	}

    bool isTarget;

	@property {
		package(atelier) const(SDL_Texture*) target() const { return _renderTexture; }

		Vec2u renderSize() const { return _renderSize; }
		Vec2u renderSize(Vec2u newRenderSize) {
            if(isTarget)
                throw new Exception("Attempt to resize canvas while being rendered.");
			if(newRenderSize.x >= 2048u || newRenderSize.y >= 2048u)
				throw new Exception("Canvas render size exceeds limits.");
			_renderSize = newRenderSize;
			if(_renderTexture !is null)
				SDL_DestroyTexture(_renderTexture);
			_renderTexture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
			return _renderSize;
		}
	}

	Vec2f position = Vec2f.zero, size = Vec2f.zero;
	bool isCentered = true;
	Color clearColor = Color.clear;

	this(Vec2f newRenderSize) {
		this(to!Vec2u(newRenderSize));
	}

    this(Vec2i newRenderSize) {
		this(to!Vec2u(newRenderSize));
	}

	this(Vec2u newRenderSize) {
		if(newRenderSize.x >= 2048u || newRenderSize.y >= 2048u)
			throw new Exception("Canvas render size exceeds limits.");
		_renderSize = newRenderSize;
		_renderTexture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
        setColorMod(Color.white, Blend.AlphaBlending);

		size = cast(Vec2f)_renderSize;
		isCentered = false;
	}

	this(const Canvas canvas) {
		_renderSize = canvas._renderSize;
		size = canvas.size;
		position = canvas.position;
        isCentered = canvas.isCentered;
		_renderTexture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
	}

	~this() {
		if(_renderTexture !is null)
			SDL_DestroyTexture(_renderTexture);
	}

	Canvas copy(const Canvas v) {
		_renderSize = v._renderSize;
		size = v.size;
		position = v.position;
        isCentered = v.isCentered;

		if(_renderTexture !is null)
			SDL_DestroyTexture(_renderTexture);
		_renderTexture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, _renderSize.x, _renderSize.y);
		return this;
	}

	void setColorMod(const Color color, Blend blend = Blend.AlphaBlending) {
		SDL_SetTextureBlendMode(_renderTexture,
			((blend == Blend.AlphaBlending) ? SDL_BLENDMODE_BLEND :
				((blend == Blend.AdditiveBlending) ? SDL_BLENDMODE_ADD :
					((blend == Blend.ModularBlending) ? SDL_BLENDMODE_MOD :
						SDL_BLENDMODE_NONE))));
		
		auto sdlColor = color.toSDL();
		SDL_SetTextureColorMod(_renderTexture, sdlColor.r, sdlColor.g, sdlColor.b);
		SDL_SetTextureAlphaMod(_renderTexture, sdlColor.a);
	}

    void setAlpha(float alpha) {
		SDL_SetTextureAlphaMod(_renderTexture, cast(ubyte)(clamp(alpha, 0f, 1f) * 255f));
	}

	void draw(const Vec2f renderPosition) const {
		Vec2f pos = transformRenderSpace(renderPosition);
		Vec2f scale = transformScale();

		SDL_Rect destRect = {
			cast(uint)(pos.x - (_renderSize.x / 2) * scale.x),
			cast(uint)(pos.y - (_renderSize.y / 2) * scale.y),
			cast(uint)(_renderSize.x * scale.x),
			cast(uint)(_renderSize.y * scale.y)
		};

		SDL_RenderCopy(renderer, cast(SDL_Texture*)_renderTexture, null, &destRect);
	}

	void draw(const Vec2f renderPosition, const Vec2f scale) const {
		Vec2f pos = transformRenderSpace(renderPosition);
		Vec2f rscale = transformScale() * scale;

		SDL_Rect destRect = {
			cast(uint)(pos.x - (_renderSize.x / 2) * rscale.x),
			cast(uint)(pos.y - (_renderSize.y / 2) * rscale.y),
			cast(uint)(_renderSize.x * rscale.x),
			cast(uint)(_renderSize.y * rscale.y)
		};

		SDL_RenderCopy(renderer, cast(SDL_Texture*)_renderTexture, null, &destRect);
	}

	bool isInside(const Vec2f pos, const Vec2f renderPosition) const {
		return (isCentered) ?
			pos.isBetween(renderPosition - cast(Vec2f)(_renderSize) * 0.5f, renderPosition + cast(Vec2f)(_renderSize) * 0.5f):
			pos.isBetween(renderPosition, renderPosition + cast(Vec2f)(_renderSize));
    }

    void draw(Vec2f pos, Vec2f rsize, Vec4i srcRect, float angle, Flip flip = Flip.NoFlip, Vec2f anchor = Vec2f.half) const {
		pos -= anchor * rsize;
		
		SDL_Rect srcSdlRect = srcRect.toSdlRect();
		SDL_Rect destSdlRect = {
			cast(uint)pos.x,
			cast(uint)pos.y,
			cast(uint)rsize.x,
			cast(uint)rsize.y
		};

		SDL_RendererFlip rendererFlip = (flip == Flip.BothFlip) ?
			cast(SDL_RendererFlip)(SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL) :
			(flip == Flip.HorizontalFlip ? SDL_FLIP_HORIZONTAL :
				(flip == Flip.VerticalFlip ? SDL_FLIP_VERTICAL :
					SDL_FLIP_NONE));

		SDL_RenderCopyEx(cast(SDL_Renderer*)renderer, cast(SDL_Texture*)_renderTexture, &srcSdlRect, &destSdlRect, angle, null, rendererFlip);
	}
}