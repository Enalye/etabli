/**
    Layout

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.layout;

import std.conv: to;
import std.algorithm.comparison: max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

/// Resize children to fit and align them vertically.
class VLayout: GuiElement {
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

	/// Ctor
	this() {}

	/// Ctor
	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChildGui(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
		super.addChildGui(gui);
		resize();
	}

    override void onSize() {
        resize();
    }

	protected void resize() {
		if(!_children.length)
			return;
		const Vec2f childSize = Vec2f(size.x, size.y / (_capacity != 0u ? _capacity : _children.length));
		foreach(size_t id, GuiElement gui; _children) {
			gui.position = origin + Vec2f(0f, childSize.y * to!float(id));
			gui.size = childSize - _spacing;
		}
	}
}

/// Resize children to fit and align them horizontally.
class HLayout: GuiElement {
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

	/// Ctor
	this() {}

	/// Ctor
	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChildGui(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
		super.addChildGui(gui);
		resize();
	}

    override void onSize() {
        resize();
    }

	protected void resize() {
		if(!_children.length)
			return;
		Vec2f childSize = Vec2f(size.x / (_capacity != 0u ? _capacity : _children.length), size.y);
		foreach(size_t id, GuiElement gui; _children) {
			gui.position = Vec2f(childSize.x * to!float(id), 0f);
			gui.size = childSize - _spacing;
		}
	}
}

/// Resize children to fit and align them on a grid.
class GridLayout: GuiElement {
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

	/// Ctor
	this() {}

	/// Ctor
	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChildGui(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
		super.addChildGui(gui);
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

		Vec2f childSize = Vec2f(size.x / _capacity.x, size.y / yCapacity);
		foreach(size_t id, GuiElement gui; _children) {
			Vec2u coords = Vec2u(id % _capacity.x, cast(uint)id / _capacity.x);
			gui.position = Vec2f(childSize.x * coords.x, childSize.y * coords.y);
			gui.size = childSize - _spacing;
		}
	}
}

/// Vertical container. \
/// Align its children vertically without changing their size. \
/// Resized automatically to fits its children.
class VContainer: GuiElement {
	protected {
		Vec2f _spacing = Vec2f.zero;
		GuiAlignX _childAlignX = GuiAlignX.center;
        float _minimalWidth = 0f;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }

        float minimalWidth() const { return _minimalWidth; }
		float minimalWidth(float newMinimalWidth) { _minimalWidth = newMinimalWidth; resize(); return _minimalWidth; }
	}

	/// Ctor
	this() {}

	override void addChildGui(GuiElement gui) {
        gui.setAlign(_childAlignX, GuiAlignY.top);
		super.addChildGui(gui);
		resize();
	}

    void setChildAlign(GuiAlignX childAlignX) {
        _childAlignX = childAlignX;
        resize();
    }

    override void update(float deltatime) {
        resize();
    }

    override void onSize() {
        resize();
    }

    private bool isResizeCalled;
	protected void resize() {
        if(isResizeCalled)
            return;
        isResizeCalled = true;

		if(!_children.length) {
			size = Vec2f.zero;
            isResizeCalled = false;
			return;
		}

		Vec2f totalSize = Vec2f(_minimalWidth, 0f);
		foreach(GuiElement gui; _children) {
			totalSize.y += gui.scaledSize.y + _spacing.y;
			totalSize.x = max(totalSize.x, gui.scaledSize.x);
		}
		size = totalSize + Vec2f(_spacing.x * 2f, _spacing.y);
		Vec2f currentPosition = _spacing;
		foreach(GuiElement gui; _children) {
            gui.setAlign(_childAlignX, GuiAlignY.top);
			gui.position = currentPosition;
			currentPosition = currentPosition + Vec2f(0f, gui.scaledSize.y + _spacing.y);
		}
        isResizeCalled = false;
	}
}

/// Horizontal container. \
/// Align its children horizontally without changing their size. \
/// Resized automatically to fits its children.
class HContainer: GuiElement {
	protected {
		Vec2f _spacing = Vec2f.zero;
		GuiAlignY _childAlignY = GuiAlignY.center;
        float _minimalHeight = 0f;
	}

	@property {
		Vec2f spacing() const { return _spacing; }
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }
	
        float minimalHeight() const { return _minimalHeight; }
		float minimalHeight(float newMinimalHeight) { _minimalHeight = newMinimalHeight; resize(); return _minimalHeight; }
    }

	/// Ctor
	this() {}

	override void addChildGui(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, _childAlignY);
		super.addChildGui(gui);
		resize();
	}

    void setChildAlign(GuiAlignY childAlignY) {
        _childAlignY = childAlignY;
        resize();
    }

    override void update(float deltatime) {
        resize();
    }

    override void onSize() {
        resize();
    }

	private bool isResizeCalled;
	protected void resize() {
        if(isResizeCalled)
            return;
        isResizeCalled = true;

		if(!_children.length) {
			size = Vec2f.zero;
            isResizeCalled = false;
			return;
		}

		Vec2f totalSize = Vec2f(0f, _minimalHeight);
		foreach(GuiElement gui; _children) {
			totalSize.y = max(totalSize.y, gui.scaledSize.y);
			totalSize.x += gui.scaledSize.x + _spacing.x;
		}
		size = totalSize + Vec2f(_spacing.x, _spacing.y * 2f);
		Vec2f currentPosition = _spacing;
		foreach(GuiElement gui; _children) {
            gui.setAlign(GuiAlignX.left, _childAlignY);
			gui.position = currentPosition;
			currentPosition = currentPosition + Vec2f(gui.scaledSize.x + _spacing.x, 0f);
		}
        isResizeCalled = false;
	}
}

class AnchoredLayout: GuiElement {
	private {
		Vec2f[] _childrenPositions, _childrenSizes;
	}

	/// Ctor
	this() {}

	/// Ctor
	this(Vec2f newSize) {
		size = newSize;
	}

	override void addChildGui(GuiElement gui) {
		super.addChildGui(gui);
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

	void addChildGui(GuiElement gui, Vec2f position, Vec2f size) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
		super.addChildGui(gui);
		_childrenPositions ~= position;
		_childrenSizes ~= size;
		resize();
	}

	override void removeChildrenGuis() {
		super.removeChildrenGuis();
		_childrenPositions.length = 0L;
		_childrenSizes.length = 0L;
	}

	protected void resize() {
		if(!_children.length)
			return;
		foreach(size_t id, GuiElement gui; _children) {
			gui.position = size * _childrenPositions[id];
			gui.size = size * _childrenSizes[id];
		}
	}
}

class LogLayout: GuiElement {
	this() {}

	override void addChildGui(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
		super.addChildGui(gui);
		resize();
	}

    override void onSize() {
        resize();
    }

	private bool isResizeCalled;
	protected void resize() {
        if(isResizeCalled)
            return;
        isResizeCalled = true;

		if(!_children.length) {
            isResizeCalled = false;
			return;
        }

		Vec2f totalSize = Vec2f.zero;
		foreach(GuiElement gui; _children) {
			totalSize.y += gui.scaledSize.y;
			totalSize.x = max(totalSize.x, gui.scaledSize.x);
		}
		size = totalSize;
		Vec2f currentPosition = origin;
		foreach(GuiElement gui; _children) {
			gui.position = currentPosition + gui.scaledSize / 2f;
			currentPosition = currentPosition + Vec2f(0f, gui.scaledSize.y);
		}

        isResizeCalled = false;
	}
}