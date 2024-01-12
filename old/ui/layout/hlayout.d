/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.layout.hlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

/// Resize elements to fit and align them horizontally.
class HLayout : UIElement {
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

    override void appendNode(UIElement node) {
        node.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendNode(node);
        resize();
    }

    override void prependNode(UIElement node) {
        node.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.prependNode(node);
        resize();
    }

    override void onSize() {
        resize();
    }

    protected void resize() {
        if (!_elements.length)
            return;
        Vec2f nodeSize = Vec2f(size.x / (_capacity != 0u ? _capacity : _elements.length), size.y);
        foreach (size_t id, UIElement node; _elements) {
            node.position = Vec2f(nodeSize.x * to!float(id), 0f);
            node.size = nodeSize - _spacing;
        }
    }
}
