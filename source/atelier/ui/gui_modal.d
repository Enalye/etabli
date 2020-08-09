/**
    Gui Modal

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/


module atelier.ui.gui_modal;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.label,
	atelier.ui.button, atelier.ui.gui_manager;

private {
	GuiElement[][] _backups;
	GuiElement[] _modals;
	GuiElement _modalGui;
	bool _isModal = false;
}

/// Set a gui as a modal gui.
/// ___
/// It will have exclusive access to events and be rendered above all other guis.
void pushModalGui(GuiElement modalGui) {
	if(_isModal) {
		_modals ~= _modalGui;
	}
	_isModal = true;
	_backups ~= getRootGuis();
	removeRootGuis();
	_modalGui = modalGui;
	addRootGui(_modalGui);
}

/// Does a modal gui is currently being run ?
bool isModalGui() {
	return _isModal;
}

/// Get and stop the current modal.
T popModalGui(T)() {
	T convModal = getModalGui!T();
	stopModalGui();
	return convModal;
}

/// Get the modal currently running.
private T getModalGui(T)() {
	if(_modalGui is null)
		throw new Exception("Modal: No window instanciated");
	T convModal = cast(T) _modalGui;
	if(convModal is null)
		throw new Exception("Modal: Type error");
	return convModal;
}

/// Immediately stops the currently running modal gui.
void stopModalGui() {
	removeRootGuis();
	if(_modalGui is null)
		throw new Exception("Modal: No window instanciated");
	setRootGuis(_backups[$ - 1]);
	_backups.length --;
	if(_modals.length) {
		_modalGui = _modals[$ - 1];
		_modals.length --;
	}
	else {
		_isModal = false;
	}
}

/// Close everything
package(atelier) void stopAllModalGuis() {
	while(_isModal) {
		stopModalGui();
	}
}

/// Update and render the gui that aren't modals while the modal gui is active.
package(atelier) void processModalBack() {
    foreach (backup; _backups) {
		foreach (GuiElement gui; backup) {
			updateGuiElements(gui, null);
			drawGuiElements(gui);	
		}
	}
}