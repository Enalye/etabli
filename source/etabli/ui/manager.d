/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.manager;

import std.algorithm;
import std.stdio;
import std.string;

import bindbc.sdl;

import etabli.common;
import etabli.input;
import etabli.render;
import etabli.runtime;
import etabli.ui.element;

/// UI children manager
class UIManager {
    private {
        UIElement[] _elements;

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

    /// Update
    void update() {
        foreach (UIElement element; _elements) {
            update(element);
        }
    }

    void dispatch(InputEvent[] events) {
        foreach (InputEvent event; events) {
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

                    foreach (UIElement element; _elements) {
                        dispatchMouseDownEvent(mouseButtonEvent.position, element);
                    }

                    if (_tempGrabbedElement) {
                        _grabbedElement = _tempGrabbedElement;
                    }

                    if (_pressedElement) {
                        _pressedElement.isPressed = true;
                    }
                }
                else {
                    _grabbedElement = null;

                    foreach (UIElement element; _elements) {
                        dispatchMouseUpEvent(mouseButtonEvent.position, element);
                    }

                    foreach (UIElement element; _mouseDownElements) {
                        element.dispatchEvent("mouserelease", false);
                    }
                    _mouseDownElements.length = 0;

                    if (_focusedElement && _focusedElement != _pressedElement) {
                        _focusedElement.hasFocus = false;
                    }
                    _focusedElement = null;

                    if (_pressedElement) {
                        _pressedElement.isPressed = false;
                    }

                    if (_pressedElement && _pressedElement.focusable) {
                        _focusedElement = _pressedElement;
                        _focusedElement.hasFocus = true;
                    }
                }
                break;
            case mouseMotion:
                auto mouseMotionEvent = event.asMouseMotion();
                foreach (UIElement element; _elements) {
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
    }

    /// Process a mouse down event down the tree.
    private void dispatchMouseDownEvent(Vec2f position, UIElement element, UIElement parent = null) {
        position = _getPointInElement(position, element, parent);
        Vec2f elementSize = element.getSize() * element.scale;
        element.setMousePosition(position);

        bool isInside = position.isBetween(Vec2f.zero, elementSize);
        if (!element.isEnabled || !isInside) {
            return;
        }

        _pressedElement = element;
        _tempGrabbedElement = null;

        _pressedElementPosition = position;

        if (element.movable && !_grabbedElement) {
            _tempGrabbedElement = element;
            _grabbedElementPosition = _pressedElementPosition;
        }

        foreach (child; element.getChildren())
            dispatchMouseDownEvent(position, child, element);

        element.dispatchEvent("mousedown", false);
        _mouseDownElements ~= element;
    }

    /// Process a mouse up event down the tree.
    private void dispatchMouseUpEvent(Vec2f position, UIElement element, UIElement parent = null) {
        position = _getPointInElement(position, element, parent);
        Vec2f elementSize = element.getSize() * element.scale;
        element.setMousePosition(position);

        bool isInside = position.isBetween(Vec2f.zero, elementSize);
        if (!element.isEnabled || !isInside) {
            return;
        }

        foreach (child; element.getChildren())
            dispatchMouseUpEvent(position, child, element);

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
            _pressedElement.dispatchEvent("click");
        }
    }

    /// Process a mouse update event down the tree.
    private void dispatchMouseUpdateEvent(Vec2f position, UIElement element, UIElement parent = null) {
        position = _getPointInElement(position, element, parent);
        Vec2f elementSize = element.getSize() * element.scale;
        element.setMousePosition(position);

        bool isInside = position.isBetween(Vec2f.zero, elementSize);

        bool wasHovered = element.isHovered;

        if (element.isEnabled && element == _grabbedElement) {
            if (!element.movable) {
                _grabbedElement = null;
            }
            else {
                Vec2f delta = position - _grabbedElementPosition;

                if (element.getAlignX() == UIAlignX.right)
                    delta.x = -delta.x;

                if (element.getAlignY() == UIAlignY.bottom)
                    delta.y = -delta.y;

                element.setPosition(element.getPosition() + delta);

                _grabbedElementPosition = position;
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
            return;
        }

        foreach (child; element.getChildren())
            dispatchMouseUpdateEvent(position, child, element);
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
        images.sweep();

        /// Màj des enfants
        Array!UIElement children = element.getChildren();
        sort!((a, b) => (a.zOrder > b.zOrder), SwapStrategy.stable)(children.array);
        foreach (i, child; children) {
            update(child);

            if (!child.isAlive) {
                children.mark(i);
            }
        }
        children.sweep();

        element.dispatchEvent("update", false);
    }

    pragma(inline) private Vec2f _getPointInElement(Vec2f position,
        UIElement element, UIElement parent = null) {
        Vec2f elementPos = _getElementOrigin(element, parent);
        Vec2f elementSize = element.getSize() * element.scale;
        Vec2f pivot = elementPos + elementSize * element.getPivot();

        if (element.angle != 0.0) {
            Vec2f mouseDelta = position - pivot;
            mouseDelta.rotate(degToRad * -element.angle);
            position = mouseDelta + pivot;
        }
        position -= elementPos;
        return position;
    }

    pragma(inline) private Vec2f _getElementOrigin(UIElement element, UIElement parent = null) {
        Vec2f position = element.getPosition() + element.offset;
        const Vec2f parentSize = parent ? parent.getSize() : Vec2f(Etabli.window.width,
            Etabli.window.height);

        final switch (element.getAlignX()) with (UIAlignX) {
        case left:
            break;
        case right:
            position.x = parentSize.x - (position.x + (element.getWidth() * element.scale.x));
            break;
        case center:
            position.x = (parentSize.x / 2f + position.x) - (element.getSize()
                    .x * element.scale.x) / 2f;
            break;
        }

        final switch (element.getAlignY()) with (UIAlignY) {
        case top:
            break;
        case bottom:
            position.y = parentSize.y - (position.y + (element.getHeight() * element.scale.y));
            break;
        case center:
            position.y = (parentSize.y / 2f + position.y) - (element.getSize()
                    .y * element.scale.y) / 2f;
            break;
        }

        return position;
    }

    /// Draw
    void draw() {
        foreach (UIElement element; _elements) {
            draw(element);
        }
    }

    private void draw(UIElement element, UIElement parent = null) {
        Vec2f position = _getElementOrigin(element, parent).round();

        if (element.getWidth() <= 0f || element.getHeight() <= 0f)
            return;

        Etabli.renderer.pushCanvas(cast(uint) element.getWidth(), cast(uint) element.getHeight());

        foreach (Image image; element.getImages()) {
            if (image.isEnabled)
                image.draw(Vec2f.zero);
        }

        element.dispatchEvent("draw", false);

        foreach (UIElement child; element.getChildren()) {
            draw(child, element);
        }

        Vec2f size = element.scale * element.getSize();
        Etabli.renderer.popCanvasAndDraw(position, size, element.angle,
            element.getPivot() * size, element.color, element.alpha);

        if (isDebug)
            Etabli.renderer.drawRect(position, size, Color.blue, 1f, false);
    }

    void dispatchEvent(string type, bool bubbleDown = true) {
        if (bubbleDown) {
            foreach (UIElement child; _elements) {
                _dispatchEvent(type, child);
            }
        }
        else {
            foreach (UIElement child; _elements) {
                child.dispatchEvent(type, false);
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

    /// Ajoute un element
    void addUI(UIElement element) {
        _elements ~= element;
        element.isAlive = true;
    }

    /// Supprime tous les éléments
    void clearUI() {
        _elements.length = 0;
        foreach (UIElement element; _elements) {
            element.remove();
        }
    }
}
