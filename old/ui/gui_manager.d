/**
    Gui Manager

    Copyright: (c) Enalye 2019
    License: Zlib
    Authors: Enalye
*/

module etabli.ui.gui_manager;

import std.conv : to;
import etabli.core, etabli.common, etabli.render;
import etabli.ui.gui_element, etabli.ui.gui_overlay, etabli.ui.gui_modal;

private {
    bool _isElementDebug = false;
    string[] _debugHoveredElements;

    UIElement[] _rootElements;
    float _deltaTime = 1f;
}

//-- Public ---

/// Add a gui as a top gui (not a node of anything).
void prependRoot(UIElement gui) {
    gui._isRegistered = true;
    _rootElements = gui ~ _rootElements;
}

/// Add a gui as a top gui (not a node of anything).
void appendRoot(UIElement gui) {
    gui._isRegistered = true;
    _rootElements ~= gui;
}

/// Remove all the top gui (that aren't a node of anything).
void removeRoots() {
    _rootElements.length = 0uL;
}

/// Set those gui as the top guis (replacing the previous ones).
void setRoots(UIElement[] guis) {
    foreach (UIElement gui; guis) {
        gui._isRegistered = true;
    }
    _rootElements = guis;
}

/// Get all the root gui.
UIElement[] getRoots() {
    return _rootElements;
}

/// Show every the hitbox of every gui element.
void setDebugGui(bool isDebug) {
    _isElementDebug = isDebug;
}

/// Show current hovered gui elements.
string[] getHoveredDebugGui() {
    return _debugHoveredElements;
}

