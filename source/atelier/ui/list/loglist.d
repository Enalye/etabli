/**
    Log list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.loglist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui.widget;
import atelier.ui.layout;
import atelier.ui.slider;

private class LogContainer: WidgetGroup {
	public {
		View view;
		LogLayout layout;
	}

	this(Vec2f size) {
		createGui(size);
	}

	override void onEvent(Event event) {
		pushView(view, false);
		super.onEvent(event);
		popView();
	}

	override void update(float deltaTime) {
		pushView(view, false);
		super.update(deltaTime);
		popView();
	}

	override void draw() {
		view.setColorMod(Color.white, Blend.AlphaBlending);
		pushView(view, true);
		layout.draw();
		popView();
		view.draw(_position);
	}

	protected void createGui(Vec2f newSize) {
		_isFrame = true;
		isLocked = true;
		layout = new LogLayout;
		view = new View(to!Vec2u(newSize));
		view.position = Vec2f.zero;
		size(newSize);
		addChild(layout);
	}
}

class LogList: WidgetGroup {
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
        _slider.position = _position - Vec2f((_size.x - _slider.size.x) / 2f, 0f);
        _container.position = _position + Vec2f(_slider.size.x / 2f, 0f);
    }

    override void onSize() {
        _slider.size = Vec2f(10f, _size.y);
        _container.size = Vec2f(_size.x - _slider.size.x, _size.y);
        _container.view.renderSize = _container.size.to!Vec2u;
        onPosition();
    }

	override void update(float deltaTime) {
		_slider.update(deltaTime);
		float min = _container.view.size.y / 2f;
		float max = _container.layout.size.y - _container.view.size.y / 2f;
		float exceedingHeight = _container.layout.size.y - _container.view.size.y;

		if(exceedingHeight < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingHeight / (_container.view.size.y / 50f);
			_slider.step = to!uint(_slider.max);
		}
		_container.view.position = Vec2f(0f, lerp(min, max, _slider.offset));
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