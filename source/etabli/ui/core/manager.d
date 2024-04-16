/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.core.manager;

import std.algorithm;
import std.stdio;
import std.string;

import bindbc.sdl;

import etabli.common;
import etabli.input;
import etabli.render;
import etabli.core;
import etabli.ui.core.element;

/// Gestionnaire d’interfaces
final class UIManager {
    private {
        Array!UIElement _elements;

        UIElement _pressedElement;
        Vec2f _pressedElementPosition = Vec2f.zero;

        UIElement _tempGrabbedElement, _grabbedElement;
        Vec2f _grabbedElementPosition = Vec2f.zero;

        UIElement _hoveredElement;
        bool _elementAlreadyHovered;
        Vec2f _hoveredElementPosition = Vec2f.zero;

        UIElement _focusedElement;

        InputEvent _inputEvent;

        UIElement[] _mouseDownElements;

        UIElement[] _modalStack;
    }

    @property {
        Vec2f pressedElementPosition() const {
            return _pressedElementPosition;
        }

        InputEvent input() {
            return _inputEvent;
        }
    }

    bool isDebug;

    this() {
        _elements = new Array!UIElement;
    }

    /// Màj
    void update() {
        UIElement[] modalElements;
        bool isDirty;
        for (size_t i; i < _modalStack.length; ++i) {
            update(_modalStack[i]);
            if (_modalStack[i].isAlive) {
                modalElements ~= _modalStack[i];
            }
            else {
                isDirty = true;
            }
        }
        if (isDirty) {
            _modalStack = modalElements;
        }

        sort!((a, b) => (a.zOrder > b.zOrder), SwapStrategy.stable)(_elements.array);
        foreach (i, element; _elements) {
            update(element);

            if (!element.isAlive) {
                _elements.mark(i);
            }
        }
        _elements.sweep(true);
    }

    void setFocus(UIElement element) {
        if (_focusedElement && _focusedElement != element) {
            _focusedElement.hasFocus = false;
        }
        _focusedElement = null;

        if (element) {
            if (element.focusable) {
                _focusedElement = element;
                _focusedElement.hasFocus = true;
            }
        }
    }

    void dispatch(InputEvent event) {
        _inputEvent = event;
        final switch (event.type) with (InputEvent.Type) {
        case none:
            break;
        case keyButton:
            if (_focusedElement) {
                _focusedElement.dispatchEvent("key");
            }
            break;
        case mouseButton:
            auto mouseButtonEvent = event.asMouseButton();
            if (mouseButtonEvent.state.down()) {
                _tempGrabbedElement = null;
                _pressedElement = null;

                if (!event.isAccepted) {
                    bool isDiscarded;
                    foreach_reverse (UIElement element; _getActiveElements()) {
                        if (dispatchMouseDownEvent(mouseButtonEvent.position, element, isDiscarded)) {
                            event.accept();
                            isDiscarded = true;
                        }
                    }
                }

                if (_tempGrabbedElement) {
                    _grabbedElement = _tempGrabbedElement;
                }

                if (_focusedElement && _focusedElement != _pressedElement) {
                    _focusedElement.hasFocus = false;
                }
                _focusedElement = null;

                if (_pressedElement) {
                    _pressedElement.isPressed = true;

                    if (_pressedElement.focusable) {
                        _focusedElement = _pressedElement;
                        _focusedElement.hasFocus = true;
                    }
                }
            }
            else {
                _grabbedElement = null;

                if (!event.isAccepted) {
                    bool isDiscarded;
                    foreach_reverse (UIElement element; _getActiveElements()) {
                        if (dispatchMouseUpEvent(mouseButtonEvent.position, element, isDiscarded)) {
                            event.accept();
                            isDiscarded = true;
                        }
                    }
                }

                foreach (UIElement element; _mouseDownElements) {
                    element.dispatchEvent("mouserelease", false);
                }
                _mouseDownElements.length = 0;

                if (_pressedElement) {
                    _pressedElement.isPressed = false;
                }
            }
            break;
        case mouseMotion:
            auto mouseMotionEvent = event.asMouseMotion();
            foreach (UIElement element; _getActiveElements()) {
                dispatchMouseUpdateEvent(mouseMotionEvent.position, element);
            }

            if (_hoveredElement && !_elementAlreadyHovered) {
                _hoveredElement.isHovered = true;
            }
            break;
        case mouseWheel:
            if (_hoveredElement) {
                _hoveredElement.dispatchEvent("wheel");
            }
            break;
        case controllerButton:
            if (_focusedElement) {
                _focusedElement.dispatchEvent("button");
            }
            break;
        case controllerAxis:
            if (_focusedElement) {
                _focusedElement.dispatchEvent("axis");
            }
            break;
        case textInput:
            if (_focusedElement) {
                _focusedElement.dispatchEvent("text");
            }
            break;
        case dropFile:
            if (_focusedElement) {
                _focusedElement.dispatchEvent("file");
            }
            break;
        }
    }

