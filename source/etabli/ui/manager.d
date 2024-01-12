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
import etabli.ui.box;
import etabli.ui.button;
import etabli.ui.element;
import etabli.ui.label;

/// UI children manager
class UIManager {
    private {
        UIElement[] _children;

        UIElement _pressedElement;
        Vec2f _pressedElementPosition = Vec2f.zero;

        UIElement _tempGrabbedElement, _grabbedElement;
        Vec2f _grabbedElementPosition = Vec2f.zero;

        UIElement _hoveredElement;
        bool _elementAlreadyHovered;
        Vec2f _hoveredElementPosition = Vec2f.zero;

        UIElement _focusedElement;
    }

    @property {
        Vec2f pressedElementPosition() const {
            return _pressedElementPosition;
        }
    }

    bool isDebug;

    /// Update
    void update() {
        foreach (UIElement element; _children) {
            update(element);
        }
    }

    void dispatch(InputEvent[] events) {
        foreach (InputEvent event; events) {
            switch (event.type) with (InputEvent.Type) {
            case mouseButton:
                auto mouseButtonEvent = event.asMouseButton();
                if (mouseButtonEvent.state.down()) {
                    _tempGrabbedElement = null;
                    _pressedElement = null;

                    foreach (UIElement element; _children) {
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

                    foreach (UIElement element; _children) {
                        dispatchMouseUpEvent(mouseButtonEvent.position, element);
                    }

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
                foreach (UIElement element; _children) {
                    dispatchMouseUpdateEvent(mouseMotionEvent.position, element);
                }

                if (_hoveredElement && !_elementAlreadyHovered) {
                    _hoveredElement.isHovered = true;
                }
                break;
            default:
                break;
            }
        }
    }

    /// Process a mouse down event down the tree.
    private void dispatchMouseDownEvent(Vec2f position, UIElement element, UIElement parent = null) {
        position = _getPointInElement(position, element, parent);
        Vec2f elementSize = element.size * element.scale;
        element.mousePosition = position;

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

        foreach (child; element.children)
            dispatchMouseDownEvent(position, child, element);

        element.dispatchEvent("mousedown", false);
    }

    /// Process a mouse up event down the tree.
    private void dispatchMouseUpEvent(Vec2f position, UIElement element, UIElement parent = null) {
        position = _getPointInElement(position, element, parent);
        Vec2f elementSize = element.size * element.scale;
        element.mousePosition = position;

        bool isInside = position.isBetween(Vec2f.zero, elementSize);
        if (!element.isEnabled || !isInside) {
            return;
        }

        foreach (child; element.children)
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

            _pressedElement.dispatchEvent("click");
        }
    }

    /// Process a mouse update event down the tree.
    private void dispatchMouseUpdateEvent(Vec2f position, UIElement element, UIElement parent = null) {
        position = _getPointInElement(position, element, parent);
        Vec2f elementSize = element.size * element.scale;
        element.mousePosition = position;

        bool isInside = position.isBetween(Vec2f.zero, elementSize);

        bool wasHovered = element.isHovered;

        if (element.isEnabled && element == _grabbedElement) {
            if (!element.movable) {
                _grabbedElement = null;
            }
            else {
                Vec2f delta = position - _grabbedElementPosition;

                if (element.alignX == UIElement.AlignX.right)
                    delta.x = -delta.x;

                if (element.alignY == UIElement.AlignY.bottom)
                    delta.y = -delta.y;

                element.position += delta;

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
                foreach (child; element.children)
                    unhoverElement(child);
            }

            unhoverElement(element);
            return;
        }

        foreach (child; element.children)
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
        }

        sort!((a, b) => (a.zOrder > b.zOrder), SwapStrategy.stable)(element.images.array);
        foreach (i, image; element.images) {
            image.update();

            if (!image.isAlive) {
                element.images.mark(i);
            }
        }
        element.images.sweep();

        // Update children
        sort!((a, b) => (a.zOrder > b.zOrder), SwapStrategy.stable)(element.children.array);
        foreach (i, child; element.children) {
            update(child);

            if (!child.isAlive) {
                element.children.mark(i);
            }
        }
        element.children.sweep();

        element.update();
    }

    pragma(inline) private Vec2f _getPointInElement(Vec2f position,
        UIElement element, UIElement parent = null) {
        Vec2f elementPos = _getElementOrigin(element, parent);
        Vec2f elementSize = element.size * element.scale;
        Vec2f pivot = elementPos + elementSize * element.pivot;

        if (element.angle != 0.0) {
            Vec2f mouseDelta = position - pivot;
            mouseDelta.rotate(degToRad * -element.angle);
            position = mouseDelta + pivot;
        }
        position -= elementPos;
        return position;
    }

    pragma(inline) private Vec2f _getElementOrigin(UIElement element, UIElement parent = null) {
        Vec2f position = element.position + element.offset;
        const Vec2f parentSize = parent ? parent.size
            : Vec2f(Etabli.window.width, Etabli.window.height);

        final switch (element.alignX) with (UIElement.AlignX) {
        case left:
            break;
        case right:
            position.x = parentSize.x - (position.x + (element.size.x * element.scale.x));
            break;
        case center:
            position.x = (parentSize.x / 2f + position.x) - (element.size.x * element.scale.x) / 2f;
            break;
        }

        final switch (element.alignY) with (UIElement.AlignY) {
        case top:
            break;
        case bottom:
            position.y = parentSize.y - (position.y + (element.size.y * element.scale.y));
            break;
        case center:
            position.y = (parentSize.y / 2f + position.y) - (element.size.y * element.scale.y) / 2f;
            break;
        }

        return position;
    }

    /// Draw
    void draw() {
        foreach (UIElement element; _children) {
            draw(element);
        }
    }

    private void draw(UIElement element, UIElement parent = null) {
        Vec2f position = _getElementOrigin(element, parent).round();

        Etabli.renderer.pushCanvas(cast(uint) element.size.x, cast(uint) element.size.y);

        foreach (Image image; element.images) {
            image.draw(Vec2f.zero);
        }

        element.draw();

        foreach (UIElement child; element.children) {
            draw(child, element);
        }

        Vec2f size = element.scale * element.size;
        Etabli.renderer.popCanvasAndDraw(position, size, element.angle,
            element.pivot * size, element.color, element.alpha);

        if (isDebug)
            Etabli.renderer.drawRect(position, size, Color.blue, 1f, false);
    }

    /// Ajoute un element
    void add(UIElement element) {
        _children ~= element;
    }

    /// Supprime tous les children
    void clear() {
        _children.length = 0;
    }
}
