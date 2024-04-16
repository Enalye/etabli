/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.core.box;

import etabli.common;
import etabli.render;
import etabli.ui.core.element;

abstract class Box : UIElement {
    private {
        Vec2f _padding = Vec2f.zero;
        Vec2f _margin = Vec2f.zero;
        float _spacing = 0f;
    }

    final Vec2f getPadding() const {
        return _padding;
    }

    final void setPadding(Vec2f padding) {
        _padding = padding;
    }

    final Vec2f getMargin() const {
        return _margin;
    }

    final void setMargin(Vec2f margin) {
        _margin = margin;
    }

    final float getSpacing() const {
        return _spacing;
    }

    final void setSpacing(float spacing) {
        _spacing = spacing;
    }
}

final class HBox : Box {
    private {
        UIAlignY _childAlign = UIAlignY.center;
    }

    this() {
        addEventListener("update", &_onUpdate);
    }

    void setChildAlign(UIAlignY align_) {
        _childAlign = align_;
    }

    UIAlignY getChildAlign() const {
        return _childAlign;
    }

    private void _onUpdate() {
        Vec2f newSize = Vec2f(_margin.x, _padding.y);

        foreach (UIElement child; getChildren()) {
            child.setAlign(UIAlignX.left, _childAlign);
            child.setPosition(Vec2f(newSize.x, _margin.y));
            newSize.x += child.getWidth() + _spacing;
            newSize.y = max(newSize.y, child.getHeight() + _margin.y * 2f);
        }
        newSize.x = max(_padding.x, newSize.x + _margin.x);

        setSize(newSize);
    }
}

final class VBox : Box {
    private {
        UIAlignX _childAlign = UIAlignX.center;
    }

    this() {
        addEventListener("update", &_onUpdate);
    }

    void setChildAlign(UIAlignX align_) {
        _childAlign = align_;
    }

    UIAlignX getChildAlign() const {
        return _childAlign;
    }

    private void _onUpdate() {
        Vec2f newSize = Vec2f(_padding.x, _margin.y);

        foreach (UIElement child; getChildren()) {
            child.setAlign(_childAlign, UIAlignY.top);
            child.setPosition(Vec2f(_margin.x, newSize.y));
            newSize.y += child.getHeight() + _spacing;
            newSize.x = max(newSize.x, child.getWidth() + _margin.x * 2f);
        }
        newSize.y = max(_padding.y, newSize.y + _margin.y);

        setSize(newSize);
    }
}
