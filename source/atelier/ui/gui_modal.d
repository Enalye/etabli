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
	GuiElement[] _backupGuis;
	GuiElement _modalGui;
	bool _isModal = false;
}

/// Set a gui as a modal gui.
/// ___
/// It will have exclusive access to events and be rendered above all other guis.
void setModalGui(GuiElement modalGui) {
	if(_isModal)
		throw new Exception("Modal gui already set");
	_isModal = true;
	_backupGuis = getRootGuis();
	removeRootGuis();
	_modalGui = modalGui;
	addRootGui(_modalGui);
}

/// Does a modal gui is currently being run ?
bool isModalGui() {
	return _isModal;
}

/// Get the modal currently running.
T getModalGui(T)() {
	if(_modalGui is null)
		throw new Exception("Modal: No window instanciated");
	T convModal = cast(T)_modalGui;
	if(convModal is null)
		throw new Exception("Modal: Type error");
	return convModal;
}

/// Immediately stops the currently running modal gui.
void stopModalGui() {
	removeRootGuis();
	if(_modalGui is null)
		throw new Exception("Modal: No window instanciated");
	setRootGuis(_backupGuis);
	_backupGuis.length = 0L;
	_isModal = false;
}

/// Update and render the gui that aren't modals while the modal gui is active.
package(atelier) void processModalBack() {
    foreach(gui; _backupGuis) {
		updateGuiElements(gui, null);	
		drawGuiElements(gui);
	}
}