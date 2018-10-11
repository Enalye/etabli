/**
    Quadview

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.quadview;

import atelier.core;

import atelier.render.view;
import atelier.render.texture;
import atelier.render.window;

class QuadView {
	Vec2f correction = Vec2f(-.001f, -.001f);

	private {
		View[4] _views;
		Vec2f _position = Vec2f.zero, _size = Vec2f.zero;
		Vec2u _renderSize;
		ubyte _currentView = 0U;
		Color _clearColor = Color.clear;
	}

	@property {
		Vec2u renderSize() const { return _renderSize; }
		Vec2u renderSize(Vec2u newRenderSize) {
			_renderSize = newRenderSize;
			foreach(view; _views)
				view.renderSize = _renderSize >> 1u;
			return _renderSize;
		}

		Vec2f size() const { return _size; }
		Vec2f size(Vec2f newSize) {
			_size = newSize;
			foreach(view; _views)
				view.size = _size / 2f;
			position(_position);
			return _size;
		}

		Vec2f position() const { return _position; }
		Vec2f position(Vec2f newPosition) {
			_position = newPosition;
			Vec2f quarterSize = _size / 4f;
			_views[0].position = _position - quarterSize;
			_views[1].position = _position + Vec2f(quarterSize.x, -quarterSize.y);
			_views[2].position = _position + Vec2f(-quarterSize.x, quarterSize.y);
			_views[3].position = _position + quarterSize;
			return _position;
		}

		Color clearColor() const { return _clearColor; }
		Color clearColor(Color newColor) {
			_clearColor = newColor;
			foreach(view; _views)
				view.clearColor = _clearColor;
			return _clearColor;
		}
	}

	this(Vec2f renderSize) {
		this(cast(Vec2u)(renderSize));
	}

	this(Vec2u renderSize) {
		_renderSize = renderSize;
		_size = cast(Vec2f)_renderSize;

		Vec2u halfSize = _renderSize >> 1U;
		foreach(i; 0.. 4)
			_views[i] = new View(halfSize);

		position(cast(Vec2f)(halfSize));

		//Clear all views
		foreach(view; _views) {
			pushView(view, true);
			popView();
		}
	}

	const (View) getCurrent() const {
		return _views[_currentView];
	}

	void advance() {
		_currentView ++;
		if(_currentView > 3U)
			_currentView = 0U;
	}

	void setColorMod(const Color color, Blend blend = Blend.AlphaBlending) {
		foreach(view; _views)
			view.setColorMod(color, blend);
	}

	void draw(const Vec2f renderPosition) {
		Vec2f quarterSize = cast(Vec2f)(_renderSize >> 2u) + correction;
		_views[0].draw(renderPosition - quarterSize);
		_views[1].draw(renderPosition + Vec2f(quarterSize.x, -quarterSize.y));
		_views[2].draw(renderPosition + Vec2f(-quarterSize.x, quarterSize.y));
		_views[3].draw(renderPosition + quarterSize);
	}

	void draw(const Vec2f renderPosition, const Vec2f scale) const {
		Vec2f quarterSize = cast(Vec2f)(_renderSize >> 2u) + correction;
		_views[0].draw(renderPosition - quarterSize, scale);
		_views[1].draw(renderPosition + Vec2f(quarterSize.x, -quarterSize.y), scale);
		_views[2].draw(renderPosition + Vec2f(-quarterSize.x, quarterSize.y), scale);
		_views[3].draw(renderPosition + quarterSize, scale);
	}
}