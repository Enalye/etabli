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

module atelier.ui.gui_modal;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.label, atelier.ui.button, atelier.ui.panel, atelier.ui.gui_manager;

private {
	GuiElement[] _backupGuis;
	GuiElement _modalGui;
	bool _isModal = false;
}

void setModalGui(GuiElement modalGui) {
	if(_isModal)
		throw new Exception("Modal gui already set");
	_isModal = true;
	_backupGuis = getRootGuis();
	removeRootGuis();
	_modalGui = modalGui;
	addRootGui(_modalGui);
}

bool isModalGui() {
	return _isModal;
}

T getModalGui(T)() {
	if(_modalGui is null)
		throw new Exception("Modal: No window instanciated");
	T convModal = cast(T)_modalGui;
	if(convModal is null)
		throw new Exception("Modal: Type error");
	return convModal;
}

void stopModalGui() {
	removeRootGuis();
	if(_modalGui is null)
		throw new Exception("Modal: No window instanciated");
	setRootGuis(_backupGuis);
	_backupGuis.length = 0L;
	_isModal = false;
}

void processModalBack() {
    foreach(gui; _backupGuis) {
		updateGuiElements(gui, null);	
		drawGuiElements(gui);
	}
}