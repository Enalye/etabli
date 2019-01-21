/**
    Listwindow

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.listwindow;

import atelier.core;
import atelier.common;

import atelier.ui.gui_modal;
import atelier.ui.button;
import atelier.ui.list.vlist;
import atelier.ui.inputfield;
/+
void setListWindow(string title, string[] list) {
	auto modal = new ListWindow(title, list);
	setModalWindow(modal);
}

class ListWindow: ModalWindow {
	private {
		InStream _stream;
		string[] _elements;
		VList _list;
	}

	@property {
		string selected() const {
			if(!_elements.length)
				return "";
			return _elements[_list.selected];
		}
	}

	this(string title, string[] newElements) {
		super(title, Vec2f(250f, 200f));
		_elements = newElements;
		_list = new VList(layout.size);
		foreach(element; _elements) {
			auto btn = new TextButton(element);
			_list.addChildGui(btn);
		}
		layout.addChildGui(_list);
	}
}+/