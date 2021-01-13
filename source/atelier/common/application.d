/**
    Application

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.common.application;

import bindbc.sdl;

import core.thread;
import std.datetime;

import atelier.core;
import atelier.render;
import atelier.ui;

import atelier.common.event;
import atelier.common.settings;
import atelier.common.resource;

alias ApplicationUpdate = void function(float);

private {
    float _deltatime = 1f;
    float _currentFps;
    long _tickStartFrame;

    bool _isChildGrabbed;
    uint _idChildGrabbed;
    GuiElement[] _children;

    bool _isInitialized;
    uint _nominalFPS = 60u;

    ApplicationUpdate[] _applicationUpdates;
}

/// Actual framerate divided by the nominal framerate
/// 1 if the same, less if the application slow down,
/// more if the application runs too quickly.
float getDeltatime() { return _deltatime; }

/// Actual framerate of the application.
float getCurrentFPS() { return _currentFps; }

/// Maximum framerate of the application. \
/// The deltatime is equal to 1 if the framerate is exactly that.
uint getNominalFPS() { return _nominalFPS; }
/// Ditto
uint setNominalFPS(uint fps) { return _nominalFPS = fps; }

/// Application startup
void createApplication(Vec2u size, string title = "Atelier") {
    if(_isInitialized)
		throw new Exception("The application cannot be run twice.");
    _isInitialized = true;
    createWindow(size, title);
    initializeEvents();
    _tickStartFrame = Clock.currStdTime();
}

/// Main application loop
void runApplication() {
	if(!_isInitialized)
		throw new Exception("Cannot run the application.");
    
    while(processEvents()) {
        updateEvents(_deltatime);
        foreach(applicationUpdate; _applicationUpdates) {
            applicationUpdate(_deltatime);
        }
        processModalBack();
        processOverlayBack();
        updateGuiElements(_deltatime);
        drawGuiElements();
        processOverlayFront(_deltatime);
        renderWindow();
        endOverlay();
        
        long deltaTicks = Clock.currStdTime() - _tickStartFrame;
        if(deltaTicks < (10_000_000 / _nominalFPS))
            Thread.sleep(dur!("hnsecs")((10_000_000 / _nominalFPS) - deltaTicks));

        deltaTicks = Clock.currStdTime() - _tickStartFrame;
        _deltatime = (cast(float)(deltaTicks) / 10_000_000f) * _nominalFPS;
        _currentFps = (_deltatime == .0f) ? .0f : (10_000_000f / cast(float)(deltaTicks));
        _tickStartFrame = Clock.currStdTime();
    }
}

/// Cleanup and kill the application
void destroyApplication() {
    destroyEvents();
	destroyWindow();
}

/// Add a callback function called for each game loop
void addApplicationUpdate(ApplicationUpdate applicationUpdate) {
    _applicationUpdates ~= applicationUpdate;
}