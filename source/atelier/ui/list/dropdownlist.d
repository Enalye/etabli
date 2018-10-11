/**
    Dropdown list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.dropdownlist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui.list.vlist;
import atelier.ui.widget;
import atelier.ui.overlay;

class DropDownList: WidgetGroup {
	private {
		VList _list;
		Vec2f _originalSize, _originalPosition;
		bool _isClicked = false;
		uint _maxListLength = 5;
	}

	@property {
		uint selected() const { return _list.selected; }
		uint selected(uint id) { return _list.selected = id; }
	}

	this(Vec2f newSize, uint maxListLength = 5U) {
		_maxListLength = maxListLength;
		_originalSize = newSize;
		_list = new VList(_originalSize * Vec2f(1f, _maxListLength));
		_size = _originalSize;
	}

	override void onEvent(Event event) {
		super.onEvent(event);
		if(!isLocked) {
			if(event.type == EventType.MouseUp) {
				_isClicked = !_isClicked;

				if(_isClicked) {
					setOverlay(this);
					setOverlay(_list);
				}
				else {
					stopOverlay();
					triggerCallback();
				}
			}
		}
		if(_isClicked)
			_list.onEvent(event);
	}

    override void onPosition() {
        _originalPosition = _position;
    }

	override void update(float deltaTime) {
		if(_isClicked) {
			Vec2f newSize = _originalSize * Vec2f(1f, _maxListLength + 1f);
			_list.position = _originalPosition + Vec2f(0f, newSize.y / 2f);
			_list.update(deltaTime);
		}
	}

	override void draw() {
		super.draw();
		auto widgets = _list.getList();
		if(widgets.length > _list.selected) {
			auto widget = widgets[_list.selected];
			auto wPos = widget.position;
			auto wSize = widget.size;

			widget.position = _originalPosition;
			widget.size = _originalSize;
			widget.draw();

			widget.position = wPos;
			widget.size = wSize;
		}
		drawRect(_originalPosition - _originalSize / 2f, _originalSize, Color.white);
	}

	override void drawOverlay() {
		super.drawOverlay();
		if(_isClicked)
			_list.draw();
	}

	override void addChild(Widget widget) {
		_list.addChild(widget);
	}

	override void removeChildren() {
		_list.removeChildren();
	}

	override void removeChild(uint id) {
		_list.removeChild(id);
	}

	override int getChildrenCount() {
		return _list.getChildrenCount();
	}

	Widget[] getList() {
		return _list.getList();
	}
}