/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.render.window;

import std.stdio;
import std.string;

import bindbc.sdl, bindbc.sdl.image, bindbc.sdl.mixer, bindbc.sdl.ttf;

import atelier.core;
import atelier.common;
import atelier.render.canvas;
import atelier.render.quadview;
import atelier.render.sprite;

static {
    package(atelier) {
        SDL_Window* _sdlWindow;
        SDL_Renderer* _sdlRenderer;
        Color _windowClearColor;
    }

    private {
        SDL_Surface* _icon;
        Vec2i _windowDimensions;
        Vec2f _windowSize, _windowCenter;
        bool _hasAudio = true;
        bool _hasCustomCursor = false;
        bool _showCursor = true;
        Sprite _customCursorSprite;
        DisplayMode _displayMode = DisplayMode.windowed;
    }
}

/// Width of the window in pixels.
int getWindowWidth() {
    return _windowDimensions.x;
}

/// Height of the window in pixels.
int getWindowHeight() {
    return _windowDimensions.y;
}

/// Dimensions of the window in pixels.
Vec2i getWindowDimensions() {
    return _windowDimensions;
}

/// Size of the window in pixels.
Vec2f getWindowSize() {
    return _windowSize;
}

/// Half of the size of the window in pixels.
Vec2f getWindowCenter() {
    return _windowCenter;
}

private struct CanvasReference {
    const(SDL_Texture)* target;
    Vec2f position;
    Vec2f renderSize;
    Vec2f size;
    Canvas canvas;
}

static private CanvasReference[] _canvases;

/// Window display mode.
enum DisplayMode {
    fullscreen,
    desktop,
    windowed
}

import std.exception;

/// Create the application window.
void createWindow(const Vec2i windowSize, string title) {
    enforce(loadSDL() >= SDLSupport.sdl2010, "SDL support <= 2.0.10");
    enforce(loadSDLImage() >= SDLImageSupport.sdlImage204, "SDL image support <= 2.0.4");
    enforce(loadSDLTTF() >= SDLTTFSupport.sdlTTF2014, "SDL ttf support <= 2.0.14");
    enforce(loadSDLMixer() >= SDLMixerSupport.sdlMixer204, "SDL mixer support <= 2.0.4");

    enforce(SDL_Init(SDL_INIT_EVERYTHING) == 0,
            "SDL initialisation failure: " ~ fromStringz(SDL_GetError()));

    enforce(TTF_Init() != -1, "SDL ttf initialisation failure");
    enforce(Mix_OpenAudio(44_100, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS,
            1024) != -1, "no audio device connected");
    enforce(Mix_AllocateChannels(16) != -1, "audio channels allocation failure");

    SDL_SetHint(SDL_HINT_RENDER_BATCHING, "1");

    enforce(SDL_CreateWindowAndRenderer(windowSize.x, windowSize.y,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC | SDL_WINDOW_RESIZABLE,
            &_sdlWindow, &_sdlRenderer) != -1, "window initialisation failure");

    CanvasReference canvasRef;
    canvasRef.target = null;
    canvasRef.position = cast(Vec2f)(windowSize) / 2;
    canvasRef.size = cast(Vec2f)(windowSize);
    canvasRef.renderSize = cast(Vec2f)(windowSize);
    _canvases ~= canvasRef;

    _windowDimensions = windowSize;
    _windowSize = cast(Vec2f)(windowSize);
    _windowCenter = _windowSize / 2f;

    setWindowTitle(title);
}

/// Cleanup the application window.
void destroyWindow() {
    if (_sdlWindow)
        SDL_DestroyWindow(_sdlWindow);

    if (_sdlRenderer)
        SDL_DestroyRenderer(_sdlRenderer);

    if (_hasAudio)
        Mix_CloseAudio();
}

/// Enable/Disable audio (Call before creating the window). \
/// Enabled by default.
void enableAudio(bool enable) {
    _hasAudio = enable;
}

/// Change the actual window title.
void setWindowTitle(string title) {
    SDL_SetWindowTitle(_sdlWindow, toStringz(title));
}

