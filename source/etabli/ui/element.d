/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.element;

import etabli.common;
import etabli.render;

/// Élément d’interface
abstract class UIElement {
    alias EventListener = void delegate();

    private {
        UIElement _parent;
        Array!UIElement _children;
        Array!Image _images;
        Array!EventListener[string] _eventListener;
    }

    private {
        bool _isHovered, _hasFocus, _isPressed, _isSelected, _isActive, _isGrabbed;
        bool _isEnabled = true;
        bool _isAlive = true;
        Vec2f _mousePosition = Vec2f.zero;
    }

    Vec2f position = Vec2f.zero;
    Vec2f size = Vec2f.zero;
    Vec2f pivot = Vec2f.half;

    /// Ordenancement
    int zOrder = 0;

    /// Alignment horizontal
    enum AlignX {
        left,
        center,
        right
    }

    /// Alignment vertical
    enum AlignY {
        top,
        center,
        bottom
    }

    AlignX alignX = AlignX.center;
    AlignY alignY = AlignY.center;

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
    }

    State[string] states;
    string currentStateName;
    State initState, targetState;
    Timer timer;

    // Propriétés

    @property {
        bool isAlive() const {
            return _isAlive;
        }

        UIElement parent() {
            return _parent;
        }

        Array!UIElement children() {
            return _children;
        }

        Array!Image images() {
            return _images;
        }

        Vec2f mousePosition() const {
            return _mousePosition;
        }

        package Vec2f mousePosition(Vec2f mousePosition_) {
            return _mousePosition = mousePosition_;
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
                dispatchEvent(_hasFocus ? "focus" : "unfocus", false);
            }
            return _hasFocus;
        }

        final bool isPressed() const {
            return _isPressed;
        }

        final bool isPressed(bool isPressed_) {
            if (_isPressed != isPressed_) {
                _isPressed = isPressed_;
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

        final bool isGrabbed(bool isGrabbed_) {
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
    }

    bool focusable, movable;

    this() {
        _children = new Array!UIElement;
        _images = new Array!Image;
    }

    void update() {
    }

    void draw() {
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

    final void dispatchEvent(string type, bool bubbling = true) {
        auto p = type in _eventListener;
        if (p) {
            Array!EventListener evllist = *p;
            foreach (listener; evllist) {
                listener();
            }
        }

        if (bubbling && _parent) {
            _parent.dispatchEvent(type);
        }
    }

    final void addElement(UIElement element) {
        element._parent = this;
        _children ~= element;
    }

    final void clearChildren() {
        foreach (child; _children) {
            child._parent = null;
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
        _isAlive = false;
        _parent = null;
        clearChildren();
        clearImages();
    }
}
