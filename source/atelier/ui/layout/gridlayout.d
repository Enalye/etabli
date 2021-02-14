/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.layout.gridlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

/// Resize children to fit and align them on a grid.
class GridLayout : GuiElement {
    private {
        Vec2f _spacing = Vec2f.zero;
        Vec2u _capacity;
    }

    @property {
        Vec2f spacing() const {
            return _spacing;
        }

        Vec2f spacing(Vec2f newPadding) {
            _spacing = newPadding;
            resize();
            return _spacing;
        }

        Vec2u capacity() const {
            return _capacity;
        }

        Vec2u capacity(Vec2u newCapacity) {
            _capacity = newCapacity;
            resize();
            return _capacity;
        }
    }

    /// Ctor
    this() {
    }

    /// Ctor
    this(Vec2f newSize) {
        size = newSize;
    }

    override void appendChild(GuiElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendChild(gui);
        resize();
    }

    override void onSize() {
        resize();
    }

    protected void resize() {
        if (!_children.length || _capacity.x == 0u)
            return;

        int yCapacity = _capacity.y;
        if (yCapacity == 0u)
            yCapacity = (to!int(_children.length) / _capacity.x) + 1;

        Vec2f childSize = Vec2f(size.x / _capacity.x, size.y / yCapacity);
        foreach (size_t id, GuiElement gui; _children) {
            Vec2u coords = Vec2u(id % _capacity.x, cast(uint) id / _capacity.x);
            gui.position = Vec2f(childSize.x * coords.x, childSize.y * coords.y);
            gui.size = childSize - _spacing;
        }
    }
}
