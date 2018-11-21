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