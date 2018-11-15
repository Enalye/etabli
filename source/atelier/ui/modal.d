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

module atelier.ui.modal;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.layout, atelier.ui.label, atelier.ui.button, atelier.ui.panel, atelier.ui.gui_manager;

private {
	GuiElement[] _widgetsBackup;
	ModalWindow _modal;
//	string _modalName;
	bool _isModal = false;
}

void setModalWindow(ModalWindow newModal) {
	if(_isModal)
		throw new Exception("Modal window already set");
	_isModal = true;
	//_modalName = newModalName;
	_widgetsBackup = getRootGuis();
	removeRootGuis();
	_modal = newModal;
	addRootGui(_modal);
	/+Event event = EventType.ModalOpen;
	event.id = _modalName;
	event.widget = _modal;
	sendEvent(event);+/
}

bool isModal() {
	return _isModal;
}

T getModal(T)() {
	if(_modal is null)
		throw new Exception("Modal: No window instanciated");
	T convModal = cast(T)_modal;
	if(convModal is null)
		throw new Exception("Modal: Type error");
	return convModal;
}

private void onModalClose() {
	removeRootGuis();
	if(_modal is null)
		throw new Exception("Modal: No window instanciated");
	setRootGuis(_widgetsBackup);
	_widgetsBackup.length = 0L;
	_isModal = false;
}

class ModalWindow: GuiElement {
	AnchoredLayout layout;
	TextButton cancelBtn, applyBtn;

	private {
		Panel _panel;
		HLayout _lowerBox;
		Label _titleLabel;
		ImgButton _exitBtn;
	}

	this(string newTitle, Vec2f newSize) {
		size = newSize + Vec2f(22f, 116f);
		isMovable = true;
		position = centerScreen;

		_titleLabel = new Label(newTitle);
		_titleLabel.color = Color.white * 0.21;
		_panel = new Panel;
		_panel.position = center;
		layout = new AnchoredLayout;
		layout.position = center;

		_exitBtn = new ImgButton;
		_exitBtn.idleSprite = fetch!Sprite("gui_window_exit");
		_exitBtn.onClick = {
			{
				Event event;
				event.type = EventType.Callback;
				event.id = "exit";
				_modal.onEvent(event);
			}
			onModalClose();
			/+Event event = EventType.ModalCancel;
			event.id = _modalName;
			event.widget = _modal;
			_modal.onEvent(event);
			sendEvent(event);
			event.type = EventType.ModalClose;
			_modal.onEvent(event);
			sendEvent(event);+/
		};

		{ //Confirmation buttons
			_lowerBox = new HLayout;
			_lowerBox.isLocked = true;
			_lowerBox.spacing = Vec2f(10f, 15f);

			cancelBtn = new TextButton("Annuler");
			applyBtn = new TextButton("Valider");
			cancelBtn.onClick = {
				{
					Event event;
					event.type = EventType.Callback;
					event.id = "cancel";
					_modal.onEvent(event);
				}
				onModalClose();
				/+Event event = EventType.ModalCancel;
				event.id = _modalName;
				event.widget = _modal;
				_modal.onEvent(event);
				sendEvent(event);
				event.type = EventType.ModalClose;
				_modal.onEvent(event);
				sendEvent(event);+/
			};
			applyBtn.onClick = {
				{
					Event event;
					event.type = EventType.Callback;
					event.id = "apply";
					_modal.onEvent(event);
				}
				onModalClose();
				/+Event event = EventType.ModalApply;
				event.id = _modalName;
				event.widget = _modal;
				_modal.onEvent(event);
				sendEvent(event);
				event.type = EventType.ModalClose;
				_modal.onEvent(event);
				sendEvent(event);+/
			};

			addChildGui(_lowerBox);
			_lowerBox.addChildGui(cancelBtn);
			_lowerBox.addChildGui(applyBtn);
		}

		addChildGui(_titleLabel);
		addChildGui(layout);
		addChildGui(_exitBtn);
		addChildGui(_panel);
		resize();
	}

	override void update(float deltaTime) {
		layout.position = center;
		//Update suspended widgets
		foreach(child; _widgetsBackup)
			child.update(deltaTime);
		super.update(deltaTime);
	}

	override void draw() {
		//Render suspended widgets in background
		foreach(child; _widgetsBackup)
			child.draw();
		super.draw();
	}

    override void onSize() {
        size += Vec2f(22f, 116f);
        resize();
    }

	protected void resize() {
		_exitBtn.position = center + Vec2f((size.x - _exitBtn.size.x), (-size.y + _exitBtn.size.y)) / 2f;
		_lowerBox.size = Vec2f(size.x - 25f, 40f);
		_lowerBox.position = center + Vec2f(0f, size.y / 2f - 30f);
		_panel.size = size;
		layout.position = center - Vec2f(8f, 0f);
		layout.size = Vec2f(size.x - 22f, size.y - 116f);
		_titleLabel.position = Vec2f(center.x, center.y - size.y / 2f + 25f);
	}
}