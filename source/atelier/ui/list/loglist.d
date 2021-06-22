/**
    Log list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.loglist;

import std.conv : to;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.slider;

private class LogContainer : GuiElement {
    public {
        LogLayout layout;
    }

    this(Vec2f newSize) {
        isLocked = true;
        layout = new LogLayout;
        size(newSize);
        appendChild(layout);
        hasCanvas(true);
    }

    override void draw() {
        layout.draw();
    }
}

class LogList : GuiElement {
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

        /// The list of all its children.
        override const(GuiElement[]) children() const {
            return _container.layout.children;
        }
        /// Ditto
        override GuiElement[] children() {
            return _container.layout.children;
        }

        /// Return the first child gui.
        override GuiElement firstChild() {
            return _container.layout.firstChild;
        }

        /// Return the last child gui.
        override GuiElement lastChild() {
            return _container.layout.lastChild;
        }

        /// The number of children it currently has.
        override size_t childCount() const {
            return _container.layout.childCount;
        }
    }

    this(Vec2f newSize) {
        isLocked = true;
        _slider = new VScrollbar;
        _slider.value01 = 1f;
        _container = new LogContainer(newSize);

        super.appendChild(_slider);
        super.appendChild(_container);

        size(newSize);
        position(Vec2f.zero);
    }

    override void onEvent(Event event) {
        super.onEvent(event);
        if (event.type == Event.Type.mouseDown || event.type == Event.Type.mouseUp
                || event.type == Event.Type.mouseUpdate) {
            _lastMousePos = event.mouse.position;
            if (_slider.isInside(event.mouse.position))
                _slider.onEvent(event);
            else if (event.type == Event.Type.mouseDown) {
                auto widgets = _container.layout.children;
                foreach (size_t id, const GuiElement widget; widgets) {
                    if (widget.isHovered)
                        _idElementSelected = cast(uint) id;
                }
            }
        }
        if (!isOnInteractableGuiElement(_lastMousePos) && event.type == Event.Type.mouseWheel)
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
            _slider.max = 0;
            _slider.step = 0;
        }
        else {
            _slider.max = exceedingHeight / (_container.canvas.size.y / 50f);
            _slider.step = to!uint(_slider.max);
        }
        _container.canvas.position = Vec2f(0f, lerp(min, max, _slider.offset));
    }

    private void repositionContainer() {
        _container.layout.position = Vec2f(5f + _container.layout.size.x / 2f - _container.size.x / 2f,
                _container.layout.size.y / 2f);
    }

    override void prependChild(GuiElement gui) {
        _container.layout.prependChild(gui);
        repositionContainer();
    }

    override void appendChild(GuiElement gui) {
        _container.layout.appendChild(gui);
        repositionContainer();
    }

    override void removeChildren() {
        _container.layout.removeChildren();
        repositionContainer();
    }

    override void removeChild(size_t id) {
        _container.layout.removeChild(id);
        repositionContainer();
    }

    override void removeChild(GuiElement gui) {
        _container.layout.removeChild(gui);
        repositionContainer();
    }
}
