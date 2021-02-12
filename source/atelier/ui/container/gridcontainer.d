/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.container.gridcontainer;

import std.conv: to;
import std.algorithm.comparison: max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

/// Grid container. \
/// Align its children left-to-right then top-to-bottom without changing their size. \
/// Resized automatically to fits its children.
class GridContainer: GuiElement {
	protected {
		Vec2f _spacing = Vec2f.zero;
        uint _maxElementsPerLine = 4u;
	}

	@property {
        /// Space between each child.
		Vec2f spacing() const { return _spacing; }
        /// Ditto
		Vec2f spacing(Vec2f newPadding) { _spacing = newPadding; resize(); return _spacing; }

        /// The number of children per line.
        uint maxElementsPerLine() const { return _maxElementsPerLine; }
        /// Ditto
		uint maxElementsPerLine(uint maxElementsPerLine_) { _maxElementsPerLine = maxElementsPerLine_; resize(); return _maxElementsPerLine; }
	}

	/// Ctor
	this() {}

	override void appendChild(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
		super.appendChild(gui);
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
        Vec2f[] lineSizes;
        uint xCount, i;
        Vec2f lineSize = Vec2f.zero, totalSize = Vec2f.zero;
		foreach(GuiElement gui; _children) {
			lineSize.x += gui.scaledSize.x + _spacing.x;
			lineSize.y = max(lineSize.y, gui.scaledSize.y);
            xCount ++;
            i ++;
            if(xCount == _maxElementsPerLine || i == _children.length) {
                lineSizes ~= lineSize;
                totalSize.x = max(totalSize.x, lineSize.x);
                totalSize.y += lineSize.y + _spacing.y;
                lineSize = Vec2f.zero;
                xCount = 0u;
            }
		}
		size = totalSize + _spacing;
		Vec2f currentPosition = _spacing;
        xCount = 0u;
        uint yCount;
		foreach(GuiElement gui; _children) {
            gui.setAlign(GuiAlignX.left, GuiAlignY.top);
			gui.position = currentPosition;
			currentPosition += Vec2f(gui.scaledSize.x + _spacing.x, 0f);
            xCount ++;
            if(xCount == _maxElementsPerLine) {
                currentPosition.x = _spacing.x;
                currentPosition.y += lineSizes[yCount].y + _spacing.y;
                yCount ++;
                xCount = 0u;
            }
		}
        _isResizeCalled = false;
	}
}