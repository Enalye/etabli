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
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.slider;

private class LogContainer: GuiElementCanvas {
	public {
		LogLayout layout;
	}

	this(Vec2f newSize) {
		isLocked = true;
		layout = new LogLayout;
		size(newSize);
		addChildGui(layout);
	}

	override void draw() {
		layout.draw();
	}
}

class LogList: GuiElement {
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

		super.addChildGui(_slider);
		super.addChildGui(_container);

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
				foreach(uint id, const GuiElement widget; widgets) {
					if(widget.isHovered)
						_idElementSelected = id;
				}
			}
		}
		if(!isOnInteractableGuiElement(_lastMousePos) && event.type == EventType.MouseWheel)
			_slider.onEvent(event);
	}

    override void onPosition() {
        _slider.position = center - Vec2f((size.x - _slider.size.x) / 2f, 0f) + size / 2f;
        _container.position = center + Vec2f(_slider.size.x / 2f, 0f) + size / 2f;
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

	override void addChildGui(GuiElement widget) {
		_container.layout.addChildGui(widget);
		repositionContainer();
	}

	override void removeChildrenGuis() {
		_container.layout.removeChildrenGuis();
		repositionContainer();
	}

	override void removeChildGui(uint id) {
		_container.layout.removeChildGui(id);
		repositionContainer();
	}

	override int getChildrenGuisCount() {
		return _container.layout.getChildrenGuisCount();
	}
}