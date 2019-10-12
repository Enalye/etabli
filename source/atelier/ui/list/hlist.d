/**
    Horizontal list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.hlist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui;

private class ListContainer: GuiElementCanvas {
	public {
		HLayout layout;
	}

	this(Vec2f newSize) {
		isLocked = true;
		layout = new HLayout;
		size(newSize);
		addChildGui(layout);
	}
}

/// Horizontal list of elements with a slider.
class HList: GuiElement {
	protected {
		ListContainer _container;
		Slider _slider;
		Vec2f _lastMousePos = Vec2f.zero;
		float _layoutLength = 25f;
		int _nbElements;
		int _idElementSelected;
	}

	@property {
		int selected() const { return _idElementSelected; }
		int selected(int id) {
			if(id >= _nbElements)
				id = _nbElements - 1;
            if(id < 0)
                id = 0;
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
			_container.layout.size = Vec2f(_layoutLength * _nbElements, _container.size.y);
			return _layoutLength;
		}
	}

	this(Vec2f newSize) {
		isLocked = true;
		_slider = new HScrollbar;
        _slider.setAlign(GuiAlignX.left, GuiAlignY.center);
		_container = new ListContainer(newSize);
        _container.setAlign(GuiAlignX.right, GuiAlignY.top);
        _container.layout.setAlign(GuiAlignX.right, GuiAlignY.top);

		super.addChildGui(_slider);
		super.addChildGui(_container);

		size(newSize);
		position(Vec2f.zero);
        
        setEventHook(true);

		_container.layout.size = Vec2f(0f, _container.size.y);
	}

	override void onCallback(string id) {
        if(id != "list")
            return;
        auto widgets = _container.layout.children;
        foreach(size_t elementId, ref GuiElement gui; _container.layout.children) {
            gui.isSelected = false;
            if(gui.isHovered)
                _idElementSelected = cast(uint)elementId;
        }
        if(_idElementSelected < widgets.length)
            widgets[_idElementSelected].isSelected = true;
    }

    override void onEvent(Event event) {
        if(event.type == EventType.mouseWheel)
            _slider.onEvent(event);
    }

    override void onSize() {
        _slider.size = Vec2f(size.x, 10f);
        _container.layout.size = Vec2f(_layoutLength * _nbElements, _container.size.y);
        _container.size = Vec2f(size.x, size.y - _slider.size.y);
        _container.canvas.renderSize = _container.size.to!Vec2u;
    }

	override void update(float deltaTime) {
		super.update(deltaTime);
		float min = 0f;
		float max = _container.layout.size.x - _container.canvas.size.x;
		float exceedingWidth = _container.layout.size.x - _container.canvas.size.x;

		if(exceedingWidth < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingWidth / _layoutLength;
			_slider.step = to!uint(_slider.max);
		}
		_container.canvas.position = _container.canvas.size / 2f + Vec2f(lerp(min, max, _slider.offset), 0f);
	}

	override void addChildGui(GuiElement gui) {
        gui.position = Vec2f.zero;
        gui.setAlign(GuiAlignX.right, GuiAlignY.top);
		gui.isSelected = (_nbElements == 0u);
        gui.setCallback(this, "list");

		_nbElements ++;
		_container.layout.size = Vec2f(_layoutLength * _nbElements, _container.size.y);
		_container.layout.position = Vec2f.zero;
		_container.layout.addChildGui(gui);
	}

	override void removeChildrenGuis() {
		_nbElements = 0u;
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(0f, _container.size.y);
		_container.layout.position = Vec2f.zero;
		_container.layout.removeChildrenGuis();
	}

	override void removeChildGui(uint id) {
		_container.layout.removeChildGui(id);
		_nbElements = _container.layout.getChildrenGuisCount();
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(_layoutLength * _nbElements, size.y);
		_container.layout.position = Vec2f(_container.layout.size.x / 2f, 0f);
	}

	override int getChildrenGuisCount() {
		return _container.layout.getChildrenGuisCount();	
	}

	GuiElement[] getList() {
		return _container.layout.children;
	}
}