/**
    Frame

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.frame;

import std.conv;

import atelier.core;
import atelier.common;
import atelier.render.sprite;
import atelier.render.view;
import atelier.render.window;

import atelier.ui.widget;

class Frame: WidgetGroup {
	protected View _view;
	bool clearRenderer = true;
	
	@property {
		View view() { return _view; }
		View view(View newView) { return _view = newView; }
	}

	this(Vec2u newSize) {
		_view = new View(newSize);
		_size = to!Vec2f(newSize);
		_isFrame = true;
	}

	this(View newView) {
		_view = newView;
		_isFrame = true;
	}
	
	override void onEvent(Event event) {
		pushView(_view, false);
		super.onEvent(event);
		popView();
	}

	override void draw() {
		pushView(_view, clearRenderer);
		super.draw();
		popView();
		_view.draw(_position);
	}

    override void onPosition() {
        _view.position = _position;
    }

    override void onSize() {
        _view.position = _position;
    }
}