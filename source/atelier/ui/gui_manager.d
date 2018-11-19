module atelier.ui.gui_manager;

import std.conv: to;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element, atelier.ui.gui_overlay;

private {
	bool _isGuiElementDebug = false;
    GuiElement[] _rootGuis;
    float _deltaTime;
}

//Public
void addRootGui(GuiElement widget) {
	_rootGuis ~= widget;
}

void removeRootGuis() {
	//_isChildGrabbed = false;
	_rootGuis.length = 0uL;
}

void setRootGuis(GuiElement[] widgets) {
	_rootGuis = widgets;
}

GuiElement[] getRootGuis() {
    return _rootGuis;
}

void setDebugGui(bool isDebug) {
	_isGuiElementDebug = isDebug;
}

//Internal
void updateGuiElements(float deltaTime) {
    _deltaTime = deltaTime;
    foreach(GuiElement widget; _rootGuis) {
        updateGuiElements(widget, null);
    }
}

void drawGuiElements() {
    foreach_reverse(GuiElement widget; _rootGuis) {
        drawGuiElements(widget);
    }
}

private {
    bool _hasClicked;
    GuiElement _clickedGuiElement;
    GuiElement _focusedGuiElement;
    Canvas _canvas;
}
void handleGuiElementEvent(Event event) {
    if(isOverlay()) {
        processOverlayEvent(event);
    }

    _hasClicked = false;
    switch (event.type) with(EventType) {
    case MouseDown:
        dispatchMouseDownEvent(null, event.position);
        break;
    case MouseUp:
        dispatchMouseUpEvent(null, event.position);
        break;
    case MouseUpdate:
        dispatchMouseUpdateEvent(null, event.position);
        break;
    case Quit:
        dispatchQuitEvent(null);
        break;
    default:
        dispatchOldEvents(null, event);
        break;
    }    
}

void updateGuiElements(GuiElement gui, GuiElement parent) {
    Vec2f coords = Vec2f.zero;

    //Calculate transitions
    if(gui.timer.isRunning) {
        gui.timer.update(_deltaTime);
        const float t = gui.targetState.easingFunction(gui.timer.time);
        gui.currentState.offset = lerp(
            gui.initState.offset,
            gui.targetState.offset,
            t
        );

        gui.currentState.scale = lerp(
            gui.initState.scale,
            gui.targetState.scale,
            t
        );

        gui.currentState.color = lerp(
            gui.initState.color,
            gui.targetState.color,
            t
        );

        gui.currentState.angle = lerp(
            gui.initState.angle,
            gui.targetState.angle,
            t
        );
    }

    //Calculate gui location
    const Vec2f offset = gui.position + (gui.size / 2f) + gui.currentState.offset;
    if(parent !is null) {
        if(parent.hasCanvas && parent.canvas !is null) {
            if(gui.xalign == GuiAlignX.Left)
                coords.x = offset.x;
            else if(gui.xalign == GuiAlignX.Right)
                coords.x = parent.size.x - offset.x;
            else
                coords.x = parent.size.x / 2f + gui.currentState.offset.x;

            if(gui.yalign == GuiAlignY.Top)
                coords.y = offset.y;
            else if(gui.yalign == GuiAlignY.Bottom)
                coords.y = parent.size.y - offset.y;
            else
                coords.y = parent.size.y / 2f + gui.currentState.offset.y;
        }
        else {
            if(gui.xalign == GuiAlignX.Left)
                coords.x = parent.origin.x + offset.x;
            else if(gui.xalign == GuiAlignX.Right)
                coords.x = parent.origin.x + parent.size.x - offset.x;
            else
                coords.x = parent.center.x + gui.currentState.offset.x;

            if(gui.yalign == GuiAlignY.Top)
                coords.y = parent.origin.y + offset.y;
            else if(gui.yalign == GuiAlignY.Bottom)
                coords.y = parent.origin.y + parent.size.y - offset.y;
            else
                coords.y = parent.center.y + gui.currentState.offset.y;
        }
    }
    else {
        if(gui.xalign == GuiAlignX.Left)
            coords.x = offset.x;
        else if(gui.xalign == GuiAlignX.Right)
            coords.x = screenWidth - offset.x;
        else
            coords.x = centerScreen.x + gui.currentState.offset.x;

        if(gui.yalign == GuiAlignY.Top)
            coords.y = offset.y;
        else if(gui.yalign == GuiAlignY.Bottom)
            coords.y = screenHeight - offset.y;
        else
            coords.y = centerScreen.y + gui.currentState.offset.y;
    }
    gui.setScreenCoords(coords);
    gui.update(_deltaTime);

    foreach(GuiElement child; gui.children) {
        updateGuiElements(child, gui);
    }
}

