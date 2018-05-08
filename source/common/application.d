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

module common.application;

import derelict.sdl2.sdl;

import core.thread;
import std.datetime;

import core.all;
import render.all;
import ui.all;
import script.all;

import common.event;
import common.settings;
import common.resource;

private Application _application;
uint nominalFps = 60u;

void createApplication(Vec2u size, string title = "Grimoire") {
	if(_application !is null)
		throw new Exception("The application cannot be run twice.");
	_application = new Application(size, title);
}

void runApplication() {
	if(_application is null)
		throw new Exception("Cannot run the application.");
	_application.run();
}

void addWidget(Widget widget) {
	if(_application is null)
		throw new Exception("The application is not running.");
	_application.addChild(widget);
}

void removeWidgets() {
	if(_application is null)
		throw new Exception("The application is not running.");
	_application.removeChildren();
}

void setWidgets(Widget[] widgets) {
	if(_application is null)
		throw new Exception("The application is not running.");
	_application.setChildren(widgets);
}

Widget[] getWidgets() {
	if(_application is null)
		throw new Exception("The application is not running.");
	return _application.getChildren();
}

private class Application: IMainWidget {
	private {
		float _deltaTime = 1f;
		float _currentFps;
		long _tickStartFrame;

		bool _isChildGrabbed;
		uint _idChildGrabbed;
		Widget[] _children;
	}

	@property {
		float deltaTime() const { return _deltaTime; }
		float currentFps() const { return _currentFps; }
	}

	this(Vec2u size, string title) {
		initializeEvents();
		createWindow(size, title);
		loadResources();
		initializeOverlay();
		loadPrimitives();
		_tickStartFrame = Clock.currStdTime();
	}

	~this() {
		destroyWindow();
	}

	void onEvent(Event event) {
		if(isOverlay()) {
			_isChildGrabbed = false;
			processOverlayEvent(event);
			return;
		}

		switch(event.type) with(EventType) {
		case MouseDown:
			bool hasClickedWidget = false;
			foreach(uint id, Widget widget; _children) {
				widget.hasFocus = false;
				if(!widget.isInteractable)
					continue;

				if(!hasClickedWidget && widget.isInside(event.position)) {
					widget.hasFocus = true;
					widget.isSelected = true;
					widget.isHovered = true;
					_isChildGrabbed = true;
					_idChildGrabbed = id;
					widget.onEvent(event);
					hasClickedWidget = true;
				}
			}
			break;
		case MouseUp:
			if(_isChildGrabbed) {
				_isChildGrabbed = false;
				_children[_idChildGrabbed].isSelected = false;
				_children[_idChildGrabbed].onEvent(event);
			}
			break;
		case MouseUpdate:
			foreach(uint id, Widget widget; _children) {
				widget.isHovered = widget.isInside(event.position);
				if(widget.isHovered)
					widget.onEvent(event);
			}

			if(_isChildGrabbed && !_children[_idChildGrabbed].isHovered)
				_children[_idChildGrabbed].onEvent(event);
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
			foreach (Widget widget; _children)
				widget.onEvent(event);
			break;
		}
	}

	void run() {
		while(processEvents(this)) {
			processOverlayBack(_deltaTime);
			foreach(Widget widget; _children) {
				widget.update(_deltaTime);
				widget.draw();
				widget.drawOverlay();
			}
			processOverlayFront(_deltaTime);
			renderWindow();
			endOverlay();
			
			long deltaTicks = Clock.currStdTime() - _tickStartFrame;
			if(deltaTicks < (10_000_000 / nominalFps))
				Thread.sleep(dur!("hnsecs")((10_000_000 / nominalFps) - deltaTicks));

			deltaTicks = Clock.currStdTime() - _tickStartFrame;
			_deltaTime = (cast(float)(deltaTicks) / 10_000_000f) * nominalFps;
			_currentFps = (_deltaTime == .0f) ? .0f : (10_000_000f / cast(float)(deltaTicks));
			_tickStartFrame = Clock.currStdTime();
		}
	}

	void addChild(Widget widget) {
		_children ~= widget;
	}

	void removeChildren() {
		_children.length = 0uL;
	}

	Widget[] getChildren() {
		return _children;
	}

	void setChildren(Widget[] newChildren) {
		_children = newChildren;
	}
}
