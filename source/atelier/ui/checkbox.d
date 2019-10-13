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

/// A simple check box.
class Checkbox: GuiElement {
	private {
		bool _value;
	}

	@property {
		/// Value of the checkbox, true if checked.
		bool value() const { return _value; }
		/// Ditto
		bool value(bool v) {
			return _value = v;
		}
	}

	override void onSubmit() {
		if(isLocked)
			return;
		_value = !_value;
        triggerCallback();
	}

	override void draw() {
		if(_value)
			drawFilledRect(origin, size, Color.white);
		else
			drawRect(origin, size, Color.white);
	}
}