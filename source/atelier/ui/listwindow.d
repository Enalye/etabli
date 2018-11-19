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