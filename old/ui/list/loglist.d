/**
    Log list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.ui.list.loglist;

import std.conv : to;
import etabli.core, etabli.render, etabli.common;
import etabli.ui.gui_element, etabli.ui.layout, etabli.ui.slider;

private class LogContainer : UIElement {
    public {
        LogLayout layout;
    }

    this(Vec2f newSize) {
        isLocked = true;
        layout = new LogLayout;
        size(newSize);
        appendNode(layout);
        hasCanvas(true);
    }

    override void draw() {
        layout.draw();
    }
}

class LogList : UIElement {
    protected {
        LogContainer _container;
        Slider _slider;
        Vec2f _lastMousePos = Vec2f.zero;
        uint _idElementSelected = 0u;
    }

    @property {
        uint selected() const {
            return _idElementSelected;
        }

        /// The list of all its elements.
        override const(UIElement[]) elements() const {
            return _container.layout.elements;
        }
        /// Ditto
        override UIElement[] elements() {
            return _container.layout.elements;
        }

        /// Return the first node gui.
        override UIElement firstNode() {
            return _container.layout.firstNode;
        }

        /// Return the last node gui.
        override UIElement lastNode() {
            return _container.layout.lastNode;
        }

        /// The number of elements it currently has.
        override size_t nodeCount() const {
            return _container.layout.nodeCount;
        }
    }

    this(Vec2f newSize) {
        isLocked = true;
        _slider = new VScrollbar;
        _slider.value01 = 1f;
        _container = new LogContainer(newSize);

        super.appendNode(_slider);
        super.appendNode(_container);

        size(newSize);
        position(Vec2f.zero);
    }

    override void onEvent(Event event) {
        super.onEvent(event);
        if (event.type == Event.Type.mouseDown
                || event.type == Event.Type.mouseUp || event.type == Event.Type.mouseUpdate) {
            _lastMousePos = event.mouse.position;
            if (_slider.isInside(event.mouse.position))
                _slider.onEvent(event);
            else if (event.type == Event.Type.mouseDown) {
                auto elements = _container.layout.elements;
                foreach (size_t id, const UIElement element; elements) {
                    if (element.isHovered)
                        _idElementSelected = cast(uint) id;
                }
            }
        }
        if (!isOnInteractableElement(_lastMousePos) && event.type == Event.Type.mouseWheel)
            _slider.onEvent(event);
    }

    override void onPosition() {
        _slider.position = center - Vec2f((size.x - _slider.size.x) / 2f, 0f) + size / 2f;
        _container.position = center + Vec2f(_slider.size.x / 2f, 0f) + size / 2f;
    }

    override void onSize() {
        _slider.size = Vec2f(10f, size.y);
        _container.size = Vec2f(size.x - _slider.size.x, size.y);
        _container.canvas.renderSize = _container.size.to!Vec2i;
        onPosition();
    }

    override void update(float deltaTime) {
        _slider.update(deltaTime);
        float min = _container.canvas.size.y / 2f;
        float max = _container.layout.size.y - _container.canvas.size.y / 2f;
        float exceedingHeight = _container.layout.size.y - _container.canvas.size.y;

        if (exceedingHeight < 0f) {
            _slider.maxValue = 0;
            _slider.steps = 0;
        }
        else {
            _slider.maxValue = exceedingHeight / (_container.canvas.size.y / 50f);
            _slider.steps = to!uint(_slider.maxValue);
        }
        _container.canvas.position = Vec2f(0f, lerp(min, max, _slider.offset));
    }

    private void repositionContainer() {
        _container.layout.position = Vec2f(5f + _container.layout.size.x / 2f - _container.size.x / 2f,
                _container.layout.size.y / 2f);
    }

    override void prependNode(UIElement gui) {
        _container.layout.prependNode(gui);
        repositionContainer();
    }

    override void appendNode(UIElement gui) {
        _container.layout.appendNode(gui);
        repositionContainer();
    }

    override void removeElements() {
        _container.layout.removeElements();
        repositionContainer();
    }

    override void removeNode(size_t id) {
        _container.layout.removeNode(id);
        repositionContainer();
    }

    override void removeNode(UIElement gui) {
        _container.layout.removeNode(gui);
        repositionContainer();
    }
}
