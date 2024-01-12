/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.container.hcontainer;

import std.conv : to;
import std.algorithm.comparison : max;
import etabli.render, etabli.core, etabli.common;
import etabli.ui.gui_element;

/// Horizontal container. \
/// Align its elements horizontally without changing their size. \
/// Resized automatically to fits its elements.
class HContainer : UIElement {
    protected {
        Vec2f _spacing = Vec2f.zero;
        GuiAlignY _nodeAlignY = GuiAlignY.center;
        float _minimalHeight = 0f;
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

        float minimalHeight() const {
            return _minimalHeight;
        }

        float minimalHeight(float newMinimalHeight) {
            _minimalHeight = newMinimalHeight;
            resize();
            return _minimalHeight;
        }
    }

    /// Ctor
    this() {
    }

    override void appendNode(UIElement gui) {
        gui.setAlign(GuiAlignX.left, _nodeAlignY);
        super.appendNode(gui);
        resize();
    }

    void setNodeAlign(GuiAlignY nodeAlignY) {
        _nodeAlignY = nodeAlignY;
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

        Vec2f totalSize = Vec2f(0f, _minimalHeight);
        foreach (UIElement gui; _elements) {
            totalSize.y = max(totalSize.y, gui.scaledSize.y);
            totalSize.x += gui.scaledSize.x + _spacing.x;
        }
        size = totalSize + Vec2f(_spacing.x, _spacing.y * 2f);
        Vec2f currentPosition = _spacing;
        foreach (UIElement gui; _elements) {
            gui.setAlign(GuiAlignX.left, _nodeAlignY);
            gui.position = currentPosition;
            currentPosition = currentPosition + Vec2f(gui.scaledSize.x + _spacing.x, 0f);
        }
        _isResizeCalled = false;
    }
}
