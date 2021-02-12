/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.layout.hlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import atelier.render, atelier.core, atelier.common;
import atelier.ui.gui_element;

/// Resize children to fit and align them horizontally.
class HLayout : GuiElement {
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

    override void appendChild(GuiElement child) {
        child.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendChild(child);
        resize();
    }

    override void prependChild(GuiElement child) {
        child.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.prependChild(child);
        resize();
    }

    override void onSize() {
        resize();
    }

    protected void resize() {
        if (!_children.length)
            return;
        Vec2f childSize = Vec2f(size.x / (_capacity != 0u ? _capacity : _children.length), size.y);
        foreach (size_t id, GuiElement child; _children) {
            child.position = Vec2f(childSize.x * to!float(id), 0f);
            child.size = childSize - _spacing;
        }
    }
}
