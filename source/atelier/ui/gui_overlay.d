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

module atelier.ui.gui_overlay;

import std.algorithm.comparison: max;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.label, atelier.ui.text, atelier.ui.gui_manager;

private {
	HintWindow _hintWindow;
	Hint _displayedHint;
	GuiElement[] _backupGuis;
	GuiElement[] _overlayGuiElements;
	bool _isOverlay = false;
}

Hint makeHint(string title, string text) {
	return new Hint(title, text);
}

class Hint {
	string title, text;

	this(string newTitle, string newText) {
		title = newTitle;
		text = newText;
	}
}

void openHintWindow(Hint hint) {
	_displayedHint = hint;
}

void initializeOverlay() {
	_hintWindow = new HintWindow;
	_displayedHint = null;
}

bool isOverlay() {
	return _isOverlay;
}

void setOverlay(GuiElement gui) {
	if(!_isOverlay) {
		_isOverlay = true;
		_backupGuis = getRootGuis();
		removeRootGuis();
	}

	_overlayGuiElements ~= gui;
	addRootGui(gui);
}

void stopOverlay() {
	if(!_isOverlay)
		throw new Exception("No overlay to stop");
	_isOverlay = false;
	setRootGuis(_backupGuis);
	_backupGuis.length = 0L;
	_overlayGuiElements.length = 0L;
}

void processOverlayEvent(Event event) {
	if(event.type == EventType.Quit) {
		foreach(gui; _backupGuis)
			gui.onEvent(event);
	}
}

void processOverlayBack() {
	foreach(gui; _backupGuis) {
		updateGuiElements(gui, null);	
		drawGuiElements(gui);
	}
}

void processOverlayFront(float deltaTime) {
	_hintWindow.hint = _displayedHint;
	_hintWindow.update(deltaTime);
	_hintWindow.draw();
}

void endOverlay() {
	_displayedHint = null;
}

private class HintWindow: GuiElement {
	private {
		bool _isRendered;
	}
	Label title;
	Text text;

	@property void hint(Hint hint) {
		_isRendered = hint !is null;
		if(_isRendered) {
			title.text = hint.title;
			text.text = hint.text;
		}
	}

	this() {
		title = new Label;
		text = new Text;
	}

	override void update(float deltaTime) {
		if(!_isRendered)
			return;
		size = Vec2f(max(title.size.x, text.size.x) + 25f, title.size.y + text.size.y);
		
        //They aren't processed buy the gui_manager, so we use setScreenCoords directly.
        setScreenCoords(getMousePos() + size / 2f + Vec2f(20f, 10f));
        title.setScreenCoords(center + Vec2f(0f, (title.size.y - size.y) / 2f));
		text.setScreenCoords(center + Vec2f(0f, title.size.y + (text.size.y - size.y) / 2f));
	}

	override void draw() {
		if(!_isRendered)
			return;
		drawFilledRect(origin, size, Color.white * .21f);
		drawFilledRect(origin, Vec2f(size.x, title.size.y), Color.white * .11f);
		title.draw();
		text.draw();
	}
}