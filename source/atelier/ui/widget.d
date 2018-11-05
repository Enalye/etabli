/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module atelier.ui.widget;

import atelier.render.window;
import atelier.core;
import atelier.common;

import atelier.ui.overlay;
import atelier.ui.modal;

private {
	bool _isWidgetDebug = false;
}

void setWidgetDebug(bool isDebug) {
	_isWidgetDebug = isDebug;
}

interface IMainWidget {
	void onEvent(Event event);
}

class Widget {
	private {
		Hint _hint;
		bool _isLocked = false, _isMovable = false, _isHovered = false, _isSelected = false, _isValidated = false, _hasFocus = false, _isInteractable = true;
		Vec2f _position = Vec2f.zero, _size = Vec2f.zero, _anchor = Vec2f.half, _padding = Vec2f.zero, _pivot = Vec2f.zero;
		float _angle = 0f;
		Widget _callbackWidget;
		string _callbackId;
	}

	@property {
		final bool isLocked() const { return _isLocked; }
		final bool isLocked(bool newIsLocked) {
            if(newIsLocked != _isLocked) {
                _isLocked = newIsLocked;
                onLock();
                return _isLocked;
            }
            return _isLocked = newIsLocked;
        }

		final bool isMovable() const { return _isMovable; }
		final bool isMovable(bool newIsMovable) {
            if(newIsMovable != _isMovable) {
                _isMovable = newIsMovable;
                onMovable();
                return _isMovable;
            }
            return _isMovable = newIsMovable;
        }

		final bool isHovered() const { return _isHovered; }
		final bool isHovered(bool newIsHovered) {
            if(newIsHovered != _isHovered) {
                _isHovered = newIsHovered;
                onHover();
                return _isHovered;
            }
            return _isHovered = newIsHovered;
        }

		final bool isSelected() const { return _isSelected; }
		final bool isSelected(bool newIsSelected) {
            if(newIsSelected != _isSelected) {
                _isSelected = newIsSelected;
                onSelect();
                return _isSelected;
            }
            return _isSelected = newIsSelected;
        }

		final bool hasFocus() const { return _hasFocus; }
		final bool hasFocus(bool newHasFocus) {
            if(newHasFocus != _hasFocus) {
                _hasFocus = newHasFocus;
                onFocus();
                return _hasFocus;
            }
            return _hasFocus = newHasFocus;
        }

		final bool isInteractable() const { return _isInteractable; }
		final bool isInteractable(bool newIsInteractable) {
            if(newIsInteractable != _isInteractable) {
                _isInteractable = newIsInteractable;
                onInteractable();
                return _isInteractable;
            }
            return _isInteractable = newIsInteractable;
        }

		final bool isValidated() const { return _isValidated; }
		final bool isValidated(bool newIsValidated) {
            if(newIsValidated != _isValidated) {
                _isValidated = newIsValidated;
                onValidate();
                return _isValidated;
            }
            return _isValidated = newIsValidated;         
        }

		final Vec2f position() { return _position; }
		final Vec2f position(Vec2f newPosition) {
            auto oldPosition = _position;
            _position = newPosition;
			_pivot = _position + _size * (Vec2f.half - _anchor);
            onDeltaPosition(newPosition - oldPosition);
            onPosition();
            onPivot();
            return _position;
        }

		final Vec2f size() const { return _size; }
		final Vec2f size(Vec2f newSize) {
            auto oldSize = _size;
            _size = newSize - _padding;
			_pivot = _position + _size * (Vec2f.half - _anchor);
            onDeltaSize(_size - oldSize);         
            onSize();
            onPivot();
            return _size;
        }

		final Vec2f anchor() const { return _anchor; }
		final Vec2f anchor(Vec2f newAnchor) {
            auto oldAnchor = _anchor;
            _anchor = newAnchor;
			_pivot = _position + _size * (Vec2f.half - _anchor);            
            onDeltaAnchor(newAnchor - oldAnchor);
            onAnchor();
            onPivot();
            return _anchor;
        }

		final Vec2f pivot() const { return _pivot; }

		final Vec2f padding() const { return _padding; }
		final Vec2f padding(Vec2f newPadding) {
            _padding = newPadding;
			size(_size);
            onPadding();
            return _padding;
        }

		final float angle() const { return _angle; }
		final float angle(float newAngle) {
            _angle = newAngle;
            onAngle();
            return _angle;
        }
	}

	this() {}

	bool isInside(const Vec2f pos) const {
		Vec2f collision = _size + _padding;
		return (_position - pos).isBetween(-collision * (Vec2f.one - anchor), collision * _anchor);
	}

	bool isOnInteractableWidget(Vec2f pos) const {
		if(isInside(pos))
			return _isInteractable;
		return false;
	}

	void setHint(string title, string text = "") {
		_hint = makeHint(title, text);
	}

	void drawOverlay() {
		if(_isHovered && _hint !is null)
			openHintWindow(_hint);

		if(_isWidgetDebug)
			drawRect(_position - _anchor * _size, _size, Color.green);
	}

	void setCallback(Widget callbackWidget, string callbackId) {
		_callbackWidget = callbackWidget;
		_callbackId = callbackId;
	}

	protected void triggerCallback() {
		if(_callbackWidget !is null) {
			_callbackWidget.onCallback(_callbackId);
		}
	}

	void update(float deltaTime) {};
	void draw() {};

    //deprecated("Use onSubmit or onCancel instead.")
	void onEvent(Event event) {};

    //Will replace the old onEvent eventually
    package {
        void onSubmit() {}
        void onCancel() {}
    }

