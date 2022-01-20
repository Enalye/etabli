/**
    Gui Modal

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.gui_modal;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.label,
    atelier.ui.button, atelier.ui.gui_manager, atelier.ui.gui_overlay;

private {
    GuiElement[][] _backups;
    GuiElement[] _modalElements;
    GuiElement _modalElement;
    bool _isModal = false;
}

/// Set a gui as a modal gui.
/// ___
/// It will have exclusive access to events and be rendered above all other guis.
void pushModal(GuiElement modalGui) {
    if (_isModal) {
        _modalElements ~= _modalElement;
    }
    _isModal = true;
    _backups ~= getRoots();
    removeRoots();
    _modalElement = modalGui;
    appendRoot(_modalElement);
}

/// Does a modal gui is currently being run ?
bool isModal() {
    return _isModal;
}

/// Get and stop the current modal.
T popModal(T)() {
    T convModal = getModal!T();
    stopModal();
    return convModal;
}

/// Get the modal currently running.
private T getModal(T)() {
    if (_modalElement is null)
        throw new Exception("Modal: No window instanciated");
    T convModal = cast(T) _modalElement;
    if (convModal is null)
        throw new Exception("Modal: Type error");
    return convModal;
}

/// Immediately stops the currently running modal gui.
void stopModal() {
    removeRoots();
    stopOverlay();
    if (_modalElement is null)
        throw new Exception("Modal: No window instanciated");
    setRoots(_backups[$ - 1]);
    _backups.length--;
    if (_modalElements.length) {
        _modalElement = _modalElements[$ - 1];
        _modalElements.length--;
    }
    else {
        _isModal = false;
    }
}

/// Close everything
package(atelier) void stopAllModals() {
    while (_isModal) {
        stopModal();
    }
}

/// Update and render the gui that aren't modals while the modal gui is active.
package(atelier) void processModalBack() {
    foreach (backup; _backups) {
        foreach (GuiElement gui; backup) {
            updateRoots(gui, null);
            drawRoots(gui);
        }
    }
}
