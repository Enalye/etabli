/**
    Grid list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.gridlist;

import std.conv: to;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.slider;

private class GridContainer: GuiElementCanvas {
	public {
		GridLayout layout;
	}

	this(Vec2f newSize) {
		isLocked = true;
		layout = new GridLayout;
		size(newSize);
		addChildGui(layout);
	}
}

class GridList: GuiElement {
	protected {
		GridContainer _container;
		Slider _slider;
		Vec2f _lastMousePos = Vec2f.zero;
		float _layoutLength = 74f;
		uint _nbElements = 0u;
		uint _idElementSelected = 0u;
		uint _nbElementsPerLine = 4u;
	}

	@property {
		uint selected() const { return _idElementSelected; }
		uint selected(uint id) {
			if(id > _nbElements)
				throw new Exception("GridList: index out of bounds");
			_idElementSelected = id;
			return _idElementSelected;
		}
	}

	this(Vec2f size) {
		createGui(size);
	}

	override void onEvent(Event event) {
		super.onEvent(event);
		if(event.type == EventType.MouseDown || event.type == EventType.MouseUp || event.type == EventType.MouseUpdate) {
			if(_slider.isInside(event.position))
				_slider.onEvent(event);
			else if(event.type == EventType.MouseDown) {

				auto widgets = _container.layout.children;
				foreach(size_t id, ref GuiElement widget; _container.layout.children) {
					widget.isSelected = false;
					if(widget.isHovered)
						_idElementSelected = cast(uint)id;
				}
				if(_idElementSelected < widgets.length)
					widgets[_idElementSelected].isSelected = true;
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
			_container.layout.capacity = Vec2u(_nbElementsPerLine, 0u);
			_container.layout.size = Vec2f(size.x, _layoutLength * (_nbElements / _nbElementsPerLine));
			_container.size = Vec2f(size.x - _slider.size.x, size.y);
			_container.canvas.renderSize = _container.size.to!Vec2u;
			onPosition();
		}

	override void update(float deltaTime) {
		super.update(deltaTime);
		float min = _container.canvas.size.y / 2f;
		float max = _container.layout.size.y - _container.canvas.size.y / 2f;
		float exceedingHeight = _container.layout.size.y - _container.canvas.size.y;

		if(exceedingHeight < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingHeight / _layoutLength;
			_slider.step = to!uint(_slider.max);
		}
		_container.canvas.position = Vec2f(0f, lerp(min, max, _slider.offset));
	}

	override void addChildGui(GuiElement widget) {
		widget.isSelected = (_nbElements == 0u);

		_nbElements ++;
		_container.layout.size = Vec2f(size.x, _layoutLength * (_nbElements / _nbElementsPerLine));
		_container.layout.position = Vec2f(0f, _container.layout.size.y / 2f);
		_container.layout.addChildGui(widget);
	}

	override void removeChildrenGuis() {
		_nbElements = 0u;
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(size.x, 0f);
		_container.layout.position = Vec2f.zero;
		_container.layout.removeChildrenGuis();
	}

	override void removeChildGui(uint id) {
		_container.layout.removeChildGui(id);
		_nbElements = _container.layout.getChildrenGuisCount();
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(size.x, _layoutLength * (_nbElements / _nbElementsPerLine));
		_container.layout.position = Vec2f(0f, _container.layout.size.y / 2f);
	}

	override int getChildrenGuisCount() {
		return _container.layout.getChildrenGuisCount();
	}

	GuiElement[] getList() {
		return _container.layout.children;
	}

	protected void createGui(Vec2f newSize) {
		isLocked = true;
		_slider = new VScrollbar;
		_container = new GridContainer(newSize);

		super.addChildGui(_slider);
		super.addChildGui(_container);

		size(newSize);
		position(Vec2f.zero);
	}
}

