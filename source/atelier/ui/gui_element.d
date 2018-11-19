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

module atelier.ui.gui_element;

import atelier.render, atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_overlay;

enum GuiAlignX {
    Left, Center, Right
}

enum GuiAlignY {
    Top, Center, Bottom
}

struct GuiState {
    Vec2f offset = Vec2f.zero;
    Vec2f scale = Vec2f.one;
    Color color = Color.white;
    float angle = 0f;
    float time = .5f;
    EasingFunction easingFunction = &easeLinear;
}

class GuiElement {
    private {
        Canvas _canvas;
        bool _hasCanvas;
    }

    string currentStateName = "default";
    GuiState currentState, targetState, initState;
    GuiState[string] states;
    Timer timer;

    GuiAlignX xalign = GuiAlignX.Left;
    GuiAlignY yalign = GuiAlignY.Top;

    //Transition
    

    void doTransitionState(string stateName) {
        auto ptr = stateName in states;
        if(!(ptr))
            throw new Exception("No state " ~ stateName ~ " in GuiElement");
        currentStateName = stateName;
        initState = currentState;
        targetState = *ptr;
        timer.start(targetState.time);
    }

    void setState(string stateName) {
        auto ptr = stateName in states;
        if(!(ptr))
            throw new Exception("No state " ~ stateName ~ " in GuiElement");
        currentStateName = stateName;
        initState = *ptr;
        targetState = *ptr;
        currentState = *ptr;
    }

    void setAlign(GuiAlignX x, GuiAlignY y) {
        xalign = x;
        yalign = y;
    }

    void setScreenCoords(Vec2f screenCoords) {
        _center = screenCoords;
        _origin = _center - _size / 2f;
    }

	protected {
		GuiElement[] _children;
		Hint _hint;
		bool _isLocked = false, _isMovable = false, _isHovered = false, _isSelected = false, _isValidated = false, _hasFocus = false, _isInteractable = true;
		Vec2f _position = Vec2f.zero, _size = Vec2f.zero, _anchor = Vec2f.half, _padding = Vec2f.zero, _center = Vec2f.zero, _origin = Vec2f.zero;
		//float _angle = 0f;
		GuiElement _callbackGuiElement;
		string _callbackId;

        //Iteration
        bool _isIterating, _isWarping = true;
        uint _idChildIterator;
        Timer _iteratorTimer, _iteratorTimeOutTimer;
	}

	@property {
        final Canvas canvas() { return _canvas; }
        final bool hasCanvas() const { return _hasCanvas; }

        final Hint hint() { return _hint; }

        const(GuiElement[]) children() const { return _children; }
		GuiElement[] children() { return _children; }

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
            /*if(newIsHovered != _isHovered) {
                _isHovered = newIsHovered;
                onHover();
                return _isHovered;
            }*/
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
            /*if(newHasFocus != _hasFocus) {
                _hasFocus = newHasFocus;
                onFocus();
                return _hasFocus;
            }*/
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
            onDeltaPosition(newPosition - oldPosition);
            onPosition();
            onCenter();
            return _position;
        }

		final Vec2f size() const { return _size; }
		final Vec2f size(Vec2f newSize) {
            auto oldSize = _size;
            _size = newSize - _padding;

            if(_hasCanvas && oldSize != newSize) {
                Canvas newCanvas;
                if(_size.x > 2f && _size.y > 2f)
                    newCanvas = new Canvas(_size);
                else
                    newCanvas = new Canvas(Vec2u.one * 2);
                newCanvas.position = _canvas.position;
                _canvas = newCanvas;
                _canvas.position = _canvas.size / 2f;
            }

            onDeltaSize(_size - oldSize);         
            onSize();
            onCenter();
            return _size;
        }

		final Vec2f anchor() const { return _anchor; }
		final Vec2f anchor(Vec2f newAnchor) {
            auto oldAnchor = _anchor;
            _anchor = newAnchor;
            onDeltaAnchor(newAnchor - oldAnchor);
            onAnchor();
            onCenter();
            return _anchor;
        }

        /*
            Old algorithm:
            _position + _size * (Vec2f.half - _anchor);
        */
		final Vec2f center() const { return _center; }
		final Vec2f origin() const { return _origin; }

