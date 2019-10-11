/**
    Texture

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.texture;

import std.string;
import std.exception;
import std.algorithm.comparison: clamp;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import atelier.core;
import atelier.render.window;

/// Indicate if something is mirrored.
enum Flip {
	NoFlip,
	HorizontalFlip,
	VerticalFlip,
	BothFlip
}

/// Blending algorithm \
/// NoBlending: Paste everything without transparency \
/// ModularBlending: Multiply color value with the destination \
/// AdditiveBlending: Add color value with the destination \
/// AlphaBlending: Paste everything with transparency (Default one)
enum Blend {
	NoBlending,
	ModularBlending,
	AdditiveBlending,
	AlphaBlending
}

/// Base rendering class.
final class Texture {
	private {
		bool _isLoaded = false, _ownData;
		SDL_Texture* _texture = null;
		uint _width, _height;
	}

	@property {
		bool isLoaded() const { return _isLoaded; }
		uint width() const { return _width; }
		uint height() const { return _height; }
	}

	this() {}

	this(Texture texture) {
        _isLoaded = texture._isLoaded;
		_texture = texture._texture;
		_width = texture._width;
        _height = texture._height;
        _ownData = false;
    }

	this(SDL_Surface* surface) {
		loadFromSurface(surface);
	}

	this(string path) {
		load(path);
	}

	~this() {
		unload();
	}

	void setColorMod(Color color, Blend blend = Blend.AlphaBlending) {
		SDL_SetTextureBlendMode(_texture,
			((blend == Blend.AlphaBlending) ? SDL_BLENDMODE_BLEND :
				((blend == Blend.AdditiveBlending) ? SDL_BLENDMODE_ADD :
					((blend == Blend.ModularBlending) ? SDL_BLENDMODE_MOD :
						SDL_BLENDMODE_NONE))));
		
		auto sdlColor = color.toSDL();
		SDL_SetTextureColorMod(_texture, sdlColor.r, sdlColor.g, sdlColor.b);
		SDL_SetTextureAlphaMod(_texture, sdlColor.a);
	}

	void setAlpha(float alpha) {
		SDL_SetTextureAlphaMod(_texture, cast(ubyte)(clamp(alpha, 0f, 1f) * 255f));
	}

	void loadFromSurface(SDL_Surface* surface) {
		enforce(null != surface, "Invalid surface.");
		enforce(null != _sdlRenderer, "The _sdlRenderer does not exist.");

		if (null != _texture)
			SDL_DestroyTexture(_texture);

		_texture = SDL_CreateTextureFromSurface(_sdlRenderer, surface);

		enforce(null != _texture, "Error occurred while converting a surface to a texture format.");

		_width = surface.w;
		_height = surface.h;
		SDL_FreeSurface(surface);

		_isLoaded = true;
        _ownData = true;
	}

	void load(string path) {
		SDL_Surface* surface = IMG_Load(toStringz(path));
			
		enforce(null != surface, "Cannot load image file \'" ~ path ~ "\'.");
		enforce(null != _sdlRenderer, "The _sdlRenderer does not exist.");

		_texture = SDL_CreateTextureFromSurface(_sdlRenderer, surface);

		if (null == _texture)
			throw new Exception("Error occurred while converting \'" ~ path ~ "\' to a texture format.");

		_width = surface.w;
		_height = surface.h;
		SDL_FreeSurface(surface);

		_isLoaded = true;
        _ownData = true;
	}

	void unload() {
        if(!_ownData)
            return;
		if (null != _texture)
			SDL_DestroyTexture(_texture);
		_isLoaded = false;
	}

	void draw(Vec2f pos, Vec2f anchor = Vec2f.half) const {
		enforce(_isLoaded, "Cannot render the texture: Asset not loaded.");
		pos -= anchor * Vec2f(_width, _height);

		SDL_Rect destRect = {
			cast(uint)pos.x,
			cast(uint)pos.y,
			_width,
			_height
		};

		SDL_RenderCopy(cast(SDL_Renderer*)_sdlRenderer, cast(SDL_Texture*)_texture, null, &destRect);
	}

	void draw(Vec2f pos, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
		enforce(_isLoaded, "Cannot render the texture: Asset not loaded.");

		SDL_Rect srcSdlRect = srcRect.toSdlRect();
		SDL_Rect destSdlRect = {
			cast(uint)(pos.x) - (srcSdlRect.w >> 1U),
			cast(uint)(pos.y) - (srcSdlRect.h >> 1U),
			srcSdlRect.w,
			srcSdlRect.h
		};

		SDL_RenderCopy(cast(SDL_Renderer*)_sdlRenderer, cast(SDL_Texture*)_texture, &srcSdlRect, &destSdlRect);
	}

	void draw(Vec2f pos, Vec2f size, Vec2f anchor = Vec2f.half) const {
		enforce(_isLoaded, "Cannot render the texture: Asset not loaded.");
		pos -= anchor * size;

		SDL_Rect destSdlRect = {
			cast(uint)pos.x,
			cast(uint)pos.y,
			cast(uint)size.x,
			cast(uint)size.y
		};

		SDL_RenderCopy(cast(SDL_Renderer*)_sdlRenderer, cast(SDL_Texture*)_texture, null, &destSdlRect);
	}

	void draw(Vec2f pos, Vec2f size, Vec4i srcRect, Vec2f anchor = Vec2f.half) const {
		enforce(_isLoaded, "Cannot render the texture: Asset not loaded.");
		pos -= anchor * size;

		SDL_Rect srcSdlRect = srcRect.toSdlRect();
		SDL_Rect destSdlRect = {
			cast(uint)pos.x,
			cast(uint)pos.y,
			cast(uint)size.x,
			cast(uint)size.y
		};

		SDL_RenderCopy(cast(SDL_Renderer*)_sdlRenderer, cast(SDL_Texture*)_texture, &srcSdlRect, &destSdlRect);
	}

	void draw(Vec2f pos, Vec2f size, Vec4i srcRect, float angle, Flip flip = Flip.NoFlip, Vec2f anchor = Vec2f.half) const {
		enforce(_isLoaded, "Cannot render the texture: Asset not loaded.");
		pos -= anchor * size;
		
		SDL_Rect srcSdlRect = srcRect.toSdlRect();
		SDL_Rect destSdlRect = {
			cast(uint)pos.x,
			cast(uint)pos.y,
			cast(uint)size.x,
			cast(uint)size.y
		};

		SDL_RendererFlip rendererFlip = (flip == Flip.BothFlip) ?
			cast(SDL_RendererFlip)(SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL) :
			(flip == Flip.HorizontalFlip ? SDL_FLIP_HORIZONTAL :
				(flip == Flip.VerticalFlip ? SDL_FLIP_VERTICAL :
					SDL_FLIP_NONE));

		SDL_RenderCopyEx(cast(SDL_Renderer*)_sdlRenderer, cast(SDL_Texture*)_texture, &srcSdlRect, &destSdlRect, angle, null, rendererFlip);
	}
}
