/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.container.vcontainer;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

/// Vertical container. \
/// Align its elements vertically without changing their size. \
/// Resized automatically to fits its elements.
class VContainer : UIElement {
    protected {
        Vec2f _spacing = Vec2f.zero;
        GuiAlignX _nodeAlignX = GuiAlignX.center;
        float _minimalWidth = 0f;
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

        float minimalWidth() const {
            return _minimalWidth;
        }

        float minimalWidth(float newMinimalWidth) {
            _minimalWidth = newMinimalWidth;
            resize();
            return _minimalWidth;
        }
    }

    /// Ctor
    this() {
    }

    override void appendNode(UIElement gui) {
        gui.setAlign(_nodeAlignX, GuiAlignY.top);
        super.appendNode(gui);
        resize();
    }

    void setNodeAlign(GuiAlignX nodeAlignX) {
        _nodeAlignX = nodeAlignX;
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
        if (_isResizeCalled)
            return;
        _isResizeCalled = true;

        if (!_elements.length) {
            size = Vec2f.zero;
            _isResizeCalled = false;
            return;
        }

        Vec2f totalSize = Vec2f(_minimalWidth, 0f);
        foreach (UIElement gui; _elements) {
            totalSize.y += gui.scaledSize.y + _spacing.y;
            totalSize.x = max(totalSize.x, gui.scaledSize.x);
        }
        size = totalSize + Vec2f(_spacing.x * 2f, _spacing.y);
        Vec2f currentPosition = _spacing;
        foreach (UIElement gui; _elements) {
            gui.setAlign(_nodeAlignX, GuiAlignY.top);
            gui.position = currentPosition;
            currentPosition = currentPosition + Vec2f(0f, gui.scaledSize.y + _spacing.y);
        }
        _isResizeCalled = false;
    }
}
