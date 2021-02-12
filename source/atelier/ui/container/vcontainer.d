/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.container.vcontainer;

import std.conv: to;
import std.algorithm.comparison: max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

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

	override void appendChild(GuiElement gui) {
        gui.setAlign(_childAlignX, GuiAlignY.top);
		super.appendChild(gui);
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
        _isResizeCalled = false;
	}
}