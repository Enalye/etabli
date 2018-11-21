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

module atelier.render.window;

import std.stdio;
import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

import atelier.core;
import atelier.common;
import atelier.render.canvas;
import atelier.render.quadview;
import atelier.render.sprite;

static {
	SDL_Window* window;
	SDL_Renderer* renderer;
	Color windowClearColor;

	private {
		SDL_Surface* _icon;
		Vec2u _windowSize;
		Vec2f _screenSize, _centerScreen;
		bool _hasAudio = true;
		bool _hasCustomCursor = false;
		bool _showCursor = true;
		Sprite _customCursorSprite;
	}
}

@property {
	uint screenWidth() { return _windowSize.x; }
	uint screenHeight() { return _windowSize.y; }
	Vec2f screenSize() { return _screenSize; }
	Vec2f centerScreen() { return _centerScreen; }
}

private struct CanvasReference {
	const(SDL_Texture)* target;
	Vec2f position;
	Vec2f renderSize;
	Vec2f size;
    Canvas canvas;
}

static private CanvasReference[] _canvases;

enum Fullscreen {
	RealFullscreen,
	DesktopFullscreen,
	NoFullscreen
}

void createWindow(const Vec2u windowSize, string title) {
	DerelictSDL2.load(SharedLibVersion(2, 0, 2));
	DerelictSDL2Image.load();
	if(_hasAudio)
		DerelictSDL2Mixer.load();
	DerelictSDL2ttf.load();

	SDL_Init(SDL_INIT_EVERYTHING);

	if(-1 == TTF_Init())
		throw new Exception("Could not initialize TTF module.");

	if(_hasAudio) {
		if(-1 == Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 1024))
			throw new Exception("No audio device connected.");

		if(-1 == Mix_AllocateChannels(16))
			throw new Exception("Could not allocate audio channels.");
	}

	if(-1 == SDL_CreateWindowAndRenderer(windowSize.x, windowSize.y, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_WINDOW_RESIZABLE, &window, &renderer))
		throw new Exception("Window initialization failed.");

    SDL_RenderSetLogicalSize(renderer, windowSize.x, windowSize.y);
	CanvasReference canvasRef;
	canvasRef.target = null;
	canvasRef.position = cast(Vec2f)(windowSize) / 2;
	canvasRef.size = cast(Vec2f)(windowSize);
	canvasRef.renderSize = cast(Vec2f)(windowSize);
	_canvases ~= canvasRef;

	_windowSize = windowSize;
	_screenSize = cast(Vec2f)(windowSize);
	_centerScreen = _screenSize / 2f;

	setWindowTitle(title);
}

void destroyWindow() {
	if (window)
		SDL_DestroyWindow(window);

	if (renderer)
		SDL_DestroyRenderer(renderer);

    if(_hasAudio)
	    Mix_CloseAudio();
}

void enableAudio(bool enable) {
	_hasAudio = enable;
}

void setWindowTitle(string title) {
	SDL_SetWindowTitle(window, toStringz(title));
}

void setWindowSize(const Vec2u windowSize) {
	//_windowSize = windowSize;
	//_screenSize = cast(Vec2f)(windowSize);
	//_centerScreen = _screenSize / 2f;
	
	if (_canvases.length)
		_canvases[0].renderSize = cast(Vec2f)windowSize;
	SDL_SetWindowSize(window, windowSize.x, windowSize.y);
}

void setWindowIcon(string path) {
	if (_icon) {
		SDL_FreeSurface(_icon);
		_icon = null;
	}
	_icon = IMG_Load(toStringz(path));

	SDL_SetWindowIcon(window, _icon);
}

void setWindowCursor(Sprite cursorSprite) {
  _customCursorSprite = cursorSprite;
  _hasCustomCursor = true;
  SDL_ShowCursor(false);
}

void showWindowCursor(bool show) {
	_showCursor = show;
	if(!_hasCustomCursor)
		SDL_ShowCursor(show);
}

void setWindowFullScreen(Fullscreen fullscreen) {
	SDL_SetWindowFullscreen(window,
		(Fullscreen.RealFullscreen == fullscreen ? SDL_WINDOW_FULLSCREEN :
			(Fullscreen.DesktopFullscreen == fullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP :
				0)));
}

void setWindowBordered(bool bordered) {
	SDL_SetWindowBordered(window, bordered ? SDL_TRUE : SDL_FALSE);
}

void showWindow(bool show) {
	if (show)
		SDL_ShowWindow(window);
	else
		SDL_HideWindow(window);
}

void renderWindow() {
	Vec2f mousePos = getMousePos();
	if(_hasCustomCursor && _showCursor && mousePos.isBetween(Vec2f.one, screenSize - Vec2f.one)) {
		_customCursorSprite.color = Color.white;
		_customCursorSprite.draw(mousePos + _customCursorSprite.size / 2f);
	}
	SDL_RenderPresent(renderer);
	setRenderColor(windowClearColor);
	SDL_RenderClear(renderer);
}

void pushCanvas(Canvas canvas, bool clear = true) {
    canvas.isTarget = true;
	CanvasReference canvasRef;
	canvasRef.target = canvas.target;
	canvasRef.position = canvas.position;
	canvasRef.size = canvas.size;
	canvasRef.renderSize = cast(Vec2f)canvas.renderSize;
    canvasRef.canvas = canvas;
	_canvases ~= canvasRef;

	SDL_SetRenderTarget(renderer, cast(SDL_Texture*)canvasRef.target);
	setRenderColor(canvas.clearColor);
	if(clear)
		SDL_RenderClear(renderer);
}
/*
void pushCanvas(QuadView quadView, bool clear = true) {
	pushCanvas(quadView.getCurrent(), clear);
	if(clear)
		quadView.advance();
}*/

