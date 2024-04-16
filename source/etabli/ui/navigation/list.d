/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.navigation.list;

import etabli.common;
import etabli.core;
import etabli.input;
import etabli.render;
import etabli.ui.core;
import etabli.ui.scrollbar;

abstract class List : UIElement {
    protected {
        Scrollbar _scrollbar;
        ContentView _contentView;
        Rectangle _background;
    }

    this() {
        _background = Rectangle.fill(getSize());
        _background.color = Etabli.theme.background;
        _background.anchor = Vec2f.zero;
        addImage(_background);

        addEventListener("size", &_onSize);
    }

    void addList(UIElement element) {
        _contentView.addUI(element);
    }

    UIElement[] getList() {
        return _contentView.getChildren().array;
    }

    void clearList() {
        _contentView.clearUI();
        _contentView.setContentPosition(0f);
    }

    private void _onSize() {
        _background.size = getSize();
    }

    float getContentPosition() {
        return _contentView.getContentPosition();
    }

    void setContentPosition(float position) {
        _contentView.setContentPosition(position);
        _scrollbar.setContentPosition(_contentView.getContentPosition());
    }
}

final class HList : List {
    this(float scrollbarSize = 9f) {
        HContentView contentView = new HContentView;
        contentView.setAlign(UIAlignX.left, UIAlignY.top);
        contentView.setChildAlign(UIAlignY.top);
        addUI(contentView);

        _contentView = contentView;

        _scrollbar = new HScrollbar;
        _scrollbar.setAlign(UIAlignX.left, UIAlignY.bottom);
        _scrollbar.setHeight(scrollbarSize);
        addUI(_scrollbar);

        addEventListener("size", &_onSize);
        addEventListener("wheel", &_onWheel);
        _contentView.addEventListener("contentSize", &_onUpdateContent);
        _scrollbar.addEventListener("handlePosition", &_onHandlePosition);
    }

    private void _onSize() {
        _scrollbar.setWidth(getWidth());
        _contentView.setSize(getSize() - Vec2f(0f, _scrollbar.getHeight()));
        _scrollbar.isVisible = _contentView.getContentWidth() > getWidth();
    }

    private void _onUpdateContent() {
        _scrollbar.setContentSize(_contentView.getContentWidth());
        _scrollbar.isVisible = _contentView.getContentWidth() > getWidth();
    }

    private void _onHandlePosition() {
        _contentView.setContentPosition(_scrollbar.getContentPosition());
    }

    private void _onWheel() {
        _scrollbar.removeEventListener("handlePosition", &_onHandlePosition);

        InputEvent.MouseWheel ev = Etabli.ui.input.asMouseWheel();
        _contentView.setContentPosition(_contentView.getContentPosition() - ev.wheel.sum() * 32f);
        _scrollbar.setContentPosition(_contentView.getContentPosition());

        _scrollbar.addEventListener("handlePosition", &_onHandlePosition);
    }
}

final class VList : List {
    this(float scrollbarSize = 9f) {
        VContentView contentView = new VContentView;
        contentView.setAlign(UIAlignX.left, UIAlignY.top);
        contentView.setChildAlign(UIAlignX.left);
        addUI(contentView);

        _contentView = contentView;

        _scrollbar = new VScrollbar;
        _scrollbar.setAlign(UIAlignX.right, UIAlignY.top);
        _scrollbar.setWidth(scrollbarSize);
        addUI(_scrollbar);

        addEventListener("size", &_onSize);
        addEventListener("wheel", &_onWheel);
        _contentView.addEventListener("contentSize", &_onUpdateContent);
        _scrollbar.addEventListener("handlePosition", &_onHandlePosition);
    }

    private void _onSize() {
        _scrollbar.setHeight(getHeight());
        _contentView.setSize(getSize() - Vec2f(_scrollbar.getWidth(), 0f));
        _scrollbar.isVisible = _contentView.getContentHeight() > getHeight();
    }

    private void _onUpdateContent() {
        _scrollbar.setContentSize(_contentView.getContentHeight());
        _scrollbar.isVisible = _contentView.getContentHeight() > getHeight();
    }

    private void _onHandlePosition() {
        _contentView.setContentPosition(_scrollbar.getContentPosition());
    }

    private void _onWheel() {
        _scrollbar.removeEventListener("handlePosition", &_onHandlePosition);

        InputEvent.MouseWheel ev = Etabli.ui.input.asMouseWheel();
        _contentView.setContentPosition(_contentView.getContentPosition() - ev.wheel.sum() * 32f);
        _scrollbar.setContentPosition(_contentView.getContentPosition());

        _scrollbar.addEventListener("handlePosition", &_onHandlePosition);
    }
}
