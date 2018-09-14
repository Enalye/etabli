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

module ui.layout;

import std.conv: to;
import std.algorithm.comparison: max;

import render.window;
import core.all;
import ui.widget;

import common.all;

class VLayout: WidgetGroup {
	private {
		Vec2f _spacing = Vec2f.zero;
		uint _capacity;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }

		uint capacity() const { return _capacity; }
		uint capacity(uint newCapacity) { _capacity = newCapacity; resize(); return _capacity; }
	}

	this() {}

	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChild(Widget widget) {
		super.addChild(widget);
		resize();
	}

    override void onSize() {
        resize();
    }

	protected void resize() {
		if(!_children.length)
			return;
		Vec2f childSize = Vec2f(_size.x, _size.y / (_capacity != 0u ? _capacity : _children.length));
		Vec2f origin = (_isFrame ? Vec2f.zero : _position) - _size / 2 + childSize / 2f;
		foreach(uint id, Widget widget; _children) {
			widget.position = origin + Vec2f(0f, childSize.y * to!float(id));
			widget.size = childSize - _spacing;
		}
	}
}

class HLayout: WidgetGroup {
	private {
		Vec2f _spacing = Vec2f.zero;
		uint _capacity;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }

		uint capacity() const { return _capacity; }
		uint capacity(uint newCapacity) { _capacity = newCapacity; resize(); return _capacity; }
	}

	this() {}

	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChild(Widget widget) {
		super.addChild(widget);
		resize();
	}

    override void onSize() {
        resize();
    }

	protected void resize() {
		if(!_children.length)
			return;
		Vec2f childSize = Vec2f(_size.x / (_capacity != 0u ? _capacity : _children.length), _size.y);
		Vec2f origin = (_isFrame ? Vec2f.zero : _position) - _size / 2 + childSize / 2f;
		foreach(uint id, Widget widget; _children) {
			widget.position = origin + Vec2f(childSize.x * to!float(id), 0f);
			widget.size = childSize - _spacing;
		}
	}
}

class GridLayout: WidgetGroup {
	private {
		Vec2f _spacing = Vec2f.zero;
		Vec2u _capacity;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }

		Vec2u capacity() const { return _capacity; }
		Vec2u capacity(Vec2u newCapacity) { _capacity = newCapacity; resize(); return _capacity; }
	}

	this() {}

	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChild(Widget widget) {
		super.addChild(widget);
		resize();
	}

    override void onSize() {
        resize();
    }

	protected void resize() {
		if(!_children.length || _capacity.x == 0u)
			return;

		int yCapacity = _capacity.y;
		if(yCapacity == 0u)
			yCapacity = (to!int(_children.length) / _capacity.x) + 1;

		Vec2f childSize = Vec2f(_size.x / _capacity.x, _size.y / yCapacity);
		Vec2f origin = (_isFrame ? Vec2f.zero : _position) - _size / 2 + childSize / 2f;
		foreach(uint id, Widget widget; _children) {
			Vec2u coords = Vec2u(id % _capacity.x, id / _capacity.x);
			widget.position = origin + Vec2f(childSize.x * coords.x, childSize.y * coords.y);
			widget.size = childSize - _spacing;
		}
	}
}

class VContainer: WidgetGroup {
	protected {
		Vec2f _spacing = Vec2f.zero;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }
	}

	this() {}

	override void addChild(Widget widget) {
		super.addChild(widget);
		resize();
	}

    override void onPosition() {
        resize();
    }

    override void onSize() {
        resize();
    }

    override void onAnchor() {
        resize();
    }

	protected void resize() {
		if(!_children.length) {
			_size = Vec2f.zero;
			return;
		}

		Vec2f totalSize = Vec2f.zero;
		foreach(Widget widget; _children) {
			totalSize.y += widget.size.y + _spacing.y;
			totalSize.x = max(totalSize.x, widget.size.x);
		}
		_size = totalSize + Vec2f(_spacing.x * 2f, _spacing.y);
		Vec2f currentPosition = _position - (_size * _anchor) + _spacing;
		foreach(Widget widget; _children) {
			widget.position = currentPosition + widget.size / 2f;
			currentPosition = currentPosition + Vec2f(0f, widget.size.y + _spacing.y);
		}
	}
}

class HContainer: WidgetGroup {
	protected {
		Vec2f _spacing = Vec2f.zero;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }
	}

	this() {}

	override void addChild(Widget widget) {
		super.addChild(widget);
		resize();
	}

    override void onPosition() {
        resize();
    }

    override void onSize() {
        resize();
    }

    override void onAnchor() {
        resize();
    }

	protected void resize() {
		if(!_children.length) {
			_size = Vec2f.zero;
			return;
		}

		Vec2f totalSize = Vec2f.zero;
		foreach(Widget widget; _children) {
			totalSize.y = max(totalSize.y, widget.size.y);
			totalSize.x += widget.size.x + _spacing.x;
		}
		_size = totalSize + Vec2f(_spacing.x, _spacing.y * 2f);
		Vec2f currentPosition = _position - (_size * _anchor) + _spacing;
		foreach(Widget widget; _children) {
			widget.position = currentPosition + widget.size / 2f;
			currentPosition = currentPosition + Vec2f(widget.size.x + _spacing.x, 0f);
		}
	}
}

class AnchoredLayout: WidgetGroup {
	private {
		Vec2f[] _childrenPositions, _childrenSizes;
	}

	this() {}

	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChild(Widget widget) {
		super.addChild(widget);
		_childrenPositions ~= Vec2f.half;
		_childrenSizes ~= Vec2f.one;
		resize();
	}

    override void onPosition() {
        resize();
    }

    override void onSize() {
        resize();
    }

	void addChild(Widget widget, Vec2f position, Vec2f size) {
		super.addChild(widget);
		_childrenPositions ~= position;
		_childrenSizes ~= size;
		resize();
	}

	override void removeChildren() {
		super.removeChildren();
		_childrenPositions.length = 0L;
		_childrenSizes.length = 0L;
	}

	protected void resize() {
		if(!_children.length)
			return;
		Vec2f origin = (_isFrame ? Vec2f.zero : _position) - _size / 2;
		foreach(uint id, Widget widget; _children) {
			widget.position = origin + _size * _childrenPositions[id];
			widget.size = _size * _childrenSizes[id];
		}
	}
}

class LogLayout: WidgetGroup {
	this() {}

	override void addChild(Widget widget) {
		super.addChild(widget);
		resize();
	}

    override void onSize() {
        resize();
    }

	protected void resize() {
		if(!_children.length)
			return;

		Vec2f totalSize = Vec2f.zero;
		foreach(Widget widget; _children) {
			totalSize.y += widget.size.y;
			totalSize.x = max(totalSize.x, widget.size.x);
		}
		_size = totalSize;
		Vec2f currentPosition = _position - _size / 2f;
		foreach(Widget widget; _children) {
			widget.position = currentPosition + widget.size / 2f;
			currentPosition = currentPosition + Vec2f(0f, widget.size.y);
		}
	}
}