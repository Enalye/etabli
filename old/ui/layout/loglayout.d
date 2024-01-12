/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.layout.loglayout;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

class LogLayout : UIElement {
    this() {
    }

    override void appendNode(UIElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendNode(gui);
        resize();
    }

    override void onSize() {
        resize();
    }

    private bool isResizeCalled;
    protected void resize() {
        if (isResizeCalled)
            return;
        isResizeCalled = true;

        if (!_elements.length) {
            isResizeCalled = false;
            return;
        }

        Vec2f totalSize = Vec2f.zero;
        foreach (UIElement gui; _elements) {
            totalSize.y += gui.scaledSize.y;
            totalSize.x = max(totalSize.x, gui.scaledSize.x);
        }
        size = totalSize;
        Vec2f currentPosition = origin;
        foreach (UIElement gui; _elements) {
            gui.position = currentPosition + gui.scaledSize / 2f;
            currentPosition = currentPosition + Vec2f(0f, gui.scaledSize.y);
        }

        isResizeCalled = false;
    }
}