    private void updateMousePosition(Vec2f position, UIElement element) {
        position = _getPointInElement(position, element);
        element.setMousePosition(position);

        foreach (child; element.getChildren()) {
            updateMousePosition(position, child);
        }
    }

    /// Process a mouse down event down the tree.
    private bool dispatchMouseDownEvent(Vec2f position, UIElement element, bool isDiscarded = false) {
        Vec2f parentPosition = position;
        position = _getPointInElement(position, element);
        Vec2f elementSize = element.getSize() * element.scale;
        element.setMousePosition(position);

        bool isInside = position.isBetween(Vec2f.zero, elementSize);
        if (!element.isEnabled || !isInside || isDiscarded) {
            foreach (child; element.getChildren()) {
                updateMousePosition(position, child);
            }
            return false;
        }

        _pressedElement = element;
        _tempGrabbedElement = null;

        _pressedElementPosition = position;

        if (element.movable && !_grabbedElement) {
            _tempGrabbedElement = element;
            _grabbedElementPosition = parentPosition;
        }

        foreach_reverse (child; element.getChildren()) {
            bool discard = dispatchMouseDownEvent(position, child, isDiscarded);
            if (discard) {
                isDiscarded = discard;
            }
        }

        element.dispatchEvent("mousedown", false);
        _mouseDownElements ~= element;

        return true;
    }

    /// Process a mouse up event down the tree.
    private bool dispatchMouseUpEvent(Vec2f position, UIElement element, bool isDiscarded = false) {
        position = _getPointInElement(position, element);
        Vec2f elementSize = element.getSize() * element.scale;
        element.setMousePosition(position);

        bool isInside = position.isBetween(Vec2f.zero, elementSize);
        if (!element.isEnabled || !isInside || isDiscarded) {
            foreach (child; element.getChildren()) {
                updateMousePosition(position, child);
            }
            return false;
        }

        foreach_reverse (child; element.getChildren()) {
            bool discard = dispatchMouseUpEvent(position, child, isDiscarded);
            if (discard) {
                isDiscarded = discard;
            }
        }

        element.dispatchEvent("mouseup", false);

        if (_pressedElement == element) {
            //The previous element is now unhovered.
            if (_hoveredElement != _pressedElement) {
                _hoveredElement.isHovered = false;
            }

            //The element is now hovered and receive the onSubmit event.
            _hoveredElement = _pressedElement;
            element.isHovered = true;

            dispatchEventExclude("clickoutside", _pressedElement);
            _pressedElement.dispatchEvent("click", false);
            _pressedElement.dispatchEvent("clickinside");
        }

        return true;
    }

    /// Process a mouse update event down the tree.
    private void dispatchMouseUpdateEvent(Vec2f position, UIElement element) {
        Vec2f parentPosition = position;
        position = _getPointInElement(position, element);
        Vec2f elementSize = element.getSize() * element.scale;
        element.setMousePosition(position);

        bool isInside = position.isBetween(Vec2f.zero, elementSize);

        bool wasHovered = element.isHovered;

        if (element.isEnabled && element == _grabbedElement) {
            if (!element.movable) {
                _grabbedElement = null;
            }
            else {
                Vec2f delta = parentPosition - _grabbedElementPosition;

                if (element.getAlignX() == UIAlignX.right)
                    delta.x = -delta.x;

                if (element.getAlignY() == UIAlignY.bottom)
                    delta.y = -delta.y;

                element.setPosition(element.getPosition() + delta);

                _grabbedElementPosition = parentPosition;
            }
        }

        if (element.isEnabled && isInside) {
            //Register element
            _elementAlreadyHovered = wasHovered;
            _hoveredElement = element;
            _hoveredElementPosition = position;

            element.dispatchEvent("mousemove", false);
        }
        else {
            void unhoverElement(UIElement element) {
                element.isHovered = false;
                if (_hoveredElement == element)
                    _hoveredElement = null;
                foreach (child; element.getChildren())
                    unhoverElement(child);
            }

            unhoverElement(element);

            foreach (child; element.getChildren()) {
                updateMousePosition(position, child);
            }
            return;
        }

        foreach (child; element.getChildren())
            dispatchMouseUpdateEvent(position, child);
    }

