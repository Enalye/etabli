/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.layout.gridlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

/// Resize elements to fit and align them on a grid.
class GridLayout : UIElement {
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

    override void appendNode(UIElement gui) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendNode(gui);
        resize();
    }

    override void onSize() {
        resize();
    }

    protected void resize() {
        if (!_elements.length || _capacity.x == 0u)
            return;

        int yCapacity = _capacity.y;
        if (yCapacity == 0u)
            yCapacity = (to!int(_elements.length) / _capacity.x) + 1;

        Vec2f nodeSize = Vec2f(size.x / _capacity.x, size.y / yCapacity);
        foreach (size_t id, UIElement gui; _elements) {
            Vec2u coords = Vec2u(id % _capacity.x, cast(uint) id / _capacity.x);
            gui.position = Vec2f(nodeSize.x * coords.x, nodeSize.y * coords.y);
            gui.size = nodeSize - _spacing;
        }
    }
}