void popCanvas() {
	if (_canvases.length <= 1)
		throw new Exception("Attempt to pop the main canvas.");

    _canvases[$ - 1].canvas.isTarget = false;
	_canvases.length --;
	SDL_SetRenderTarget(renderer, cast(SDL_Texture*)_canvases[$ - 1].target);
	setRenderColor(windowClearColor);
}

Vec2f transformRenderSpace(const Vec2f pos) {
	const CanvasReference* canvasRef = &_canvases[$ - 1];
	return (pos - canvasRef.position) * (canvasRef.renderSize / canvasRef.size) + canvasRef.renderSize * 0.5f;
}

Vec2f transformCanvasSpace(const Vec2f pos, const Vec2f renderPos) {
	const CanvasReference* canvasRef = &_canvases[$ - 1];
	return (pos - renderPos) * (canvasRef.size / canvasRef.renderSize) + canvasRef.position;
}

Vec2f transformCanvasSpace(const Vec2f pos) {
	const CanvasReference* canvasRef = &_canvases[$ - 1];
	return pos * (canvasRef.size / canvasRef.renderSize);
}

Vec2f transformScale() {
	const CanvasReference* canvasRef = &_canvases[$ - 1];
	return canvasRef.renderSize / canvasRef.size;
}

bool isVisible(const Vec2f targetPosition, const Vec2f targetSize) {
	const CanvasReference* canvasRef = &_canvases[$ - 1];
	return (((canvasRef.position.x - canvasRef.size.x * .5f) < (targetPosition.x + targetSize.x * .5f))
		&& ((canvasRef.position.x + canvasRef.size.x * .5f) > (targetPosition.x - targetSize.x * .5f))
		&& ((canvasRef.position.y - canvasRef.size.y * .5f) < (targetPosition.y + targetSize.y * .5f))
		&& ((canvasRef.position.y + canvasRef.size.y * .5f) > (targetPosition.y - targetSize.y * .5f)));
}

void setRenderColor(const Color color) {
	auto sdlColor = color.toSDL();
	SDL_SetRenderDrawColor(renderer, sdlColor.r, sdlColor.g, sdlColor.b, sdlColor.a);
}

void drawPoint(const Vec2f position, const Color color) {
	if (isVisible(position, Vec2f(.0f, .0f))) {
		Vec2f rpos = transformRenderSpace(position);

		setRenderColor(color);
		SDL_RenderDrawPoint(renderer, cast(int)rpos.x, cast(int)rpos.y);
	}
}

void drawLine(const Vec2f startPosition, const Vec2f endPosition, const Color color) {
	Vec2f pos1 = transformRenderSpace(startPosition);
	Vec2f pos2 = transformRenderSpace(endPosition);

	setRenderColor(color);
	SDL_RenderDrawLine(renderer, cast(int)pos1.x, cast(int)pos1.y, cast(int)pos2.x, cast(int)pos2.y);
}

void drawArrow(const Vec2f startPosition, const Vec2f endPosition, const Color color) {
	Vec2f pos1 = transformRenderSpace(startPosition);
	Vec2f pos2 = transformRenderSpace(endPosition);
	Vec2f dir = (pos2 - pos1).normalized;
	Vec2f arrowBase = pos2 - dir * 25f;
	Vec2f pos3 = arrowBase + dir.normal * 20f;
	Vec2f pos4 = arrowBase - dir.normal * 20f;

	setRenderColor(color);
	SDL_RenderDrawLine(renderer, cast(int)pos1.x, cast(int)pos1.y, cast(int)pos2.x, cast(int)pos2.y);
	SDL_RenderDrawLine(renderer, cast(int)pos2.x, cast(int)pos2.y, cast(int)pos3.x, cast(int)pos3.y);
	SDL_RenderDrawLine(renderer, cast(int)pos2.x, cast(int)pos2.y, cast(int)pos4.x, cast(int)pos4.y);
}

void drawRect(const Vec2f origin, const Vec2f size, const Color color) {
	Vec2f pos1 = transformRenderSpace(origin);
	Vec2f pos2 = size * transformScale();

	SDL_Rect rect = {
		cast(int)pos1.x,
		cast(int)pos1.y,
		cast(int)pos2.x,
		cast(int)pos2.y
	};

	setRenderColor(color);
	SDL_RenderDrawRect(renderer, &rect);
}

void drawFilledRect(const Vec2f origin, const Vec2f size, const Color color) {
	Vec2f pos1 = transformRenderSpace(origin);
	Vec2f pos2 = size * transformScale();

	SDL_Rect rect = {
		cast(int)pos1.x,
		cast(int)pos1.y,
		cast(int)pos2.x,
		cast(int)pos2.y
	};

	setRenderColor(color);
	SDL_RenderFillRect(renderer, &rect);
}

void drawPixel(const Vec2f position, const Color color) {
	Vec2f pos = transformRenderSpace(position);

	SDL_Rect rect = {
		cast(int)pos.x,
		cast(int)pos.y,
		1, 1
	};

	setRenderColor(color);
	SDL_RenderFillRect(renderer, &rect);
}