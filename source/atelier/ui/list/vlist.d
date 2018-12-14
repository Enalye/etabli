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

module atelier.ui.list.vlist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui;

private class ListContainer: GuiElementCanvas {
	public {
		VLayout layout;
	}

	this(Vec2f newSize) {
		isLocked = true;
		layout = new VLayout;
		size(newSize);
		addChildGui(layout);
	}
}

class VList: GuiElement {
	protected {
		ListContainer _container;
		Slider _slider;
		Vec2f _lastMousePos = Vec2f.zero;
		float _layoutLength = 25f;
		uint _nbElements = 0u;
		uint _idElementSelected = 0u;
	}

	@property {
		uint selected() const { return _idElementSelected; }
		uint selected(uint id) {
			if(id > _nbElements)
				throw new Exception("VList: index out of bounds");
			_idElementSelected = id;

            //Update children
            auto widgets = _container.layout.children;
            foreach(GuiElement gui; _container.layout.children)
                gui.isSelected = false;
            if(_idElementSelected < widgets.length)
                widgets[_idElementSelected].isSelected = true;
			return _idElementSelected;
		}

		float layoutLength() const { return _layoutLength; }
		float layoutLength(float length) {
			_layoutLength = length;
			_container.layout.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
			return _layoutLength;
		}
	}

	this(Vec2f newSize) {
		isLocked = true;
		_slider = new VScrollbar;
        _slider.setAlign(GuiAlignX.Left, GuiAlignY.Center);
		_container = new ListContainer(newSize);
        _container.setAlign(GuiAlignX.Right, GuiAlignY.Top);
        _container.layout.setAlign(GuiAlignX.Right, GuiAlignY.Top);

		super.addChildGui(_slider);
		super.addChildGui(_container);

		size(newSize);
		position(Vec2f.zero);

        setEventHook(true);
        
		_container.layout.size = Vec2f(_container.size.x, 0f);
	}

    override void onCallback(string id) {
        if(id != "list")
            return;
        auto widgets = _container.layout.children;
        foreach(uint elementId, ref GuiElement gui; _container.layout.children) {
            gui.isSelected = false;
            if(gui.isHovered)
                _idElementSelected = elementId;
        }
        if(_idElementSelected < widgets.length)
            widgets[_idElementSelected].isSelected = true;
    }

    override void onEvent(Event event) {
        if(event.type == EventType.MouseWheel)
            _slider.onEvent(event);
    }
    
    override void onSize() {
        _slider.size = Vec2f(10f, _size.y);
        _container.layout.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.size = Vec2f(size.x - _slider.size.x, size.y);
        _container.canvas.renderSize = _container.size.to!Vec2u;
    }

	override void update(float deltaTime) {
		super.update(deltaTime);
		float min = 0f;
		float max = _container.layout.size.y - _container.size.y;
		float exceedingHeight = _container.layout.size.y - _container.canvas.size.y;

		if(exceedingHeight < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingHeight / _layoutLength;
			_slider.step = to!uint(_slider.max);
		}
		_container.canvas.position = _container.canvas.size / 2f + Vec2f(0f, lerp(min, max, _slider.offset));
	}

	override void addChildGui(GuiElement gui) {
        gui.position = Vec2f.zero;
        gui.setAlign(GuiAlignX.Right, GuiAlignY.Top);
		gui.isSelected = (_nbElements == 0u);
        gui.setCallback(this, "list");

		_nbElements ++;
		_container.layout.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
		_container.layout.position = Vec2f.zero;
		_container.layout.addChildGui(gui);
	}

	override void removeChildrenGuis() {
		_nbElements = 0u;
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(_container.size.x, 0f);
		_container.layout.position = Vec2f.zero;
		_container.layout.removeChildrenGuis();
	}

	override void removeChildGui(uint id) {
		_container.layout.removeChildGui(id);
		_nbElements = _container.layout.getChildrenGuisCount();
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
		_container.layout.position = Vec2f(0f, _container.layout.size.y / 2f);
	}

	override int getChildrenGuisCount() {
		return _container.layout.getChildrenGuisCount();	
	}

	GuiElement[] getList() {
		return _container.layout.children;
	}
}