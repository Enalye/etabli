/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.container.hcontainer;

import std.conv: to;
import std.algorithm.comparison: max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

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

	override void appendChild(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, _childAlignY);
		super.appendChild(gui);
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

	private bool _isResizeCalled;
	protected void resize() {
        if(_isResizeCalled)
            return;
        _isResizeCalled = true;

		if(!_children.length) {
			size = Vec2f.zero;
            _isResizeCalled = false;
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
        _isResizeCalled = false;
	}
}