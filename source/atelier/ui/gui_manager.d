/**
    Gui Manager

    Copyright: (c) Enalye 2019
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.gui_manager;

import std.conv : to;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element, atelier.ui.gui_overlay, atelier.ui.gui_modal;

private {
    bool _isGuiElementDebug = false;
    GuiElement[] _rootElements;
    float _deltaTime;
}

//-- Public ---

/// Add a gui as a top gui (not a child of anything).
void prependRoot(GuiElement gui) {
    _rootElements = gui ~ _rootElements;
}

/// Add a gui as a top gui (not a child of anything).
void appendRoot(GuiElement gui) {
    _rootElements ~= gui;
}

/// Remove all the top gui (that aren't a child of anything).
void removeRoots() {
    //_isChildGrabbed = false;
    _rootElements.length = 0uL;
}

/// Set those gui as the top guis (replacing the previous ones).
void setRoots(GuiElement[] widgets) {
    _rootElements = widgets;
}

/// Get all the root gui.
GuiElement[] getRoots() {
    return _rootElements;
}

/// Show every the hitbox of every gui element.
void setDebugGui(bool isDebug) {
    _isGuiElementDebug = isDebug;
}

/// Remove the specified gui from roots.
void removeRoot(GuiElement gui) {
    foreach (size_t i, GuiElement child; _rootElements) {
        if (child is gui) {
            removeRoot(i);
            return;
        }
    }
}

/// Remove the gui at the specified index from roots.
void removeRoot(size_t index) {
    if (!_rootElements.length)
        return;
    if (index + 1u == _rootElements.length)
        _rootElements.length--;
    else if (index == 0u)
        _rootElements = _rootElements[1 .. $];
    else
        _rootElements = _rootElements[0 .. index] ~ _rootElements[index + 1 .. $];
}

//-- Internal ---

/// Update all the guis from the root.
package(atelier) void updateRoots(float deltaTime) {
    _deltaTime = deltaTime;
    size_t index = 0;
    while (index < _rootElements.length) {
        if (_rootElements[index]._isRegistered) {
            updateRoots(_rootElements[index], null);
            index++;
        }
        else {
            removeRoot(index);
        }
    }
}

/// Draw all the guis from the root.
package(atelier) void drawRoots() {
    foreach_reverse (GuiElement widget; _rootElements) {
        drawRoots(widget);
    }
}

private {
    bool _hasClicked, _wasHoveredGuiElementAlreadyHovered;
    GuiElement _clickedGuiElement;
    GuiElement _focusedGuiElement;
    GuiElement _hoveredGuiElement;
    GuiElement _grabbedGuiElement, _tempGrabbedGuiElement;
    Canvas _canvas;
    Vec2f _clickedGuiElementEventPosition = Vec2f.zero;
    Vec2f _hoveredGuiElementEventPosition = Vec2f.zero;
    Vec2f _grabbedGuiElementEventPosition = Vec2f.zero;
    GuiElement[] _hookedGuis;
}

/// Dispatch global events on the guis from the root. \
/// Called by the main event loop.
package(atelier) void handleGuiElementEvent(Event event) {
    if (isOverlay()) {
        processOverlayEvent(event);
    }

    _hasClicked = false;
    switch (event.type) with (Event.Type) {
    case mouseDown:
        _tempGrabbedGuiElement = null;
        dispatchMouseDownEvent(null, event.mouse.position);

        if (_tempGrabbedGuiElement) {
            _grabbedGuiElement = _tempGrabbedGuiElement;
        }

        if (_hasClicked && _clickedGuiElement !is null) {
            _clickedGuiElement.isClicked = true;
            Event guiEvent = Event.Type.mouseDown;
            guiEvent.mouse.position = _clickedGuiElementEventPosition;
            _clickedGuiElement.onEvent(guiEvent);
        }
        break;
    case mouseUp:
        _grabbedGuiElement = null;
        dispatchMouseUpEvent(null, event.mouse.position);
        break;
    case mouseUpdate:
        _hookedGuis.length = 0;
        dispatchMouseUpdateEvent(null, event.mouse.position);

        if (_hasClicked && _hoveredGuiElement !is null) {
            _hoveredGuiElement.isHovered = true;

            if (!_wasHoveredGuiElementAlreadyHovered)
                _hoveredGuiElement.onHover();

            //Compatibility
            Event guiEvent = Event.Type.mouseUpdate;
            guiEvent.mouse.position = _hoveredGuiElementEventPosition;
            _hoveredGuiElement.onEvent(guiEvent);
        }
        break;
    case mouseWheel:
        dispatchMouseWheelEvent(event.scroll.delta);
        break;
    case quit:
        dispatchQuitEvent(null);
        if (isModal()) {
            stopAllModals();
            dispatchQuitEvent(null);
        }
        break;
    default:
        dispatchGenericEvents(null, event);
        break;
    }
}

/// Update all children of a gui. \
/// Called by the application itself.
package(atelier) void updateRoots(GuiElement gui, GuiElement parent) {
    Vec2f coords = Vec2f.zero;

    //Calculate transitions
    if (gui._timer.isRunning) {
        gui._timer.update(_deltaTime);
        const float t = gui._targetState.easing(gui._timer.value01);
        gui._currentState.offset = lerp(gui._initState.offset, gui._targetState.offset, t);

        gui._currentState.scale = lerp(gui._initState.scale, gui._targetState.scale, t);

        gui._currentState.color = lerp(gui._initState.color, gui._targetState.color, t);

        gui._currentState.alpha = lerp(gui._initState.alpha, gui._targetState.alpha, t);

        gui._currentState.angle = lerp(gui._initState.angle, gui._targetState.angle, t);
        gui.onColor();
        if (!gui._timer.isRunning) {
            if (gui._targetState.callback.length)
                gui.onCallback(gui._targetState.callback);
        }
    }

    //Calculate gui location
    const Vec2f offset = gui._position + (
            gui._size * gui._currentState.scale / 2f) + gui._currentState.offset;
    if (parent !is null) {
        if (parent.hasCanvas && parent.canvas !is null) {
            if (gui._alignX == GuiAlignX.left)
                coords.x = offset.x;
            else if (gui._alignX == GuiAlignX.right)
                coords.x = (parent._size.x * parent._currentState.scale.x) - offset.x;
            else
                coords.x = (parent._size.x * parent._currentState.scale.x) / 2f
                    + gui._currentState.offset.x + gui.position.x;

            if (gui._alignY == GuiAlignY.top)
                coords.y = offset.y;
            else if (gui._alignY == GuiAlignY.bottom)
                coords.y = (parent._size.y * parent._currentState.scale.y) - offset.y;
            else
                coords.y = (parent._size.y * parent._currentState.scale.y) / 2f
                    + gui._currentState.offset.y + gui.position.y;
        }
        else {
            if (gui._alignX == GuiAlignX.left)
                coords.x = parent.origin.x + offset.x;
            else if (gui._alignX == GuiAlignX.right)
                coords.x = parent.origin.x + (
                        parent._size.x * parent._currentState.scale.x) - offset.x;
            else
                coords.x = parent.center.x + gui._currentState.offset.x + gui.position.x;

            if (gui._alignY == GuiAlignY.top)
                coords.y = parent.origin.y + offset.y;
            else if (gui._alignY == GuiAlignY.bottom)
                coords.y = parent.origin.y + (
                        parent._size.y * parent._currentState.scale.y) - offset.y;
            else
                coords.y = parent.center.y + gui._currentState.offset.y + gui.position.y;
        }
    }
    else {
        if (gui._alignX == GuiAlignX.left)
            coords.x = offset.x;
        else if (gui._alignX == GuiAlignX.right)
            coords.x = getWindowWidth() - offset.x;
        else
            coords.x = getWindowCenter().x + gui._currentState.offset.x + gui.position.x;

        if (gui._alignY == GuiAlignY.top)
            coords.y = offset.y;
        else if (gui._alignY == GuiAlignY.bottom)
            coords.y = getWindowHeight() - offset.y;
        else
            coords.y = getWindowCenter().y + gui._currentState.offset.y + gui.position.y;
    }
    gui.setScreenCoords(coords);
    gui.update(_deltaTime);

    size_t childIndex = 0;
    while (childIndex < gui.nodes.length) {
        if (gui.nodes[childIndex]._isRegistered) {
            updateRoots(gui.nodes[childIndex], gui);
            childIndex++;
        }
        else {
            gui.removeChild(childIndex);
        }
    }
}

/// Renders a gui and all its children.
void drawRoots(GuiElement gui) {
    if (gui.hasCanvas && gui.canvas !is null) {
        auto canvas = gui.canvas;
        canvas.color(gui._currentState.color);
        canvas.alpha(gui._currentState.alpha);
        pushCanvas(canvas, true);
        gui.draw();
        foreach (GuiElement child; gui.nodes) {
            drawRoots(child);
        }
        popCanvas();
        canvas.draw(transformRenderSpace(gui._screenCoords),
                transformScale() * cast(Vec2f) canvas.renderSize(), Vec4i(0, 0,
                    canvas.width, canvas.height), gui._currentState.angle, Flip.none, Vec2f.half);
        const auto origin = gui._origin;
        const auto center = gui._center;
        gui._origin = gui._screenCoords - (gui._size * gui._currentState.scale) / 2f;
        gui._center = gui._screenCoords;
        gui.drawOverlay();
        gui._origin = origin;
        gui._center = center;
        if (gui.isHovered && gui.hint !is null)
            openHintWindow(gui.hint);
    }
    else {
        gui.draw();
        foreach (GuiElement child; gui.nodes) {
            drawRoots(child);
        }
        gui.drawOverlay();
        if (gui.isHovered && gui.hint !is null)
            openHintWindow(gui.hint);
    }
    if (_isGuiElementDebug) {
        drawRect(gui.center - (gui._size * gui._currentState.scale) / 2f,
                gui._size * gui._currentState.scale, gui.isHovered ? Color.red
                : (gui.nodes.length ? Color.blue : Color.green));
    }
}

/// Process a mouse down event down the tree.
private void dispatchMouseDownEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootElements : gui.nodes;
    bool hasCanvas;

    if (gui !is null) {
        if (gui.isInteractable && gui.isInside(cursorPosition)) {
            _clickedGuiElement = gui;
            _tempGrabbedGuiElement = null;

            if (gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            _clickedGuiElementEventPosition = cursorPosition;
            _hasClicked = true;

            if (gui._hasEventHook) {
                Event guiEvent = Event.Type.mouseDown;
                guiEvent.mouse.position = cursorPosition;
                gui.onEvent(guiEvent);
            }

            if (gui._isMovable && !_grabbedGuiElement) {
                _tempGrabbedGuiElement = gui;
                _grabbedGuiElementEventPosition = _clickedGuiElementEventPosition;
            }
        }
        else
            return;
    }

    foreach (child; children)
        dispatchMouseDownEvent(child, cursorPosition);

    if (hasCanvas)
        popCanvas();
}

/// Process a mouse up event down the tree.
private void dispatchMouseUpEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootElements : gui.nodes;
    bool hasCanvas;

    if (gui !is null) {
        if (gui.isInteractable && gui.isInside(cursorPosition)) {
            if (gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            if (gui._hasEventHook) {
                Event guiEvent = Event.Type.mouseUp;
                guiEvent.mouse.position = cursorPosition;
                gui.onEvent(guiEvent);
            }
        }
        else
            return;
    }

    foreach (child; children)
        dispatchMouseUpEvent(child, cursorPosition);

    if (hasCanvas)
        popCanvas();

    if (gui !is null && _clickedGuiElement == gui) {
        //The previous widget is now unfocused.
        if (_focusedGuiElement !is null) {
            _focusedGuiElement.hasFocus = false;
        }

        //The widget is now focused and receive the onSubmit event.
        _focusedGuiElement = _clickedGuiElement;
        _hasClicked = true;
        gui.hasFocus = true;
        gui.onSubmit();

        //Compatibility
        Event event = Event.Type.mouseUp;
        event.mouse.position = cursorPosition;
        gui.onEvent(event);
    }
    if (_clickedGuiElement !is null)
        _clickedGuiElement.isClicked = false;
}

/// Process a mouse update event down the tree.
private void dispatchMouseUpdateEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootElements : gui.nodes;
    bool hasCanvas, wasHovered;

    if (gui !is null) {
        wasHovered = gui.isHovered;

        if (gui.isInteractable && gui == _grabbedGuiElement) {
            if (!gui._isMovable) {
                _grabbedGuiElement = null;
            }
            else {
                if (gui.hasCanvas && gui.canvas !is null) {
                    pushCanvas(gui.canvas, false);
                    cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
                }
                Vec2f deltaPosition = (cursorPosition - _grabbedGuiElementEventPosition);
                if (gui._alignX == GuiAlignX.right)
                    deltaPosition.x = -deltaPosition.x;
                if (gui._alignY == GuiAlignY.bottom)
                    deltaPosition.y = -deltaPosition.y;
                gui._position += deltaPosition;
                if (gui.hasCanvas && gui.canvas !is null)
                    popCanvas();
                else
                    _grabbedGuiElementEventPosition = cursorPosition;
            }
        }

        if (gui.isInteractable && gui.isInside(cursorPosition)) {
            if (gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            //Register gui
            _wasHoveredGuiElementAlreadyHovered = wasHovered;
            _hoveredGuiElement = gui;
            _hoveredGuiElementEventPosition = cursorPosition;
            _hasClicked = true;

            if (gui._hasEventHook) {
                Event guiEvent = Event.Type.mouseUpdate;
                guiEvent.mouse.position = cursorPosition;
                gui.onEvent(guiEvent);
                _hookedGuis ~= gui;
            }
        }
        else {
            void unHoverRoots(GuiElement gui) {
                gui.isHovered = false;
                foreach (child; gui.nodes)
                    unHoverRoots(child);
            }

            unHoverRoots(gui);
            return;
        }
    }

    foreach (child; children)
        dispatchMouseUpdateEvent(child, cursorPosition);

    if (hasCanvas)
        popCanvas();
}

/// Process a mouse wheel event down the tree.
private void dispatchMouseWheelEvent(Vec2f scroll) {
    Event scrollEvent = Event.Type.mouseWheel;
    scrollEvent.scroll.delta = scroll;

    foreach (gui; _hookedGuis) {
        gui.onEvent(scrollEvent);
    }

    if (_clickedGuiElement !is null) {
        if (_clickedGuiElement.isClicked) {
            _clickedGuiElement.onEvent(scrollEvent);
            return;
        }
    }
    if (_hoveredGuiElement !is null) {
        _hoveredGuiElement.onEvent(scrollEvent);
        return;
    }
}

/// Notify every gui in the tree that we are leaving.
private void dispatchQuitEvent(GuiElement gui) {
    if (gui !is null) {
        foreach (GuiElement child; gui.nodes)
            dispatchQuitEvent(child);
        gui.onQuit();
    }
    else {
        foreach (GuiElement widget; _rootElements)
            dispatchQuitEvent(widget);
    }
}

/// Every other event that doesn't have a specific behavior like mouse events.
private void dispatchGenericEvents(GuiElement gui, Event event) {
    if (gui !is null) {
        gui.onEvent(event);
        foreach (GuiElement child; gui.nodes) {
            dispatchGenericEvents(child, event);
        }
    }
    else {
        foreach (GuiElement widget; _rootElements) {
            dispatchGenericEvents(widget, event);
        }
    }
}
/*
private void handleGuiElementEvents(GuiElement gui) {
    switch (event.type) with(Event.Type) {
    case MouseDown:
        bool hasClickedGuiElement;
        foreach(uint id, GuiElement widget; _children) {
            widget.hasFocus = false;
            if(!widget.isInteractable)
                continue;

            if(!hasClickedGuiElement && widget.isInside(_isFrame ? transformCanvasSpace(event.mouse.position, _position) : event.mouse.position)) {
                widget.hasFocus = true;
                widget.isSelected = true;
                widget.isHovered = true;
                _isChildGrabbed = true;
                _idChildGrabbed = id;

                if(_isFrame)
                    event.mouse.position = transformCanvasSpace(event.mouse.position, _position);
                widget.onEvent(event);
                hasClickedGuiElement = true;
            }
        }

        if(!_isChildGrabbed && _isMovable) {
            _isGrabbed = true;
            _lastMousePos = event.mouse.position;
        }
        break;
    case MouseUp:
        if(_isChildGrabbed) {
            _isChildGrabbed = false;
            _children[_idChildGrabbed].isSelected = false;

            if(_isFrame)
                event.mouse.position = transformCanvasSpace(event.mouse.position, _position);
            _children[_idChildGrabbed].onEvent(event);
        }
        else {
            _isGrabbed = false;
        }
        break;
    case MouseUpdate:
        _isIterating = false; //Use mouse control
        Vec2f mousePosition = event.mouse.position;
        if(_isFrame)
            event.mouse.position = transformCanvasSpace(event.mouse.position, _position);

        _isChildHovered = false;
        foreach(uint id, GuiElement widget; _children) {
            if(isHovered) {
                widget.isHovered = widget.isInside(event.mouse.position);
                if(widget.isHovered && widget.isInteractable) {
                    _isChildHovered = true;
                    widget.onEvent(event);
                }
            }
            else
                widget.isHovered = false;
        }

        if(_isChildGrabbed && !_children[_idChildGrabbed].isHovered)
            _children[_idChildGrabbed].onEvent(event);
        else if(_isGrabbed && _isMovable) {
            Vec2f deltaPosition = (mousePosition - _lastMousePos);
            if(!_isFrame) {
                //Clamp the window in the screen
                if(isModal()) {
                    Vec2f halfSize = _size / 2f;
                    Vec2f clampedPosition = _position.clamp(halfSize, screenSize - halfSize);
                    deltaPosition += (clampedPosition - _position);
                }
                _position += deltaPosition;

                foreach(widget; _children)
                    widget.position = widget.position + deltaPosition;
            }
            else
                _position += deltaPosition;
            _lastMousePos = mousePosition;
        }
        break;
    case MouseWheel:
        foreach(uint id, GuiElement widget; _children) {
            if(widget.isHovered)
                widget.onEvent(event);
        }

        if(_isChildGrabbed && !_children[_idChildGrabbed].isHovered)
            _children[_idChildGrabbed].onEvent(event);
        break;
    default:
        foreach(GuiElement widget; _children)
            widget.onEvent(event);
        break;
    }
}*/
