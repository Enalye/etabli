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

module ui.widget;

import render.window;
import core.all;
import common.all;

import ui.overlay;
import ui.modal;

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
	protected {
		Hint _hint;
		bool _isLocked = false, _isMovable = false, _isHovered = false, _isSelected = false, _isValidated = false, _hasFocus = false, _isInteractable = true;
		Vec2f _position = Vec2f.zero, _size = Vec2f.zero, _anchor = Vec2f.half;
		float _angle = 0f;
		Widget _callbackWidget;
		string _callbackId;
	}

	@property {
		bool isLocked() const { return _isLocked; }
		bool isLocked(bool newIsLocked) { return _isLocked = newIsLocked; }

		bool isMovable() const { return _isMovable; }
		bool isMovable(bool newIsMovable) { return _isMovable = newIsMovable; }

		bool isHovered() const { return _isHovered; }
		bool isHovered(bool newIsHovered) { return _isHovered = newIsHovered; }

		bool isSelected() const { return _isSelected; }
		bool isSelected(bool newIsSelected) { return _isSelected = newIsSelected; }

		bool hasFocus() const { return _hasFocus; }
		bool hasFocus(bool newHasFocus) { return _hasFocus = newHasFocus; }

		bool isInteractable() const { return _isInteractable; }
		bool isInteractable(bool newIsSelectable) { return _isInteractable = newIsSelectable; }

		bool isValidated() const { return _isValidated; }
		bool isValidated(bool newIsValidated) { return _isValidated = newIsValidated; }

		Vec2f position() { return _position; }
		Vec2f position(Vec2f newPosition) { return _position = newPosition; }

		Vec2f size() const { return _size; }
		Vec2f size(Vec2f newSize) { return _size = newSize; }

		Vec2f anchor() const { return _anchor; }
		Vec2f anchor(Vec2f newAnchor) { return _anchor = newAnchor; }

		Vec2f anchoredPosition() const {
			return _position + _size * (Vec2f.half - _anchor);
		}

		float angle() const { return _angle; }
		float angle(float newAngle) { return _angle = newAngle; }
	}

	this() {}

	bool isInside(const Vec2f pos) const {
		return (_position - pos).isBetween(-_size * (Vec2f.one - anchor), _size * _anchor);
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

	void setCallback(string callbackId, Widget widget) {
		_callbackWidget = widget;
		_callbackId = callbackId;
	}

	protected void triggerCallback() {
		if(_callbackWidget !is null) {
			Event ev = EventType.Callback;
			ev.id = _callbackId;
			ev.widget = this;
			_callbackWidget.onEvent(ev);
		}
	}

	abstract void update(float deltaTime);
	abstract void onEvent(Event event);
	abstract void draw();
}

class WidgetGroup: Widget {
	protected {
		Widget[] _children;
		Vec2f _lastMousePos;
		bool _isGrabbed = false, _isChildGrabbed = false, _isChildHovered = false;
		uint _idChildGrabbed;
		bool _isFrame = false;
	}

	@property {
		alias isHovered = super.isHovered;
		override bool isHovered(bool hovered) {
			if(!hovered)
				foreach(Widget widget; _children)
					widget.isHovered = false;
			return _isHovered = hovered;
		}

		alias position = super.position;
		override Vec2f position(Vec2f newPosition) {
			if(!_isFrame) {
				Vec2f deltaPosition = newPosition - _position;
				foreach(widget; _children)
					widget.position = widget.position + deltaPosition;
			}
			_position = newPosition;
			return _position;
		}

		const(Widget[]) children() const { return _children; }
		Widget[] children() { return _children; }
	}

	override void update(float deltaTime) {
		foreach(Widget widget; _children)
			widget.update(deltaTime);
	}
	
	override void onEvent(Event event) {
		switch (event.type) with(EventType) {
		case MouseDown:
			bool hasClickedWidget = false;
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
		_children.length = 0uL;
	}

	int getChildrenCount() {
		return cast(int)(_children.length);
	}

	void removeChild(uint id) {
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
}