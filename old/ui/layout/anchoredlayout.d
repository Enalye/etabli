/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.layout.anchoredlayout;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

class AnchoredLayout : UIElement {
    private {
        Vec2f[] _elementsPositions, _elementsSizes;
    }

    /// Ctor
    this() {
    }

    /// Ctor
    this(Vec2f newSize) {
        size = newSize;
    }

    override void appendNode(UIElement gui) {
        super.appendNode(gui);
        _elementsPositions ~= Vec2f.half;
        _elementsSizes ~= Vec2f.one;
        resize();
    }

    override void onPosition() {
        resize();
    }

    override void onSize() {
        resize();
    }

    void appendNode(UIElement gui, Vec2f position, Vec2f size) {
        gui.setAlign(GuiAlignX.left, GuiAlignY.top);
        super.appendNode(gui);
        _elementsPositions ~= position;
        _elementsSizes ~= size;
        resize();
    }

    override void removeElements() {
        super.removeElements();
        _elementsPositions.length = 0L;
        _elementsSizes.length = 0L;
    }

    protected void resize() {
        if (!_elements.length)
            return;
        foreach (size_t id, UIElement gui; _elements) {
            gui.position = size * _elementsPositions[id];
            gui.size = size * _elementsSizes[id];
        }
    }
}
