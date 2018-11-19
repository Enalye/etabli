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

module atelier.common.application;

import derelict.sdl2.sdl;

import core.thread;
import std.datetime;

import atelier.core;
import atelier.render;
import atelier.ui;

import atelier.common.event;
import atelier.common.settings;
import atelier.common.resource;

private {
    float _deltaTime = 1f;
    float _currentFps;
    long _tickStartFrame;

    bool _isChildGrabbed;
    uint _idChildGrabbed;
    GuiElement[] _children;
}
private {
    bool _isInitialized;
}
uint nominalFps = 60u;

void createApplication(Vec2u size, string title = "Atelier") {
    if(_isInitialized)
		throw new Exception("The application cannot be run twice.");
    _isInitialized = true;
    createWindow(size, title);
    initializeEvents();
    loadResources();
    initializeOverlay();
    _tickStartFrame = Clock.currStdTime();
}

void runApplication() {
	if(!_isInitialized)
		throw new Exception("Cannot run the application.");
    while(processEvents()) {
        updateEvents(_deltaTime);
        processOverlayBack();
        processModalBack();
        updateGuiElements(_deltaTime);
        drawGuiElements();
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

void destroyApplication() {
    destroyEvents();
	destroyWindow();
}

@property {
    float deltaTime() { return _deltaTime; }
    float currentFps() { return _currentFps; }
}