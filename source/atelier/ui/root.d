module atelier.ui.root;

import std.conv: to;

import atelier.core;
import atelier.common;
import atelier.render;
import atelier.ui.widget, atelier.ui.overlay;

private {
	bool _isWidgetDebug = false;
    Widget[] _widgets;
    float _deltaTime;
}

void initializeUI() {
    _canvas = new Canvas(screenSize);
}

//Public
void addWidget(Widget widget) {
	_widgets ~= widget;
}

void removeWidgets() {
	//_isChildGrabbed = false;
	_widgets.length = 0uL;
}

void setWidgets(Widget[] widgets) {
	_widgets = widgets;
}

Widget[] getWidgets() {
    return _widgets;
}

void setWidgetDebug(bool isDebug) {
	_isWidgetDebug = isDebug;
}

//Internal
void updateWidgets(float deltaTime) {
    _deltaTime = deltaTime;
    foreach(Widget widget; _widgets) {
        updateWidgets(widget);
    }
}

void drawWidgets() {
    foreach_reverse(Widget widget; _widgets) {
        drawWidgets(widget);
    }
}

private {
    bool _hasClicked;
    Widget _clickedWidget;
    Widget _focusedWidget;
    Canvas _canvas;
}
void handleWidgetEvent(Event event) {
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

void updateWidgets(Widget parent) {
    parent.update(_deltaTime);
    foreach(Widget child; parent.children) {
        updateWidgets(child);
    }
}

void drawWidgets(Widget parent) {
    if(parent.hasCanvas && parent.canvas !is null) {
        auto canvas = parent.canvas;
        pushCanvas(canvas, true);
        parent.draw();
        foreach(Widget child; parent.children) {
            drawWidgets(child);
        }
        popCanvas();
        canvas.draw(parent.pivot);
        parent.drawOverlay();
        if(parent.isHovered && parent.hint !is null)
			openHintWindow(parent.hint);
    }
    else {
        parent.draw();
        foreach(Widget child; parent.children) {
            drawWidgets(child);
        }
        parent.drawOverlay();
        if(parent.isHovered && parent.hint !is null)
			openHintWindow(parent.hint);
    }
    if(_isWidgetDebug) {
        drawRect(parent.pivot - parent.size / 2f, parent.size,
            parent.children.length ? Color.blue : Color.green);
    }
}

private void dispatchMouseDownEvent(Widget parent, Vec2f cursorPosition) {
    auto children = (parent is null) ? _widgets : parent.children;
    bool hasCanvas;

    if(parent !is null) {
        if(parent.isInteractable && parent.isInside(cursorPosition)) {
            _clickedWidget = parent;

            if(parent.hasCanvas && parent.canvas !is null) {
                hasCanvas = true;
                pushCanvas(parent.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, parent.pivot);
            }

            //Compatibility
            Event event = EventType.MouseDown;
            event.position = cursorPosition;
            parent.onEvent(event);
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseDownEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
}

private void dispatchMouseUpEvent(Widget parent, Vec2f cursorPosition) {
    auto children = (parent is null) ? _widgets : parent.children;
    bool hasCanvas;

    if(parent !is null) {
        if(parent.isInteractable && parent.isInside(cursorPosition)) {
            if(parent.hasCanvas && parent.canvas !is null) {
                hasCanvas = true;
                pushCanvas(parent.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, parent.pivot);
            }
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseUpEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
    
    if(parent !is null && _clickedWidget == parent) {
        //The previous widget is now unfocused.
        if(_focusedWidget !is null) {
            _focusedWidget.hasFocus = false;
        }

        //The widget is now focused and receive the onSubmit event.
        _focusedWidget = _clickedWidget;
        _hasClicked = true;
        parent.hasFocus = true;
        parent.onSubmit();

        //Compatibility
        Event event = EventType.MouseUp;
        event.position = cursorPosition;
        parent.onEvent(event);
    }
}

private void dispatchMouseUpdateEvent(Widget parent, Vec2f cursorPosition) {
    auto children = (parent is null) ? _widgets : parent.children;
    bool hasCanvas, wasHovered;

    if(parent !is null) {
        wasHovered = parent.isHovered;
        parent.isHovered = false;

        if(parent.isInteractable && parent.isInside(cursorPosition)) {
            if(parent.hasCanvas && parent.canvas !is null) {
                hasCanvas = true;
                pushCanvas(parent.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, parent.position);
            }
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseUpdateEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
    
    if(parent !is null) {
        parent.isHovered = true;

        if(!wasHovered)
            parent.onHover();

        //Compatibility
        Event event = EventType.MouseUpdate;
        event.position = cursorPosition;
        parent.onEvent(event);
    }
}

void dispatchQuitEvent(Widget parent) {
    if(parent !is null) {
        foreach(Widget child; parent.children)
            dispatchQuitEvent(child);
        parent.onQuit();
    }
    else {
        foreach(Widget widget; _widgets)
            dispatchQuitEvent(widget);
    }
}

void dispatchOldEvents(Widget parent, Event event) {
    if(parent !is null) {
        parent.onEvent(event);
        foreach(Widget child; parent.children) {
            dispatchOldEvents(child, event);
        }
    }
    else {
        foreach(Widget widget; _widgets) {
            dispatchOldEvents(widget, event);
        }
    }
}
/*
private void handleWidgetEvents(Widget parent) {
    switch (event.type) with(EventType) {
    case MouseDown:
        bool hasClickedWidget;
        foreach(uint id, Widget widget; _children) {
            widget.hasFocus = false;
            if(!widget.isInteractable)
                continue;

            if(!hasClickedWidget && widget.isInside(_isFrame ? transformCanvasSpace(event.position, _position) : event.position)) {
                widget.hasFocus = true;
                widget.isSelected = true;
                widget.isHovered = true;
                _isChildGrabbed = true;
                _idChildGrabbed = id;

                if(_isFrame)
                    event.position = transformCanvasSpace(event.position, _position);
                widget.onEvent(event);
                hasClickedWidget = true;
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
        foreach(uint id, Widget widget; _children) {
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
        foreach(uint id, Widget widget; _children) {
            if(widget.isHovered)
                widget.onEvent(event);
        }

        if(_isChildGrabbed && !_children[_idChildGrabbed].isHovered)
            _children[_idChildGrabbed].onEvent(event);
        break;
    default:
        foreach(Widget widget; _children)
            widget.onEvent(event);
        break;
    }
}*/