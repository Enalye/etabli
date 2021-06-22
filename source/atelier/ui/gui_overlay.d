/**
    Gui Overlay

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.gui_overlay;

import std.algorithm.comparison : max;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.label, atelier.ui.text, atelier.ui.gui_manager;

private {
    HintWindow _hintWindow;
    Hint _displayedHint;
    GuiElement[] _backupGuis;
    GuiElement[] _overlayGuiElements;
    bool _isOverlay = false;
}

/// Create a Hint for a gui element.
Hint makeHint(string text) {
    return new Hint(text);
}

/// Displays text next to the cursor when hovering over a gui.
class Hint {
    /// The title is rendered above the text.
    string text;

    /// Ctor
    this(string text_) {
        text = text_;
    }
}

/// Create the hint gui.
package void openHintWindow(Hint hint) {
    _hintWindow = new HintWindow;
    _displayedHint = hint;
}

/// Is there a gui running as an overlay ?
bool isOverlay() {
    return _isOverlay;
}

/// Add the gui as an overlay (rendered above all other guis). \
/// Doesn't take away events from the other guis (unlike modal).
void setOverlay(GuiElement gui) {
    if (!_isOverlay) {
        _isOverlay = true;
        _backupGuis = getRoots();
        removeRoots();
    }

    _overlayGuiElements ~= gui;
    appendRoot(gui);
}

/// Remove the current overlay gui.
void stopOverlay() {
    if (!_isOverlay)
        return;
    _isOverlay = false;
    setRoots(_backupGuis);
    _backupGuis.length = 0L;
    _overlayGuiElements.length = 0L;
}

/// Process events from the guis that aren't overlay.
package void processOverlayEvent(Event event) {
    switch (event.type) with (Event.Type) {
    case quit:
        foreach (gui; _backupGuis) {
            gui.onQuit();
            gui.onEvent(event);
        }
        stopOverlay();
        break;
    case resize:
    case custom:
        foreach (gui; _backupGuis) {
            gui.onEvent(event);
        }
        break;
    default:
        break;
    }
}

/// Updates and renders guis that are behind.
package(atelier) void processOverlayBack() {
    foreach (gui; _backupGuis) {
        updateRoots(gui, null);
        drawRoots(gui);
    }
}

/// Updates and renders guis that are in front (like the hint).
package(atelier) void processOverlayFront(float deltaTime) {
    if (_hintWindow is null)
        return;
    _hintWindow.hint = _displayedHint;
    _hintWindow.update(deltaTime);
    _hintWindow.draw();
}

/// Stops overlay gui.
void endOverlay() {
    _displayedHint = null;
}

/// The gui that renders the hint.
private final class HintWindow : GuiElement {
    private {
        bool _isRendered;
    }
    Label text;

    @property void hint(Hint hint) {
        _isRendered = hint !is null;
        if (_isRendered) {
            text.text = hint.text;
        }
    }

    this() {
        text = new Label;
    }

    override void update(float deltaTime) {
        if (!_isRendered)
            return;
        size = Vec2f(text.size.x + 25f, text.size.y);

        //They aren't processed by the gui manager, so we use setScreenCoords directly.
        setScreenCoords(getMousePos() + size / 2f + Vec2f(20f, 10f));
        text.setScreenCoords(center + Vec2f(0f, (text.size.y - size.y) / 2f));
    }

    override void draw() {
        if (!_isRendered)
            return;
        drawFilledRect(origin, size, Color.white * .11f);
        text.draw();
    }
}