    protected {
        void onLock() {}
        void onMovable() {}
        void onHover() {}
        void onSelect() {}
        void onFocus() {}
        void onInteractable() {}
        void onValidate() {}
        void onDeltaPosition(Vec2f delta) {}
        void onPosition() {}
        void onDeltaSize(Vec2f delta) {}
        void onSize() {}
        void onDeltaAnchor(Vec2f delta) {}
        void onAnchor() {}
        void onPivot() {}
        void onPadding() {}
        void onAngle() {}
        void onCallback(string id) {}
    }
}

class WidgetGroup: Widget {
	protected {
		Widget[] _children;
		bool _isFrame = false;

        //Mouse control        
		Vec2f _lastMousePos;
		bool _isGrabbed = false, _isChildGrabbed = false, _isChildHovered = false;
		uint _idChildGrabbed;

        //Iteration
        bool _isIterating, _isWarping = true;
        uint _idChildIterator;
        Timer _iteratorTimer, _iteratorTimeOutTimer;
	}

	@property {
		const(Widget[]) children() const { return _children; }
		Widget[] children() { return _children; }
	}

	override void update(float deltaTime) {
        _iteratorTimer.update(deltaTime);
        _iteratorTimeOutTimer.update(deltaTime);
		foreach(Widget widget; _children)
			widget.update(deltaTime);
	}

    override void onHover() {
        if(!_isHovered) {
            foreach(Widget widget; _children)
                widget.isHovered = false;
        }
    }
	
	override void onEvent(Event event) {
		switch (event.type) with(EventType) {
		case MouseDown:
			bool hasClickedWidget;
			foreach(uint id, Widget widget; _children) {
				widget.hasFocus = false;
				if(!widget.isInteractable)
					continue;

				if(!hasClickedWidget && widget.isInside(_isFrame ? getViewVirtualPos(event.position, _position) : event.position)) {
					widget.hasFocus = true;
					widget.isSelected = true;
					widget.isHovered = true;
					_isChildGrabbed = true;
					_idChildGrabbed = id;

					if(_isFrame)
						event.position = getViewVirtualPos(event.position, _position);
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
					event.position = getViewVirtualPos(event.position, _position);
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
				event.position = getViewVirtualPos(event.position, _position);

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
		case Callback:
			//We musn't propagate the callback further, so it's catched here.
			break;
		default:
			foreach(Widget widget; _children)
				widget.onEvent(event);
			break;
		}
	}
    
    override void onDeltaPosition(Vec2f delta) {
        if(!_isFrame) {
            foreach(widget; _children)
                widget.position = widget.position + delta;
        }
    }

	override void draw() {
		foreach_reverse(Widget widget; _children)
			widget.draw();
	}

	override bool isOnInteractableWidget(Vec2f pos) const {
		if(!isInside(pos))
			return false;

		if(_isFrame)
			pos = getViewVirtualPos(pos, _position);
		
		foreach(const Widget widget; _children) {
			if(widget.isOnInteractableWidget(pos))
				return true;
		}
		return false;
	}

	void addChild(Widget widget) {
		_children ~= widget;
	}

	void removeChildren() {
        _isChildGrabbed = false;
		_children.length = 0uL;
	}

	int getChildrenCount() {
		return cast(int)(_children.length);
	}

	void removeChild(uint id) {
        _isChildGrabbed = false;
        _isChildHovered = false;
		if(!_children.length)
			return;
		if(id + 1u == _children.length)
			_children.length --;
		else if(id == 0u)
			_children = _children[1..$];
		else
			_children = _children[0..id]  ~ _children[id + 1..$];
	}
	
	override void drawOverlay() {
		if(_isWidgetDebug)
			drawRect(_position - _anchor * _size, _size, Color.cyan);

		if(!_isHovered)
			return;

		if(_hint !is null)
			openHintWindow(_hint);

		foreach(widget; _children)
			widget.drawOverlay();
	}

    //Iteration
    private void setupIterationTimer(float time) {
        _iteratorTimer.start(time);
        _iteratorTimeOutTimer.start(5f);
    }

    private bool startIteration() {
        if(_isIterating)
            return _iteratorTimeOutTimer.isRunning;
        _isIterating = true;
        
        //If a child was hovered, we start from here
        if(_isChildHovered) {
            foreach(i; 0.. _children.length) {
                if(_children[i].isHovered) {
                    _idChildIterator = cast(int)i;
                    break;
                }
            }
        }
        else
            _idChildIterator = 0u;
        return false;
    }

    void stopChild() {
        _iteratorTimeOutTimer.stop();
    }

    void previousChild() {
        bool wasIterating = startIteration();
        if(_iteratorTimer.isRunning)
            return;
        setupIterationTimer(wasIterating ? .15f : .35f);
        if(_idChildIterator == 0u) {
            if(_children.length < 1)
                return;
            if(_isWarping)
                _idChildIterator = (cast(int)_children.length) - 1;
            else return;
        }
        else _idChildIterator --;

        foreach(uint id, Widget widget; _children)
            widget.isHovered = (id == _idChildIterator);
    }

    void nextChild() {
        bool wasIterating = startIteration();
        if(_iteratorTimer.isRunning)
            return;
        setupIterationTimer(wasIterating ? .15f : .35f);
        if(_idChildIterator + 1u == _children.length) {
            if(_children.length < 1)
                return;
            if(_isWarping)
                _idChildIterator = 0u;
            else return;
        }
        else _idChildIterator ++;

        foreach(uint id, Widget widget; _children)
            widget.isHovered = (id == _idChildIterator);
    }

    Widget selectChild() {
        startIteration();

        if(_idChildIterator < _children.length)
            return _children[_idChildIterator];
        return null;
    }
}