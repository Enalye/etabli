/**
    Checkbox

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.checkbox;

import std.conv: to;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element;

class Checkbox: GuiElement {
	private {
		bool _isChecked;
	}

	@property {
		bool isChecked() const { return _isChecked; }
		bool isChecked(bool newIsChecked) {
			_isChecked = newIsChecked;
			onCheck();
			return _isChecked;
		}
	}

	override void onSubmit() {
		if(isLocked)
			return;
		isChecked = !isChecked;
        triggerCallback();
	}

	protected void onCheck() {}
}