/// Change the base color of the base canvas.
void setWindowClearColor(Color color) {
    _windowClearColor = color;
}

/// Update the window size. \
/// If `isLogical` is set, the actual window won't be resized, only the canvas will.
void setWindowSize(const Vec2i windowSize, bool isLogical = false) {
    resizeWindow(windowSize);

    if (isLogical)
        SDL_RenderSetLogicalSize(_sdlRenderer, windowSize.x, windowSize.y);
    else
        SDL_SetWindowSize(_sdlWindow, windowSize.x, windowSize.y);
}

/// Call this to update canvas size when window's size is changed externally.
package(atelier) void resizeWindow(const Vec2i windowSize) {
    _windowDimensions = windowSize;
    _windowSize = cast(Vec2f)(windowSize);
    _windowCenter = _windowSize / 2f;

    if (_canvases.length) {
        _canvases[0].position = cast(Vec2f)(windowSize) / 2;
        _canvases[0].size = cast(Vec2f)(windowSize);
        _canvases[0].renderSize = cast(Vec2f) windowSize;
    }
}

/// Current window size.
private Vec2i fetchWindowSize() {
    Vec2i windowSize;
    SDL_GetWindowSize(_sdlWindow, &windowSize.x, &windowSize.y);
    return windowSize;
}

/// The window cannot be resized less than this.
void setWindowMinSize(Vec2i size) {
    SDL_SetWindowMinimumSize(_sdlWindow, size.x, size.y);
}

/// The window cannot be resized more than this.
void setWindowMaxSize(Vec2i size) {
    SDL_SetWindowMaximumSize(_sdlWindow, size.x, size.y);
}

/// Change the icon displayed.
void setWindowIcon(string path) {
    if (_icon) {
        SDL_FreeSurface(_icon);
        _icon = null;
    }
    _icon = IMG_Load(toStringz(path));

    SDL_SetWindowIcon(_sdlWindow, _icon);
}

/// Change the cursor to a custom one and disable the default one.
void setWindowCursor(Sprite cursorSprite) {
    _customCursorSprite = cursorSprite;
    _hasCustomCursor = true;
    SDL_ShowCursor(false);
}

/// Enable/Disable the cursor. \
/// Enabled by default.
void showWindowCursor(bool show) {
    _showCursor = show;
    if (!_hasCustomCursor)
        SDL_ShowCursor(show);
}

/// Change the display mode between windowed, desktop fullscreen and fullscreen.
void setWindowDisplay(DisplayMode displayMode) {
    import atelier.ui : handleGuiElementEvent;

    _displayMode = displayMode;
    SDL_WindowFlags mode;
    final switch (displayMode) with (DisplayMode) {
    case fullscreen:
        mode = SDL_WINDOW_FULLSCREEN;
        break;
    case desktop:
        mode = SDL_WINDOW_FULLSCREEN_DESKTOP;
        break;
    case windowed:
        mode = cast(SDL_WindowFlags) 0;
        break;
    }
    SDL_SetWindowFullscreen(_sdlWindow, mode);
    Vec2i newSize = fetchWindowSize();
    resizeWindow(newSize);
    Event event;
    event.type = Event.Type.resize;
    event.window.size = newSize;
    handleGuiElementEvent(event);
}

/// Current display mode.
DisplayMode getWindowDisplay() {
    return _displayMode;
}

/// Enable/Disable the borders.
void setWindowBordered(bool isBordered) {
    SDL_SetWindowBordered(_sdlWindow, isBordered ? SDL_TRUE : SDL_FALSE);
}

/// Allow the user to resize the window
void setWindowResizable(bool isResizable) {
    SDL_SetWindowResizable(_sdlWindow, isResizable ? SDL_TRUE : SDL_FALSE);
}

/// Show/Hide the window. \
/// Shown by default obviously.
void showWindow(bool show) {
    if (show)
        SDL_ShowWindow(_sdlWindow);
    else
        SDL_HideWindow(_sdlWindow);
}

