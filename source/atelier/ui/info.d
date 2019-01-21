/**
    Info

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.info;

import atelier.core;

import atelier.ui.gui_modal;
import atelier.ui.label;
/+
void setInfoWindow(string title, string information) {
	setModalWindow(new InfoWindow(title, information));
}

void setInfoWindow(string information) {
	setModalWindow(new InfoWindow(information));
}


class InfoWindow: ModalWindow {
	this(string title, string information) {
		super(title, Vec2f.zero);
		auto label = new Label(information);
		size = label.size;
		layout.addChildGui(label);
	}

	this(string information) {
		this("Information", information);
	}
}+/