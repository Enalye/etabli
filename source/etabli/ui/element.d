/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.element;

import etabli.common;
import etabli.window;
import etabli.render;
import etabli.runtime;

/// Alignement horizontal
enum UIAlignX {
    left,
    center,
    right
}

/// Alignement vertical
enum UIAlignY {
    top,
    center,
    bottom
}

/// Élément d’interface
class UIElement {
    alias EventListener = void delegate();

    private {
        UIElement _parent;
        Array!UIElement _children;
        Array!Image _images;
        Array!EventListener[string] _eventListener;

        UIAlignX _alignX = UIAlignX.center;
        UIAlignY _alignY = UIAlignY.center;

        Vec2f _position = Vec2f.zero;
        Vec2f _size = Vec2f.zero;
        Vec2f _pivot = Vec2f.half;
        Vec2f _mousePosition = Vec2f.zero;

        bool _isHovered, _hasFocus, _isPressed, _isSelected, _isActive, _isGrabbed;
        bool _isEnabled = true;
        bool _isAlive;
        bool _widthLock, _heightLock;
        bool _isVisible = true;
    }

    /// Ordenancement
    int zOrder = 0;

    /// Transitions
    Vec2f offset = Vec2f.zero;
    Vec2f scale = Vec2f.one;
    Color color = Color.white;
    float alpha = 1f;
    double angle = 0.0;

    static final class State {
        string name;
        Vec2f offset = Vec2f.zero;
        Vec2f scale = Vec2f.one;
        Color color = Color.white;
        float alpha = 1f;
        double angle = 0.0;
        int time = 60;
        Spline spline = Spline.linear;

        this(string name_) {
            name = name_;
        }
    }

    package {
        State[string] states;
        string currentStateName;
        State initState, targetState;
        Timer timer;
    }

    // Propriétés
    @property {
        package final bool isAlive() const {
            return _isAlive;
        }

        package final bool isAlive(bool isAlive_) {
            if (_isAlive != isAlive_) {
                _isAlive = isAlive_;
                dispatchEvent(_isAlive ? "register" : "unregister", false);
            }
            return _isAlive = isAlive_;
        }

        final bool isHovered() const {
            return _isHovered;
        }

        package final bool isHovered(bool isHovered_) {
            if (_isHovered != isHovered_) {
                _isHovered = isHovered_;
                dispatchEvent(_isHovered ? "mouseenter" : "mouseleave", false);
            }
            return _isHovered;
        }

        final bool hasFocus() const {
            return _hasFocus;
        }

        final bool hasFocus(bool hasFocus_) {
            if (_hasFocus != hasFocus_) {
                _hasFocus = hasFocus_;
                dispatchEvent(_hasFocus ? "focus" : "blur", false);
            }
            return _hasFocus;
        }

        final bool isPressed() const {
            return _isPressed;
        }

        package final bool isPressed(bool isPressed_) {
            if (_isPressed != isPressed_) {
                _isPressed = isPressed_;
                dispatchEvent(_isPressed ? "press" : "unpress", true);
            }
            return _isPressed;
        }

        final bool isSelected() const {
            return _isSelected;
        }

        final bool isSelected(bool isSelected_) {
            if (_isSelected != isSelected_) {
                _isSelected = isSelected_;
                dispatchEvent(_isSelected ? "select" : "deselect", false);
            }
            return _isSelected;
        }

        final bool isActive() const {
            return _isActive;
        }

        final bool isActive(bool isActive_) {
            if (_isActive != isActive_) {
                _isActive = isActive_;
                dispatchEvent(_isActive ? "active" : "inactive", false);
            }
            return _isActive;
        }

        final bool isGrabbed() const {
            return _isGrabbed;
        }

        package final bool isGrabbed(bool isGrabbed_) {
            if (_isGrabbed != isGrabbed_) {
                _isGrabbed = isGrabbed_;
                dispatchEvent(_isGrabbed ? "grab" : "ungrab", false);
            }
            return _isGrabbed;
        }

        final bool isEnabled() const {
            return _isEnabled;
        }

        final bool isEnabled(bool isEnabled_) {
            if (_isEnabled != isEnabled_) {
                _isEnabled = isEnabled_;
                dispatchEvent(_isEnabled ? "enable" : "disable", false);
            }
            return _isEnabled;
        }

        final bool isVisible() const {
            return _isVisible;
        }

        final bool isVisible(bool isVisible_) {
            if (_isVisible != isVisible_) {
                _isVisible = isVisible_;
                dispatchEvent(_isVisible ? "visible" : "hidden", false);
            }
            return _isVisible;
        }
    }

    bool focusable, movable;

    this() {
        _children = new Array!UIElement;
        _images = new Array!Image;
    }

    final UIElement getParent() {
        return _parent;
    }

    final Vec2f getParentSize() const {
        if (_parent) {
            return _parent._size;
        }
        return cast(Vec2f) Etabli.window.size();
    }

    final float getParentWidth() const {
        if (_parent) {
            return _parent._size.x;
        }
        return cast(float) Etabli.window.width();
    }