/// Render everything on screen.
void renderWindow() {
    Vec2f mousePos = getMousePos();
    if (_hasCustomCursor && _showCursor && mousePos.isBetween(Vec2f.one, _windowSize - Vec2f.one)) {
        _customCursorSprite.color = Color.white;
        _customCursorSprite.draw(mousePos + _customCursorSprite.size / 2f);
    }
    SDL_RenderPresent(_sdlRenderer);
    setRenderColor(_windowClearColor);
    SDL_RenderClear(_sdlRenderer);
}

/// Push a render canvas on the stack.
/// Everything after that and before the next popCanvas will be rendered onto this.
/// You **must** call popCanvas after that.
void pushCanvas(Canvas canvas, bool clear = true) {
    canvas._isTargetOnStack = true;
    CanvasReference canvasRef;
    canvasRef.target = canvas.target;
    canvasRef.position = canvas.position;
    canvasRef.size = canvas.size;
    canvasRef.renderSize = cast(Vec2f) canvas.renderSize;
    canvasRef.canvas = canvas;
    _canvases ~= canvasRef;

    SDL_SetRenderTarget(_sdlRenderer, cast(SDL_Texture*) canvasRef.target);
    setRenderColor(canvas.color, canvas.alpha);
    if (clear)
        SDL_RenderClear(_sdlRenderer);
}
/*
void pushCanvas(QuadView quadView, bool clear = true) {
	pushCanvas(quadView.getCurrent(), clear);
	if(clear)
		quadView.advance();
}*/

/// Called after pushCanvas to remove the render canvas from the stack.
/// When there is no canvas on the stack, everything is displayed directly on screen.
void popCanvas() {
    if (_canvases.length <= 1)
        throw new Exception("Attempt to pop the main canvas.");

    _canvases[$ - 1].canvas._isTargetOnStack = false;
    _canvases.length--;
    SDL_SetRenderTarget(_sdlRenderer, cast(SDL_Texture*) _canvases[$ - 1].target);
    setRenderColor(_windowClearColor);
}

/// Change coordinate system from inside to outside the canvas.
Vec2f transformRenderSpace(const Vec2f pos) {
    const CanvasReference* canvasRef = &_canvases[$ - 1];
    return (pos - canvasRef.position) * (
            canvasRef.renderSize / canvasRef.size) + canvasRef.renderSize * 0.5f;
}

/// Change coordinate system from outside to inside the canvas.
Vec2f transformCanvasSpace(const Vec2f pos, const Vec2f renderPos) {
    const CanvasReference* canvasRef = &_canvases[$ - 1];
    return (pos - renderPos) * (canvasRef.size / canvasRef.renderSize) + canvasRef.position;
}

/// Change coordinate system from outside to insside the canvas.
Vec2f transformCanvasSpace(const Vec2f pos) {
    const CanvasReference* canvasRef = &_canvases[$ - 1];
    return pos * (canvasRef.size / canvasRef.renderSize);
}

/// Change the scale from outside to inside the canvas.
Vec2f transformScale() {
    const CanvasReference* canvasRef = &_canvases[$ - 1];
    return canvasRef.renderSize / canvasRef.size;
}

/// Check if something is inside the actual canvas rendering area.
bool isVisible(const Vec2f targetPosition, const Vec2f targetSize) {
    const CanvasReference* canvasRef = &_canvases[$ - 1];
    return (((canvasRef.position.x - canvasRef.size.x * .5f) < (
            targetPosition.x + targetSize.x * .5f))
            && ((canvasRef.position.x + canvasRef.size.x * .5f) > (
                targetPosition.x - targetSize.x * .5f))
            && ((canvasRef.position.y - canvasRef.size.y * .5f) < (
                targetPosition.y + targetSize.y * .5f))
            && ((canvasRef.position.y + canvasRef.size.y * .5f) > (
                targetPosition.y - targetSize.y * .5f)));
}

/// Change the draw color, used internally. Don't bother use it.
void setRenderColor(const Color color, float alpha = 1f) {
    const auto sdlColor = color.toSDL();
    SDL_SetRenderDrawColor(_sdlRenderer, sdlColor.r, sdlColor.g, sdlColor.b,
            cast(ubyte)(clamp(alpha, 0f, 1f) * 255f));
}