		final Vec2f padding() const { return _padding; }
		final Vec2f padding(Vec2f newPadding) {
            _padding = newPadding;
			size(_size);
            onPadding();
            return _padding;
        }

		final float angle() const { return currentState.angle; }
		/*final float angle(float newAngle) {
            _angle = newAngle;
            onAngle();
            return _angle;
        }*/
	}

	this() {}

    private final initCanvas() {
        _hasCanvas = true;
        if(_size.x > 2f && _size.y > 2f)
            _canvas = new Canvas(_size);
        else
            _canvas = new Canvas(Vec2u.one * 2);
        _canvas.position = _canvas.size / 2f;
    }

	bool isInside(const Vec2f pos) const {
        return (_center - pos).isBetween(-size / 2f, _size / 2f);

		//Vec2f collision = _size + _padding;
		//return (_position - pos).isBetween(-collision * (Vec2f.one - anchor), collision * _anchor);
	}

	bool isOnInteractableGuiElement(Vec2f pos) const {
		if(isInside(pos))
			return _isInteractable;
		return false;
	}

	void setHint(string title, string text = "") {
		_hint = makeHint(title, text);
	}

	void setCallback(GuiElement callbackGuiElement, string callbackId) {
		_callbackGuiElement = callbackGuiElement;
		_callbackId = callbackId;
	}

	protected void triggerCallback() {
		if(_callbackGuiElement !is null) {
			_callbackGuiElement.onCallback(_callbackId);
		}
	}

    //Update and rendering
	void update(float deltaTime) {}
	void draw() {}
	void drawOverlay() {}

    //All events
	void onEvent(Event event) {}

    //Special events
    void onSubmit() {}
    void onCancel() {}
    void onNextTab() {}
    void onPreviousTab() {}
    void onUp() {}
    void onDown() {}
    void onLeft() {}
    void onRight() {}
    void onQuit() {}

    public {
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
        void onCenter() {}
        void onPadding() {}
        //void onAngle() {}
        void onCallback(string id) {}
    }

    void addChildGui(GuiElement widget) {
		_children ~= widget;
	}

	void removeChildrenGuis() {
		_children.length = 0uL;
	}

	int getChildrenGuisCount() {
		return cast(int)(_children.length);
	}

	void removeChildGui(uint id) {
		if(!_children.length)
			return;
		if(id + 1u == _children.length)
			_children.length --;
		else if(id == 0u)
			_children = _children[1..$];
		else
			_children = _children[0..id]  ~ _children[id + 1..$];
	}
}

class GuiElementCanvas: GuiElement {
    this() {
        initCanvas();
    }
}
/+
class GuiElementGroup: GuiElement {
	/*override void update(float deltaTime) {
        _iteratorTimer.update(deltaTime);
        _iteratorTimeOutTimer.update(deltaTime);
		foreach(GuiElement widget; _children)
			widget.update(deltaTime);
	}

    override void onHover() {
        if(!_isHovered) {
            foreach(GuiElement widget; _children)
                widget.isHovered = false;
        }
    }
    
    override void onDeltaPosition(Vec2f delta) {
        if(!_isFrame) {
            foreach(widget; _children)
                widget.position = widget.position + delta;
        }
    }

	override bool isOnInteractableGuiElement(Vec2f pos) const {
		if(!isInside(pos))
			return false;

		if(_isFrame)
			pos = getViewVirtualPos(pos, _position);
		
		foreach(const GuiElement widget; _children) {
			if(widget.isOnInteractableGuiElement(pos))
				return true;
		}
		return false;
	}*/

	
	
	override void drawOverlay() {
		//if(_isGuiElementDebug)
		//	drawRect(_position - _anchor * _size, _size, Color.cyan);

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

        foreach(uint id, GuiElement widget; _children)
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

        foreach(uint id, GuiElement widget; _children)
            widget.isHovered = (id == _idChildIterator);
    }

    GuiElement selectChild() {
        startIteration();

        if(_idChildIterator < _children.length)
            return _children[_idChildIterator];
        return null;
    }
}+/