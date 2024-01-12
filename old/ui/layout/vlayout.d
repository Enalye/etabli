/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.layout.vlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

/// Resize elements to fit and align them vertically.
class VLayout : UIElement {
    private {
        Vec2f _spacing = Vec2f.zero;
        uint _capacity;
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

        uint capacity() const {
            return _capacity;
        }

        uint capacity(uint newCapacity) {
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
        if (!_elements.length)
            return;
        const Vec2f nodeSize = Vec2f(size.x, size.y / (_capacity != 0u
                ? _capacity : _elements.length));
        foreach (size_t id, UIElement gui; _elements) {
            gui.position = origin + Vec2f(0f, nodeSize.y * to!float(id));
            gui.size = nodeSize - _spacing;
        }
    }
}