void drawGuiElements(GuiElement gui) {
    if(gui.hasCanvas && gui.canvas !is null) {
        auto canvas = gui.canvas;
        canvas.setColorMod(gui.currentState.color, Blend.AlphaBlending);
        pushCanvas(canvas, true);
        gui.draw();
        foreach(GuiElement child; gui.children) {
            drawGuiElements(child);
        }
        popCanvas();
        canvas.draw(gui.center);
        gui.drawOverlay();
        if(gui.isHovered && gui.hint !is null)
			openHintWindow(gui.hint);
    }
    else {
        gui.draw();
        foreach(GuiElement child; gui.children) {
            drawGuiElements(child);
        }
        gui.drawOverlay();
        if(gui.isHovered && gui.hint !is null)
			openHintWindow(gui.hint);
    }
    if(_isGuiElementDebug) {
        drawRect(gui.center - gui.size / 2f, gui.size,
            gui.children.length ? Color.blue : Color.green);
    }
}

private void dispatchMouseDownEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootGuis : gui.children;
    bool hasCanvas;

    if(gui !is null) {
        if(gui.isInteractable && gui.isInside(cursorPosition)) {
            _clickedGuiElement = gui;

            if(gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui.center);
            }

            //Compatibility
            Event event = EventType.MouseDown;
            event.position = cursorPosition;
            gui.onEvent(event);
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseDownEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
}

private void dispatchMouseUpEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootGuis : gui.children;
    bool hasCanvas;

    if(gui !is null) {
        if(gui.isInteractable && gui.isInside(cursorPosition)) {
            if(gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui.center);
            }
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseUpEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
    
    if(gui !is null && _clickedGuiElement == gui) {
        //The previous widget is now unfocused.
        if(_focusedGuiElement !is null) {
            _focusedGuiElement.hasFocus = false;
        }

        //The widget is now focused and receive the onSubmit event.
        _focusedGuiElement = _clickedGuiElement;
        _hasClicked = true;
        gui.hasFocus = true;
        gui.onSubmit();

        //Compatibility
        Event event = EventType.MouseUp;
        event.position = cursorPosition;
        gui.onEvent(event);
    }
}

private void dispatchMouseUpdateEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootGuis : gui.children;
    bool hasCanvas, wasHovered;

    if(gui !is null) {
        wasHovered = gui.isHovered;
        gui.isHovered = false;

        if(gui.isInteractable && gui.isInside(cursorPosition)) {
            if(gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui.center);
            }
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseUpdateEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
    
    if(gui !is null) {
        gui.isHovered = true;

        if(!wasHovered)
            gui.onHover();

        //Compatibility
        Event event = EventType.MouseUpdate;
        event.position = cursorPosition;
        gui.onEvent(event);
    }
}

void dispatchQuitEvent(GuiElement gui) {
    if(gui !is null) {
        foreach(GuiElement child; gui.children)
            dispatchQuitEvent(child);
        gui.onQuit();
    }
    else {
        foreach(GuiElement widget; _rootGuis)
            dispatchQuitEvent(widget);
    }
}

void dispatchOldEvents(GuiElement gui, Event event) {
    if(gui !is null) {
        gui.onEvent(event);
        foreach(GuiElement child; gui.children) {
            dispatchOldEvents(child, event);
        }
    }
    else {
        foreach(GuiElement widget; _rootGuis) {
            dispatchOldEvents(widget, event);
        }
    }
}
/*
private void handleGuiElementEvents(GuiElement gui) {
    switch (event.type) with(EventType) {
    case MouseDown:
        bool hasClickedGuiElement;
        foreach(uint id, GuiElement widget; _children) {
            widget.hasFocus = false;
            if(!widget.isInteractable)
                continue;

            if(!hasClickedGuiElement && widget.isInside(_isFrame ? transformCanvasSpace(event.position, _position) : event.position)) {
                widget.hasFocus = true;
                widget.isSelected = true;
                widget.isHovered = true;
                _isChildGrabbed = true;
                _idChildGrabbed = id;

                if(_isFrame)
                    event.position = transformCanvasSpace(event.position, _position);
                widget.onEvent(event);
                hasClickedGuiElement = true;
            }
        }

        if(!_isChildGrabbed && _isMovable) {
            _isGrabbed = true;
            _lastMousePos = event.position;
        }
        break;
    case MouseUp:
        if(_isChildGrabbed) {
            _isChildGrabbed = false;
            _children[_idChildGrabbed].isSelected = false;

            if(_isFrame)
                event.position = transformCanvasSpace(event.position, _position);
            _children[_idChildGrabbed].onEvent(event);
        }
        else {
            _isGrabbed = false;
        }
        break;
    case MouseUpdate:
        _isIterating = false; //Use mouse control
        Vec2f mousePosition = event.position;
        if(_isFrame)
            event.position = transformCanvasSpace(event.position, _position);

        _isChildHovered = false;
        foreach(uint id, GuiElement widget; _children) {
            if(isHovered) {
                widget.isHovered = widget.isInside(event.position);
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