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

module atelier.ui.list.loglist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui.widget;
import atelier.ui.layout;
import atelier.ui.slider;

private class LogContainer: WidgetCanvas {
	public {
		LogLayout layout;
	}

	this(Vec2f newSize) {
		isLocked = true;
		layout = new LogLayout;
		size(newSize);
		addChild(layout);
	}

	override void draw() {
		layout.draw();
	}
}

class LogList: Widget {
	protected {
		LogContainer _container;
		Slider _slider;
		Vec2f _lastMousePos = Vec2f.zero;
		uint _idElementSelected = 0u;
	}

	@property {
		uint selected() const { return _idElementSelected; }
	}

	this(Vec2f newSize) {
		isLocked = true;
		_slider = new VScrollbar;
		_slider.value01 = 1f;
		_container = new LogContainer(newSize);

		super.addChild(_slider);
		super.addChild(_container);

		size(newSize);
		position(Vec2f.zero);
	}

	override void onEvent(Event event) {
		super.onEvent(event);
		if(event.type == EventType.MouseDown || event.type == EventType.MouseUp || event.type == EventType.MouseUpdate) {
			_lastMousePos = event.position;
			if(_slider.isInside(event.position))
				_slider.onEvent(event);
			else if(event.type == EventType.MouseDown) {
				auto widgets = _container.layout.children;
				foreach(uint id, const Widget widget; widgets) {
					if(widget.isHovered)
						_idElementSelected = id;
				}
			}
		}
		if(!isOnInteractableWidget(_lastMousePos) && event.type == EventType.MouseWheel)
			_slider.onEvent(event);
	}

    override void onPosition() {
        _slider.position = pivot - Vec2f((size.x - _slider.size.x) / 2f, 0f) + size / 2f;
        _container.position = pivot + Vec2f(_slider.size.x / 2f, 0f) + size / 2f;
    }

    override void onSize() {
        _slider.size = Vec2f(10f, size.y);
        _container.size = Vec2f(size.x - _slider.size.x, size.y);
        _container.canvas.renderSize = _container.size.to!Vec2u;
        onPosition();
    }

	override void update(float deltaTime) {
		_slider.update(deltaTime);
		float min = _container.canvas.size.y / 2f;
		float max = _container.layout.size.y - _container.canvas.size.y / 2f;
		float exceedingHeight = _container.layout.size.y - _container.canvas.size.y;

		if(exceedingHeight < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingHeight / (_container.canvas.size.y / 50f);
			_slider.step = to!uint(_slider.max);
		}
		_container.canvas.position = Vec2f(0f, lerp(min, max, _slider.offset));
	}

	private void repositionContainer() {
		_container.layout.position = Vec2f(5f + _container.layout.size.x / 2f - _container.size.x / 2f, _container.layout.size.y / 2f);
	}

	override void addChild(Widget widget) {
		_container.layout.addChild(widget);
		repositionContainer();
	}

	override void removeChildren() {
		_container.layout.removeChildren();
		repositionContainer();
	}

	override void removeChild(uint id) {
		_container.layout.removeChild(id);
		repositionContainer();
	}

	override int getChildrenCount() {
		return _container.layout.getChildrenCount();
	}
}