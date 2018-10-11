/**
    Modal

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.modal;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui.widget;
import atelier.ui.layout;
import atelier.ui.label;
import atelier.ui.button;
import atelier.ui.panel;

private {
	Widget[] _widgetsBackup;
	ModalWindow _modal;
//	string _modalName;
	bool _isModal = false;
}

void setModalWindow(ModalWindow newModal) {
	if(_isModal)
		throw new Exception("Modal window already set");
	_isModal = true;
	//_modalName = newModalName;
	_widgetsBackup = getWidgets();
	removeWidgets();
	_modal = newModal;
	addWidget(_modal);
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
	removeWidgets();
	if(_modal is null)
		throw new Exception("Modal: No window instanciated");
	setWidgets(_widgetsBackup);
	_widgetsBackup.length = 0L;
	_isModal = false;
}

class ModalWindow: WidgetGroup {
	AnchoredLayout layout;
	TextButton cancelBtn, applyBtn;

	private {
		Panel _panel;
		HLayout _lowerBox;
		Label _titleLabel;
		ImgButton _exitBtn;
	}

	this(string newTitle, Vec2f newSize) {
		_size = newSize + Vec2f(22f, 116f);
		_isMovable = true;
		_isFrame = false;
		position = centerScreen;

		_titleLabel = new Label(newTitle);
		_titleLabel.color = Color.white * 0.21;
		_panel = new Panel;
		_panel.position = _position;
		layout = new AnchoredLayout;
		layout.position = _position;

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

			addChild(_lowerBox);
			_lowerBox.addChild(cancelBtn);
			_lowerBox.addChild(applyBtn);
		}

		addChild(_titleLabel);
		addChild(layout);
		addChild(_exitBtn);
		addChild(_panel);
		resize();
	}

	override void update(float deltaTime) {
		layout.position = _position;
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
        _size += Vec2f(22f, 116f);
        resize();
    }

	protected void resize() {
		_exitBtn.position = _position + Vec2f((_size.x - _exitBtn.size.x), (-_size.y + _exitBtn.size.y)) / 2f;
		_lowerBox.size = Vec2f(_size.x - 25f, 40f);
		_lowerBox.position = _position + Vec2f(0f, _size.y / 2f - 30f);
		_panel.size = _size;
		layout.position = _position - Vec2f(8f, 0f);
		layout.size = Vec2f(_size.x - 22f, _size.y - 116f);
		_titleLabel.position = Vec2f(_position.x, _position.y - _size.y / 2f + 25f);
	}
}