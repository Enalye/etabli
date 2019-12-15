
/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.layout.loglayout;

import std.conv: to;
import std.algorithm.comparison: max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

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