    final float getParentHeight() const {
        if (_parent) {
            return _parent._size.y;
        }
        return cast(float) Etabli.window.height();
    }

    final Array!UIElement getChildren() {
        return _children;
    }

    final Array!Image getImages() {
        return _images;
    }

    final Vec2f getMousePosition() const {
        return _mousePosition;
    }

    final package Vec2f setMousePosition(Vec2f mousePosition) {
        return _mousePosition = mousePosition;
    }

    final void setAlign(UIAlignX alignX, UIAlignY alignY) {
        _alignX = alignX;
        _alignY = alignY;
    }

    final UIAlignX getAlignX() const {
        return _alignX;
    }

    final UIAlignY getAlignY() const {
        return _alignY;
    }

    final Vec2f getAbsolutePosition() const {
        Vec2f position = Vec2f.zero;
        if (_parent) {
            position = _parent.getAbsolutePosition();
        }
        position += Etabli.ui.getElementOrigin(this, _parent);
        return position;
    }

    final Vec2f getPosition() const {
        return _position;
    }

    final void setPosition(Vec2f position_) {
        if (_position == position_)
            return;
        _position = position_;
        dispatchEvent("position");
    }

    final Vec2f getSize() const {
        return _size;
    }

    final float getWidth() const {
        return _size.x;
    }

    final float getHeight() const {
        return _size.y;
    }

    final void setSize(Vec2f size_) {
        if (_size == size_)
            return;

        bool isDirty;

        if (!_widthLock && _size.x != size_.x) {
            isDirty = true;
            _size.x = size_.x;
        }

        if (!_heightLock && _size.y != size_.y) {
            isDirty = true;
            _size.y = size_.y;
        }

        if (isDirty) {
            dispatchEvent("size");
            dispatchEventChildren("parentSize", false);
        }
    }

    final void setWidth(float width_) {
        if (_widthLock || _size.x == width_)
            return;
        _size.x = width_;
        dispatchEvent("size");
        dispatchEventChildren("parentSize", false);
    }

    final void setHeight(float height_) {
        if (_heightLock || _size.y == height_)
            return;
        _size.y = height_;
        dispatchEvent("size");
        dispatchEventChildren("parentSize", false);
    }

    final void setSizeLock(bool width, bool height) {
        _widthLock = width;
        _heightLock = height;
    }

    final Vec2f getCenter() const {
        return _size / 2f;
    }

    final Vec2f getPivot() const {
        return _pivot;
    }

    final void setPivot(Vec2f pivot_) {
        if (_pivot == pivot_)
            return;
        _pivot = pivot_;
        dispatchEvent("pivot");
    }

    void addState(State state) {
        states[state.name] = state;
    }

    string getState() {
        return currentStateName;
    }

    void setState(string name) {
        const auto ptr = name in states;
        if (!ptr) {
            return;
        }

        currentStateName = ptr.name;
        initState = null;
        targetState = null;
        offset = ptr.offset;
        scale = ptr.scale;
        color = ptr.color;
        angle = ptr.angle;
        alpha = ptr.alpha;
        timer.stop();
    }

    void runState(string name) {
        auto ptr = name in states;
        if (!ptr) {
            return;
        }

        currentStateName = ptr.name;
        initState = new State("");
        initState.offset = offset;
        initState.scale = scale;
        initState.angle = angle;
        initState.alpha = alpha;
        initState.time = timer.duration;
        targetState = *ptr;
        timer.start(ptr.time);
    }

    final void addEventListener(string type, EventListener listener) {
        _eventListener.update(type, {
            Array!EventListener evllist = new Array!EventListener;
            evllist ~= listener;
            return evllist;
        }, (Array!EventListener evllist) { evllist ~= listener; });
    }

    final void removeEventListener(string type, EventListener listener) {
        _eventListener.update(type, { return new Array!EventListener; },
            (Array!EventListener evllist) {
            foreach (i, eventListener; evllist) {
                if (eventListener == listener)
                    evllist.mark(i);
            }
            evllist.sweep();
        });
    }

    final void dispatchEvent(string type, bool bubbleUp = true) {
        auto p = type in _eventListener;
        if (p) {
            Array!EventListener evllist = *p;
            foreach (listener; evllist) {
                listener();
            }
        }

        if (bubbleUp && _parent) {
            _parent.dispatchEvent(type);
        }
    }

    final void dispatchEventChildren(string type, bool bubbleDown = true) {
        if (bubbleDown) {
            foreach (UIElement child; _children) {
                child.dispatchEvent(type, false);
                child.dispatchEventChildren(type, bubbleDown);
            }
        }
        else {
            foreach (UIElement child; _children) {
                child.dispatchEvent(type, false);
            }
        }
    }

    final void addUI(UIElement element) {
        if (element.isAlive)
            return;

        element.isAlive = true;
        element._parent = this;
        _children ~= element;
    }

    final void clearUI() {
        foreach (child; _children) {
            child.remove();
        }
        _children.clear();
    }

    final void addImage(Image image) {
        _images ~= image;
    }

    final void clearImages() {
        _images.clear();
    }

    final void remove() {
        isAlive = false;
        _parent = null;
    }
}