/// Remove the specified gui from roots.
void removeRoot(UIElement gui) {
    foreach (size_t i, UIElement node; _rootElements) {
        if (node is gui) {
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
package(etabli) void updateRoots(float deltaTime) {
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
package(etabli) void drawRoots() {
    if (_isElementDebug) {
        _debugHoveredElements.length = 0;
    }

    foreach_reverse (UIElement element; _rootElements) {
        drawRoots(element);
    }
}

private {
    bool _hasClicked, _wasHoveredElementAlreadyHovered;
    UIElement _clickedElement;
    UIElement _focusedElement;
    UIElement _hoveredElement;
    UIElement _grabbedElement, _tempGrabbedElement;
    Canvas _canvas;
    Vec2f _clickedElementEventPosition = Vec2f.zero;
    Vec2f _hoveredElementEventPosition = Vec2f.zero;
    Vec2f _grabbedElementEventPosition = Vec2f.zero;
    UIElement[] _hookedGuis;
}

/// Dispatch global events on the guis from the root. \
/// Called by the main event loop.
package(etabli) void handleElementEvent(Event event) {
    if (isOverlay()) {
        processOverlayEvent(event);
    }

    _hasClicked = false;
    switch (event.type) with (Event.Type) {
    case mouseDown:
        _tempGrabbedElement = null;
        dispatchMouseDownEvent(null, event.mouse.position);

        if (_tempGrabbedElement) {
            _grabbedElement = _tempGrabbedElement;
        }

        if (_hasClicked && _clickedElement !is null) {
            _clickedElement.isClicked = true;
            Event guiEvent = Event.Type.mouseDown;
            guiEvent.mouse.position = _clickedElementEventPosition;
            _clickedElement.onEvent(guiEvent);
        }
        break;
    case mouseUp:
        _grabbedElement = null;
        dispatchMouseUpEvent(null, event.mouse.position);
        break;
    case mouseUpdate:
        _hookedGuis.length = 0;
        dispatchMouseUpdateEvent(null, event.mouse.position);

        if (_hasClicked && _hoveredElement !is null) {
            _hoveredElement.isHovered = true;

            if (!_wasHoveredElementAlreadyHovered)
                _hoveredElement.onHover();

            //Compatibility
            Event guiEvent = Event.Type.mouseUpdate;
            guiEvent.mouse.position = _hoveredElementEventPosition;
            _hoveredElement.onEvent(guiEvent);
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

/// Update all elements of a gui. \
/// Called by the application itself.
package(etabli) void updateRoots(UIElement gui, UIElement parent) {
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
                coords.x = parent._size.x - offset.x;
            else
                coords.x = parent._size.x / 2f
                    + gui._currentState.offset.x + gui.position.x;

            if (gui._alignY == GuiAlignY.top)
                coords.y = offset.y;
            else if (gui._alignY == GuiAlignY.bottom)
                coords.y = parent._size.y - offset.y;
            else
                coords.y = parent._size.y / 2f
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

    size_t nodeIndex = 0;
    while (nodeIndex < gui.nodes.length) {
        if (gui.nodes[nodeIndex]._isRegistered) {
            updateRoots(gui.nodes[nodeIndex], gui);
            nodeIndex++;
        }
        else {
            gui.removeNode(nodeIndex);
        }
    }
}

/// Force update all gui in place, but does not call update()
void forceUpdateRoots() {
    foreach (UIElement root; _rootElements) {
        _forceUpdateRoots(root, null);
    }
}
/// Ditto
private void _forceUpdateRoots(UIElement gui, UIElement parent) {
    Vec2f coords = Vec2f.zero;

    //Calculate gui location
    const Vec2f offset = gui._position + (
        gui._size * gui._currentState.scale / 2f) + gui._currentState.offset;
    if (parent !is null) {
        if (parent.hasCanvas && parent.canvas !is null) {
            if (gui._alignX == GuiAlignX.left)
                coords.x = offset.x;
            else if (gui._alignX == GuiAlignX.right)
                coords.x = parent._size.x - offset.x;
            else
                coords.x = parent._size.x / 2f
                    + gui._currentState.offset.x + gui.position.x;

            if (gui._alignY == GuiAlignY.top)
                coords.y = offset.y;
            else if (gui._alignY == GuiAlignY.bottom)
                coords.y = parent._size.y - offset.y;
            else
                coords.y = parent._size.y / 2f
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

    size_t nodeIndex = 0;
    while (nodeIndex < gui.nodes.length) {
        if (gui.nodes[nodeIndex]._isRegistered) {
            _forceUpdateRoots(gui.nodes[nodeIndex], gui);
            nodeIndex++;
        }
        else {
            gui.removeNode(nodeIndex);
        }
    }
}

/// Renders a gui and all its elements.
void drawRoots(UIElement gui) {
    if (gui.hasCanvas && gui.canvas !is null) {
        auto canvas = gui.canvas;
        canvas.color(gui._currentState.color);
        canvas.alpha(gui._currentState.alpha);
        pushCanvas(canvas, true);
        gui.draw();
        foreach (UIElement node; gui.nodes) {
            drawRoots(node);
        }
        popCanvas();
        canvas.draw(transformRenderSpace(gui._screenCoords),
            transformScale() * cast(Vec2f) canvas.renderSize() * gui._currentState.scale, Vec4i(0, 0,
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
        foreach (UIElement node; gui.nodes) {
            drawRoots(node);
        }
        gui.drawOverlay();
        if (gui.isHovered && gui.hint !is null)
            openHintWindow(gui.hint);
    }
    if (_isElementDebug) {
        if (gui.isHovered) {
            _debugHoveredElements ~= gui.classinfo.name;
        }

        drawRect(gui._screenCoords - (gui._size * gui._currentState.scale) / 2f,
            gui._size * gui._currentState.scale, gui.isHovered ? Color.red
                : (gui.nodes.length ? Color.blue : Color.green));
    }
}

/// Process a mouse down event down the tree.
private void dispatchMouseDownEvent(UIElement gui, Vec2f cursorPosition) {
    auto elements = (gui is null) ? _rootElements : gui.nodes;
    bool hasCanvas;

    if (gui !is null) {
        if (gui.isInteractable && gui.isInside(cursorPosition)) {
            _clickedElement = gui;
            _tempGrabbedElement = null;

            if (gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            _clickedElementEventPosition = cursorPosition;
            _hasClicked = true;

            if (gui._hasEventHook) {
                Event guiEvent = Event.Type.mouseDown;
                guiEvent.mouse.position = cursorPosition;
                gui.onEvent(guiEvent);
            }

            if (gui._isMovable && !_grabbedElement) {
                _tempGrabbedElement = gui;
                _grabbedElementEventPosition = _clickedElementEventPosition;
            }
        }
        else
            return;
    }

    foreach (node; elements)
        dispatchMouseDownEvent(node, cursorPosition);

    if (hasCanvas)
        popCanvas();
}

/// Process a mouse up event down the tree.
private void dispatchMouseUpEvent(UIElement gui, Vec2f cursorPosition) {
    auto elements = (gui is null) ? _rootElements : gui.nodes;
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

    foreach (node; elements)
        dispatchMouseUpEvent(node, cursorPosition);

    if (hasCanvas)
        popCanvas();

    if (gui !is null && _clickedElement == gui) {
        //The previous element is now unfocused.
        if (_focusedElement !is null) {
            _focusedElement.hasFocus = false;
        }

        //The element is now focused and receive the onSubmit event.
        _focusedElement = _clickedElement;
        _hasClicked = true;
        gui.hasFocus = true;
        gui.onSubmit();

        //Compatibility
        Event event = Event.Type.mouseUp;
        event.mouse.position = cursorPosition;
        gui.onEvent(event);
    }
    if (_clickedElement !is null)
        _clickedElement.isClicked = false;
}

package void setFocusedElement(UIElement gui) {
    if (_focusedElement == gui)
        return;
    //The previous element is now unfocused.
    if (_focusedElement !is null) {
        _focusedElement.hasFocus = false;
    }
    _focusedElement = gui;
}

/// Process a mouse update event down the tree.
private void dispatchMouseUpdateEvent(UIElement gui, Vec2f cursorPosition) {
    auto elements = (gui is null) ? _rootElements : gui.nodes;
    bool hasCanvas, wasHovered;

    if (gui !is null) {
        wasHovered = gui.isHovered;

        if (gui.isInteractable && gui == _grabbedElement) {
            if (!gui._isMovable) {
                _grabbedElement = null;
            }
            else {
                if (gui.hasCanvas && gui.canvas !is null) {
                    pushCanvas(gui.canvas, false);
                    cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
                }
                Vec2f deltaPosition = (cursorPosition - _grabbedElementEventPosition);
                if (gui._alignX == GuiAlignX.right)
                    deltaPosition.x = -deltaPosition.x;
                if (gui._alignY == GuiAlignY.bottom)
                    deltaPosition.y = -deltaPosition.y;
                gui._position += deltaPosition;
                if (gui.hasCanvas && gui.canvas !is null)
                    popCanvas();
                else
                    _grabbedElementEventPosition = cursorPosition;
            }
        }

        if (gui.isInteractable && gui.isInside(cursorPosition)) {
            if (gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            //Register gui
            _wasHoveredElementAlreadyHovered = wasHovered;
            _hoveredElement = gui;
            _hoveredElementEventPosition = cursorPosition;
            _hasClicked = true;

            if (gui._hasEventHook) {
                Event guiEvent = Event.Type.mouseUpdate;
                guiEvent.mouse.position = cursorPosition;
                gui.onEvent(guiEvent);
                _hookedGuis ~= gui;
            }
        }
        else {
            void unHoverRoots(UIElement gui) {
                gui.isHovered = false;
                foreach (node; gui.nodes)
                    unHoverRoots(node);
            }

            unHoverRoots(gui);
            return;
        }
    }

    foreach (node; elements)
        dispatchMouseUpdateEvent(node, cursorPosition);

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

    if (_clickedElement !is null) {
        if (_clickedElement.isClicked) {
            _clickedElement.onEvent(scrollEvent);
            return;
        }
    }
    if (_hoveredElement !is null) {
        _hoveredElement.onEvent(scrollEvent);
        return;
    }
}

/// Notify every gui in the tree that we are leaving.
private void dispatchQuitEvent(UIElement gui) {
    if (gui !is null) {
        foreach (UIElement node; gui.nodes)
            dispatchQuitEvent(node);
        gui.onQuit();
    }
    else {
        foreach (UIElement element; _rootElements)
            dispatchQuitEvent(element);
    }
}

/// Every other event that doesn't have a specific behavior like mouse events.
private void dispatchGenericEvents(UIElement gui, Event event) {
    if (gui !is null) {
        gui.onEvent(event);
        foreach (UIElement node; gui.nodes) {
            dispatchGenericEvents(node, event);
        }
    }
    else {
        foreach (UIElement element; _rootElements) {
            dispatchGenericEvents(element, event);
        }
    }
}
/*
private void handleElementEvents(UIElement gui) {
    switch (event.type) with(Event.Type) {
    case MouseDown:
        bool hasClickedElement;
        foreach(uint id, UIElement element; _elements) {
            element.hasFocus = false;
            if(!element.isInteractable)
                continue;

            if(!hasClickedElement && element.isInside(_isFrame ? transformCanvasSpace(event.mouse.position, _position) : event.mouse.position)) {
                element.hasFocus = true;
                element.isSelected = true;
                element.isHovered = true;
                _isNodeGrabbed = true;
                _idNodeGrabbed = id;

                if(_isFrame)
                    event.mouse.position = transformCanvasSpace(event.mouse.position, _position);
                element.onEvent(event);
                hasClickedElement = true;
            }
        }

        if(!_isNodeGrabbed && _isMovable) {
            _isGrabbed = true;
            _lastMousePos = event.mouse.position;
        }
        break;
    case MouseUp:
        if(_isNodeGrabbed) {
            _isNodeGrabbed = false;
            _elements[_idNodeGrabbed].isSelected = false;

            if(_isFrame)
                event.mouse.position = transformCanvasSpace(event.mouse.position, _position);
            _elements[_idNodeGrabbed].onEvent(event);
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

        _isNodeHovered = false;
        foreach(uint id, UIElement element; _elements) {
            if(isHovered) {
                element.isHovered = element.isInside(event.mouse.position);
                if(element.isHovered && element.isInteractable) {
                    _isNodeHovered = true;
                    element.onEvent(event);
                }
            }
            else
                element.isHovered = false;
        }

        if(_isNodeGrabbed && !_elements[_idNodeGrabbed].isHovered)
            _elements[_idNodeGrabbed].onEvent(event);
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

                foreach(element; _elements)
                    element.position = element.position + deltaPosition;
            }
            else
                _position += deltaPosition;
            _lastMousePos = mousePosition;
        }
        break;
    case MouseWheel:
        foreach(uint id, UIElement element; _elements) {
            if(element.isHovered)
                element.onEvent(event);
        }

        if(_isNodeGrabbed && !_elements[_idNodeGrabbed].isHovered)
            _elements[_idNodeGrabbed].onEvent(event);
        break;
    default:
        foreach(UIElement element; _elements)
            element.onEvent(event);
        break;
    }
}*/
