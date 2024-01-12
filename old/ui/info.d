/**
    Info

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.ui.info;

import etabli.core;

import etabli.ui.gui_modal;
import etabli.ui.label;
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
		layout.addNodeGui(label);
	}

	this(string information) {
		this("Information", information);
	}
}+/