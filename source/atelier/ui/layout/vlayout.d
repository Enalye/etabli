
/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.layout.vlayout;

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