    private void update(UIElement element) {
        // Compute transitions
        if (element.timer.isRunning) {
            element.timer.update();

            SplineFunc splineFunc = getSplineFunc(element.targetState.spline);
            const float t = splineFunc(element.timer.value01);

            element.offset = lerp(element.initState.offset, element.targetState.offset, t);
            element.scale = lerp(element.initState.scale, element.targetState.scale, t);
            element.color = lerp(element.initState.color, element.targetState.color, t);
            element.angle = lerp(element.initState.angle, element.targetState.angle, t);
            element.alpha = lerp(element.initState.alpha, element.targetState.alpha, t);

            if (!element.timer.isRunning) {
                element.dispatchEvent("state", false);
            }
        }

        /// Màj des images
        Array!Image images = element.getImages();
        sort!((a, b) => (a.zOrder > b.zOrder), SwapStrategy.stable)(images.array);
        foreach (i, image; images) {
            image.update();

            if (!image.isAlive) {
                images.mark(i);
            }
        }
        images.sweep(true);

        /// Màj des enfants
        Array!UIElement children = element.getChildren();
        sort!((a, b) => (a.zOrder > b.zOrder), SwapStrategy.stable)(children.array);
        foreach (i, child; children) {
            update(child);

            if (!child.isAlive) {
                children.mark(i);
            }
        }
        children.sweep(true);

        element.dispatchEvent("update", false);
    }

    pragma(inline) private Vec2f _getPointInElement(Vec2f position, UIElement element) {
        Vec2f elementPos = element.getElementOrigin();
        Vec2f elementSize = element.getSize() * element.scale;
        Vec2f pivot = elementPos + elementSize * element.getPivot();

        if (element.angle != 0.0) {
            Vec2f mouseDelta = position - pivot;
            mouseDelta.rotate(degToRad(-element.angle));
            position = mouseDelta + pivot;
        }
        position -= elementPos;
        return position;
    }

    /// Draw
    void draw() {
        foreach (UIElement element; _elements) {
            draw(element);
        }

        foreach (UIElement element; _modalStack) {
            draw(element);
        }
    }

    private void draw(UIElement element) {
        Vec2f position = element.getElementOrigin().round();

        if (!element.isVisible || element.getWidth() <= 0f || element.getHeight() <= 0f)
            return;

        Etabli.renderer.pushCanvas(cast(uint) element.getWidth(), cast(uint) element.getHeight());

        foreach (Image image; element.getImages()) {
            if (image.isVisible)
                image.draw(Vec2f.zero);
        }

        element.dispatchEvent("draw", false);

        foreach (UIElement child; element.getChildren()) {
            draw(child);
        }

        Vec2f size = element.scale * element.getSize();
        Etabli.renderer.popCanvasAndDraw(position, size, element.angle,
            element.getPivot(), element.color, element.alpha);

        if (isDebug) {
            Color rectColor = Color.blue;
            if (!element.isEnabled)
                rectColor = Color.white;
            else if (element.isPressed)
                rectColor = Color.red;
            else if (element.isHovered)
                rectColor = Color.green;
            Etabli.renderer.drawRect(position, size, rectColor, 1f, false);
        }
    }

    void dispatchEvent(string type, bool bubbleDown = true) {
        if (bubbleDown) {
            foreach_reverse (UIElement element; _modalStack) {
                _dispatchEvent(type, element);
            }

            foreach (UIElement element; _elements) {
                _dispatchEvent(type, element);
            }
        }
        else {
            foreach_reverse (UIElement element; _modalStack) {
                element.dispatchEvent(type, false);
            }

            foreach (UIElement element; _elements) {
                element.dispatchEvent(type, false);
            }
        }
    }

    void dispatchEventExclude(string type, UIElement excludedElement) {
        foreach (UIElement child; excludedElement.getChildren()) {
            _dispatchEvent(type, child);
        }

        _dispatchEventExclude(type, excludedElement);
    }

    private void _dispatchEventExclude(string type, UIElement excludedElement) {
        UIElement parent = excludedElement.getParent();
        if (parent) {
            foreach (UIElement child; parent.getChildren()) {
                if (child == excludedElement) {
                    continue;
                }

                _dispatchEvent(type, child);
            }
            _dispatchEventExclude(type, parent);
        }
        else {
            foreach (UIElement element; _elements) {
                if (element == excludedElement) {
                    continue;
                }

                _dispatchEvent(type, element);
            }
        }
    }

    private void _dispatchEvent(string type, UIElement element) {
        foreach (UIElement child; element.getChildren()) {
            _dispatchEvent(type, child);
        }
        element.dispatchEvent(type, false);
    }

    private UIElement[] _getActiveElements() {
        if (_modalStack.length) {
            return _modalStack[$ - 1 .. $];
        }
        return _elements.array;
    }

    /// Ajoute un élément d’interface
    void addUI(UIElement element) {
        _elements ~= element;
        element.isAlive = true;
    }

    void pushModalUI(UIElement element) {
        _modalStack ~= element;
        element.isAlive = true;
    }

    void popModalUI() {
        if (!_modalStack.length)
            return;
        _modalStack[$ - 1].remove();
        _modalStack.length--;
    }

    /// Supprime toutes les interfaces
    void clearUI() {
        foreach (UIElement element; _modalStack) {
            element.remove();
        }
        _modalStack.length = 0;

        foreach (UIElement element; _elements) {
            element.remove();
        }
        _elements.clear();
    }
}
