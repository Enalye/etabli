/**
    Window

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
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
import atelier.render.view;
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

private struct ViewReference {
	const(SDL_Texture)* target;
	Vec2f position;
	Vec2f renderSize;
	Vec2f size;
}

static private ViewReference[] _views;

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

	ViewReference viewRef;
	viewRef.target = null;
	viewRef.position = cast(Vec2f)(windowSize) / 2;
	viewRef.size = cast(Vec2f)(windowSize);
	viewRef.renderSize = cast(Vec2f)(windowSize);
	_views ~= viewRef;

	_windowSize = windowSize;
	_screenSize = cast(Vec2f)(windowSize);
	_centerScreen = _screenSize / 2f;

	setWindowTitle(title);
}

void destroyWindow() {
	if (_icon)
		SDL_FreeSurface(_icon);

	if (window)
		SDL_DestroyWindow(window);

	if (renderer)
		SDL_DestroyRenderer(renderer);

    if(_hasAudio)
	    Mix_CloseAudio();
	//TTF_Quit();
	//SDL_Quit();
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
	
	if (_views.length)
		_views[0].renderSize = cast(Vec2f)windowSize;
	SDL_SetWindowSize(window, windowSize.x, windowSize.y);
}

void setWindowIcon(string path) {
	if (_icon) {
		SDL_FreeSurface(_icon);
		_icon = null;
	}
	_icon = SDL_LoadBMP(toStringz(path));

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

void pushView(const View view, bool clear = true) {
	ViewReference viewRef;
	viewRef.target = view.target;
	viewRef.position = view.position;
	viewRef.size = view.size;
	viewRef.renderSize = cast(Vec2f)view.renderSize;
	_views ~= viewRef;

	SDL_SetRenderTarget(renderer, cast(SDL_Texture*)viewRef.target);
	setRenderColor(view.clearColor);
	if(clear)
		SDL_RenderClear(renderer);
}

void pushView(QuadView quadView, bool clear = true) {
	pushView(quadView.getCurrent(), clear);
	if(clear)
		quadView.advance();
}

void popView() {
	if (_views.length <= 1)
		throw new Exception("Attempt to pop the main view.");

	_views.length --;
	SDL_SetRenderTarget(renderer, cast(SDL_Texture*)_views[_views.length - 1].target);
	setRenderColor(windowClearColor);
}

Vec2f getViewRenderPos(const Vec2f pos) {
	const ViewReference* viewRef = &_views[_views.length - 1];
	return (pos - viewRef.position) * (viewRef.renderSize / viewRef.size) + viewRef.renderSize * 0.5f;
}

Vec2f getViewVirtualPos(const Vec2f pos, const Vec2f renderPos) {
	const ViewReference* viewRef = &_views[_views.length - 1];
	return (pos - renderPos) * (viewRef.size / viewRef.renderSize) + viewRef.position;
}

Vec2f getViewVirtualPos(const Vec2f pos) {
	const ViewReference* viewRef = &_views[_views.length - 1];
	return pos * (viewRef.size / viewRef.renderSize);
}

Vec2f getViewScale() {
	const ViewReference* viewRef = &_views[_views.length - 1];
	return viewRef.renderSize / viewRef.size;
}

bool isVisible(const Vec2f targetPosition, const Vec2f targetSize) {
	const ViewReference* viewRef = &_views[_views.length - 1];
	return (((viewRef.position.x - viewRef.size.x * .5f) < (targetPosition.x + targetSize.x * .5f))
		&& ((viewRef.position.x + viewRef.size.x * .5f) > (targetPosition.x - targetSize.x * .5f))
		&& ((viewRef.position.y - viewRef.size.y * .5f) < (targetPosition.y + targetSize.y * .5f))
		&& ((viewRef.position.y + viewRef.size.y * .5f) > (targetPosition.y - targetSize.y * .5f)));
}

void setRenderColor(const Color color) {
	auto sdlColor = color.toSDL();
	SDL_SetRenderDrawColor(renderer, sdlColor.r, sdlColor.g, sdlColor.b, sdlColor.a);
}

void drawPoint(const Vec2f position, const Color color) {
	if (isVisible(position, Vec2f(.0f, .0f))) {
		Vec2f rpos = getViewRenderPos(position);

		setRenderColor(color);
		SDL_RenderDrawPoint(renderer, cast(int)rpos.x, cast(int)rpos.y);
	}
}

void drawLine(const Vec2f startPosition, const Vec2f endPosition, const Color color) {
	Vec2f pos1 = getViewRenderPos(startPosition);
	Vec2f pos2 = getViewRenderPos(endPosition);

	setRenderColor(color);
	SDL_RenderDrawLine(renderer, cast(int)pos1.x, cast(int)pos1.y, cast(int)pos2.x, cast(int)pos2.y);
}

void drawArrow(const Vec2f startPosition, const Vec2f endPosition, const Color color) {
	Vec2f pos1 = getViewRenderPos(startPosition);
	Vec2f pos2 = getViewRenderPos(endPosition);
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
	Vec2f pos1 = getViewRenderPos(origin);
	Vec2f pos2 = size * getViewScale();

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
	Vec2f pos1 = getViewRenderPos(origin);
	Vec2f pos2 = size * getViewScale();

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
	Vec2f pos = getViewRenderPos(position);

	SDL_Rect rect = {
		cast(int)pos.x,
		cast(int)pos.y,
		1, 1
	};

	setRenderColor(color);
	SDL_RenderFillRect(renderer, &rect);
}