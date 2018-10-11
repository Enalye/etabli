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