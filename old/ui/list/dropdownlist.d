/**
    Dropdown list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.ui.list.dropdownlist;

import std.conv : to;
import std.algorithm : min, max;
import etabli.core, etabli.render, etabli.common;
import etabli.ui.gui_element, etabli.ui.gui_overlay, etabli.ui.list.vlist,
    etabli.ui.label, etabli.ui.button;

private class DropDownListCancelTrigger : UIElement {
    override void onSubmit() {
        triggerCallback();
    }
}

private class DropDownListSubElement : Button {
    Label label;

    this(string title, Vec2f sz) {
        size = sz;
        label = new Label(title);
        label.setAlign(GuiAlignX.center, GuiAlignY.center);
        if ((label.size.x + 20) > size.x) {
            size = Vec2f(label.size.x + 20, size.y);
        }
        appendNode(label);
    }

    override void draw() {
        drawFilledRect(origin, size, isHovered ? Color.gray : Color.black);
    }
}

/// A clickable button that deploy a list of choices.
class DropDownList : UIElement {
    private {
        VList _list;
        Label _label;
        DropDownListCancelTrigger _cancelTrigger;
        bool _isUnrolled = false;
        uint _maxListLength = 5;
        float _maxWidth = 5f;
        Timer _timer;
    }

    @property {
        /// The ID of the currently selected node.
        uint selected() const {
            return _list.selected;
        }
        /// Ditto
        uint selected(uint id) {
            return _list.selected = id;
        }

        /// The list of all its elements.
        override const(UIElement[]) elements() const {
            return _list.elements;
        }
        /// Ditto
        override UIElement[] elements() {
            return _list.elements;
        }

        /// Return the first node gui.
        override UIElement firstNode() {
            return _list.firstNode;
        }

        /// Return the last node gui.
        override UIElement lastNode() {
            return _list.lastNode;
        }

        /// The number of elements it currently has.
        override size_t nodeCount() const {
            return _list.nodeCount;
        }
    }

    /// Size is used for the canvas, avoid resizing too often. \
    /// maxListLength is the maximum number of choices that can be displayed at the same time.
    this(Vec2f newSize, uint maxListLength = 5U) {
        _maxListLength = maxListLength;
        size = newSize;
        hasCanvas(true);
        _maxWidth = max(size.x, _maxWidth);

        _list = new VList(Vec2f(_maxWidth, _maxListLength * size.x));
        _list.setAlign(GuiAlignX.left, GuiAlignY.top);

        _cancelTrigger = new DropDownListCancelTrigger;
        _cancelTrigger.setAlign(GuiAlignX.left, GuiAlignY.top);
        _cancelTrigger.size = size;
        _cancelTrigger.setCallback(this, "cancel");

        _label = new Label;
        _label.setAlign(GuiAlignX.center, GuiAlignY.center);

        _timer.mode = Timer.Mode.bounce;
        _timer.start(2f);
        super.appendNode(_label);
    }

    override void onSubmit() {
        if (!isLocked) {
            _isUnrolled = !_isUnrolled;

            if (_isUnrolled) {
                setOverlay(_cancelTrigger);
                setOverlay(_list);
            }
            else {
                stopOverlay();
                triggerCallback();
            }
        }
    }

    override void onCallback(string id) {
        if (id == "cancel") {
            _isUnrolled = false;
            stopOverlay();
            triggerCallback();
        }
    }

    override void update(float deltaTime) {
        _timer.update(deltaTime);
        if (_label.size.x > size.x) {
            _label.setAlign(GuiAlignX.left, GuiAlignY.center);
            _label.position = Vec2f(lerp(-(_label.size.x - size.x), 0f,
                    easeInOutSine(_timer.value01)), 0f);
        }
        else {
            _label.setAlign(GuiAlignX.center, GuiAlignY.center);
            _label.position = Vec2f.zero;
        }

        if (_isUnrolled) {
            _list.update(deltaTime);
        }
    }

    override void drawOverlay() {
        if (_isUnrolled) {
            _cancelTrigger.position = origin;
            _list.position = origin + Vec2f(0f, _size.y);

            int id;
            foreach (gui; _list.elements) {
                if (gui.hasFocus) {
                    _isUnrolled = false;
                    selected = id;

                    stopOverlay();
                    triggerCallback();
                }
                id++;
            }
        }
    }

    override void draw() {
        super.draw();
        auto guis = _list.elements;
        if (guis.length > _list.selected) {
            auto gui = cast(DropDownListSubElement)(guis[_list.selected]);
            _label.text = gui.label.text;
        }
        drawFilledRect(origin, size, Color.black);
        drawRect(origin, size, Color.white);
    }

    protected override void appendNode(UIElement gui) {
        float width = size.x;
        _list.appendNode(gui);
        auto guis = _list.elements;
        foreach (node; guis) {
            width = max(node.size.x, width);
        }
        foreach (node; guis) {
            node.size = Vec2f(width, node.size.y);
        }
        _list.size = Vec2f(width, min(_maxListLength, guis.length) * size.y);
    }

    /// Add a choice to the list. \
    /// Use this instead of appendNode unless you want to define your own.
    void add(string msg) {
        auto gui = new DropDownListSubElement(msg, size);
        appendNode(gui);
    }

    override void removeElements() {
        _list.removeElements();
    }

    override void removeNode(size_t id) {
        _list.removeNode(id);
    }

    override void removeNode(UIElement gui) {
        _list.removeNode(gui);
    }

    /// Returns the name of the selected choice.
    string getSelectedName() {
        auto list = cast(DropDownListSubElement[]) elements;
        if (selected() >= list.length)
            return "";
        return list[selected()].label.text;
    }

    /// Change the name of the selected choice.
    void setSelectedName(string name) {
        auto list = cast(DropDownListSubElement[]) elements;
        int i;
        foreach (btn; list) {
            if (btn.label.text == name) {
                selected(i);
                triggerCallback();
                return;
            }
            i++;
        }
    }
}
