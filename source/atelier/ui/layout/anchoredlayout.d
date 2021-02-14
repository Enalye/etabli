/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.layout.anchoredlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

class AnchoredLayout : GuiElement {
    private {
        Vec2f[] _childrenPositions, _childrenSizes;
    }

    /// Ctor
    this() {
    }

    /// Ctor
    this(Vec2f newSize) {
        size = newSize;
    }

    override void appendChild(GuiElement gui) {
        super.appendChild(gui);
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

    void appendChild(GuiElement gui, Vec2f position, Vec2f size) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendChild(gui);
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
        if (!_children.length)
            return;
        foreach (size_t id, GuiElement gui; _children) {
            gui.position = size * _childrenPositions[id];
            gui.size = size * _childrenSizes[id];
        }
    }
}