/// Draw a single point.
void drawPoint(const Vec2f position, const Color color, float alpha = 1f) {
    if (isVisible(position, Vec2f(.0f, .0f))) {
        const Vec2f rpos = transformRenderSpace(position);

        setRenderColor(color, alpha);
        SDL_RenderDrawPoint(_sdlRenderer, cast(int) rpos.x, cast(int) rpos.y);
    }
}

/// Draw a line between the two positions.
void drawLine(const Vec2f startPosition, const Vec2f endPosition, const Color color, float alpha = 1f) {
    const Vec2f pos1 = transformRenderSpace(startPosition);
    const Vec2f pos2 = transformRenderSpace(endPosition);

    setRenderColor(color, alpha);
    SDL_RenderDrawLine(_sdlRenderer, cast(int) pos1.x, cast(int) pos1.y,
            cast(int) pos2.x, cast(int) pos2.y);
}

/// Draw an arrow with its head pointing at the end position.
void drawArrow(const Vec2f startPosition, const Vec2f endPosition, const Color color,
        float alpha = 1f) {
    const Vec2f pos1 = transformRenderSpace(startPosition);
    const Vec2f pos2 = transformRenderSpace(endPosition);
    const Vec2f dir = (pos2 - pos1).normalized;
    const Vec2f arrowBase = pos2 - dir * 25f;
    const Vec2f pos3 = arrowBase + dir.normal * 20f;
    const Vec2f pos4 = arrowBase - dir.normal * 20f;

    setRenderColor(color, alpha);
    SDL_RenderDrawLine(_sdlRenderer, cast(int) pos1.x, cast(int) pos1.y,
            cast(int) pos2.x, cast(int) pos2.y);
    SDL_RenderDrawLine(_sdlRenderer, cast(int) pos2.x, cast(int) pos2.y,
            cast(int) pos3.x, cast(int) pos3.y);
    SDL_RenderDrawLine(_sdlRenderer, cast(int) pos2.x, cast(int) pos2.y,
            cast(int) pos4.x, cast(int) pos4.y);
}

/// Draw a vertical cross (like this: +) with the indicated size.
void drawCross(const Vec2f center, float length, const Color color, float alpha = 1f) {
    const float halfLength = length / 2f;
    drawLine(center + Vec2f(-halfLength, 0f), center + Vec2f(halfLength, 0f), color, alpha);
    drawLine(center + Vec2f(0f, -halfLength), center + Vec2f(0f, halfLength), color, alpha);
}

/// Draw a rectangle border.
void drawRect(const Vec2f origin, const Vec2f size, const Color color, float alpha = 1f) {
    const Vec2f pos1 = transformRenderSpace(origin);
    const Vec2f pos2 = size * transformScale();

    const SDL_Rect rect = {
        cast(int) pos1.x, cast(int) pos1.y, cast(int) pos2.x, cast(int) pos2.y
    };

    setRenderColor(color, alpha);
    SDL_RenderDrawRect(_sdlRenderer, &rect);
}

/// Draw a fully filled rectangle.
void drawFilledRect(const Vec2f origin, const Vec2f size, const Color color, float alpha = 1f) {
    const Vec2f pos1 = transformRenderSpace(origin);
    const Vec2f pos2 = size * transformScale();

    const SDL_Rect rect = {
        cast(int) pos1.x, cast(int) pos1.y, cast(int) pos2.x, cast(int) pos2.y
    };

    setRenderColor(color, alpha);
    SDL_RenderFillRect(_sdlRenderer, &rect);
}

/// Draw a rectangle with a size of 1.
void drawPixel(const Vec2f position, const Color color, float alpha = 1f) {
    const Vec2f pos = transformRenderSpace(position);

    const SDL_Rect rect = {cast(int) pos.x, cast(int) pos.y, 1, 1};

    setRenderColor(color, alpha);
    SDL_RenderFillRect(_sdlRenderer, &rect);
}
