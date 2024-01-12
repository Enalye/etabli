/**
    Vertical list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.ui.list.vlist;

import std.conv : to;
import etabli.core, etabli.render, etabli.common;
import etabli.ui.gui_element, etabli.ui.container, etabli.ui.slider;

private final class ListContainer : UIElement {
    public {
        VContainer container;
    }

    this(Vec2f sz) {
        isLocked = true;
        container = new VContainer;
        size(sz);
        appendNode(container);
        hasCanvas(true);
    }
}

/// Vertical list of elements with a slider.
class VList : UIElement {
    protected {
        ListContainer _container;
        Slider _slider;
        Vec2f _lastMousePos = Vec2f.zero;
        float _layoutLength = 25f;
        int _nbElements;
        int _idElementSelected;
    }

    @property {
        /// The ID of the node that has been selected.
        int selected() const {
            return _idElementSelected;
        }
        /// Ditto
        int selected(int id) {
            if (id >= _nbElements)
                id = _nbElements - 1;
            if (id < 0)
                id = 0;
            _idElementSelected = id;

            //Update elements
            auto elements = _container.container.elements;
            foreach (UIElement node; _container.container.elements)
                node.isSelected = false;
            if (_idElementSelected < elements.length)
                elements[_idElementSelected].isSelected = true;
            return _idElementSelected;
        }

        /// The list of all its elements.
        override const(UIElement[]) elements() const {
            return _container.container.elements;
        }
        /// Ditto
        override UIElement[] elements() {
            return _container.container.elements;
        }

        /// Return the first node gui.
        override UIElement firstNode() {
            return _container.container.firstNode;
        }

        /// Return the last node gui.
        override UIElement lastNode() {
            return _container.container.lastNode;
        }

        /// The number of elements it currently has.
        override size_t nodeCount() const {
            return _container.container.nodeCount;
        }
    }

    /// Ctor.
    this(Vec2f sz) {
        isLocked = true;
        _slider = new VScrollbar;
        _slider.setAlign(GuiAlignX.left, GuiAlignY.center);
        _container = new ListContainer(sz);
        _container.setAlign(GuiAlignX.right, GuiAlignY.top);
        _container.container.setAlign(GuiAlignX.center, GuiAlignY.top);

        super.appendNode(_slider);
        super.appendNode(_container);

        size(sz);
        position(Vec2f.zero);

        setEventHook(true);

        _container.container.size = Vec2f(_container.size.x, 0f);
    }

    override void onCallback(string id) {
        if (id != "list")
            return;
        auto elements = _container.container.elements;
        foreach (size_t elementId, ref UIElement node; _container.container.elements) {
            node.isSelected = false;
            if (node.isHovered)
                _idElementSelected = cast(uint) elementId;
        }
        if (_idElementSelected < elements.length)
            elements[_idElementSelected].isSelected = true;
    }

    override void onEvent(Event event) {
        if (event.type == Event.Type.mouseWheel)
            _slider.onEvent(event);
    }

    override void onSize() {
        _slider.size = Vec2f(10f, _size.y);
        _container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.size = Vec2f(size.x - _slider.size.x, size.y);
        _container.canvas.renderSize = _container.size.to!Vec2i;
    }

    override void update(float deltaTime) {
        super.update(deltaTime);
        const float min = 0f;
        const float max = _container.container.size.y - _container.size.y;
        const float exceedingHeight = _container.container.size.y - _container.canvas.size.y;

        if (exceedingHeight < 0f) {
            _slider.maxValue = 0;
            _slider.steps = 0;
        }
        else {
            _slider.maxValue = (exceedingHeight / _layoutLength) + 1;
            _slider.steps = to!uint(_slider.maxValue);
        }
        _container.canvas.position = _container.canvas.size / 2f + Vec2f(0f,
                lerp(min, max, _slider.offset));
    }

    override void prependNode(UIElement node) {
        node.position = Vec2f.zero;
        node.size = Vec2f(_container.size.x, node.size.y);
        node.setAlign(GuiAlignX.right, GuiAlignY.top);
        node.isSelected = (_nbElements == 0u);
        node.setCallback(this, "list");

        _nbElements++;
        _container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.container.position = Vec2f.zero;
        _container.container.prependNode(node);
    }

    override void appendNode(UIElement node) {
        node.position = Vec2f.zero;
        node.size = Vec2f(_container.size.x, node.size.y);
        node.setAlign(GuiAlignX.right, GuiAlignY.top);
        node.isSelected = (_nbElements == 0u);
        node.setCallback(this, "list");

        _nbElements++;
        _container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.container.position = Vec2f.zero;
        _container.container.appendNode(node);
    }

    override void removeElements() {
        _nbElements = 0u;
        _idElementSelected = 0u;
        _container.container.size = Vec2f(_container.size.x, 0f);
        _container.container.position = Vec2f.zero;
        _container.container.removeElements();
    }

    override void removeNode(size_t id) {
        _container.container.removeNode(id);
        _nbElements = cast(int) _container.container.nodeCount;
        _idElementSelected = 0u;
        _container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.container.position = Vec2f(0f, _container.container.size.y / 2f);
    }

    override void removeNode(UIElement gui) {
        _container.container.removeNode(gui);
        _nbElements = cast(int) _container.container.nodeCount;
        _idElementSelected = 0u;
        _container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.container.position = Vec2f(0f, _container.container.size.y / 2f);
    }
}
