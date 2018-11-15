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

module atelier.ui.list.dropdownlist;

import std.conv: to;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element, atelier.ui.gui_overlay, atelier.ui.list.vlist, atelier.ui.label, atelier.ui.button;

private class DropDownListCancelTrigger: GuiElement {
    override void onSubmit() {
        triggerCallback();
    }
}

private class DropDownListSubElement: Button {
    Label label;

    this(string title) {
        label = new Label(title);
        label.setAlign(GuiAlignX.Center, GuiAlignY.Center);
        addChildGui(label);
    }

    override void draw() {
        drawFilledRect(origin, size, isHovered ? Color.gray : Color.black);
    }
}

class DropDownList: GuiElement {
	private {
		VList _list;
        Label _label;
        DropDownListCancelTrigger _cancelTrigger;
		bool _isUnrolled = false;
		uint _maxListLength = 5;
	}

	@property {
		uint selected() const { return _list.selected; }
		uint selected(uint id) { return _list.selected = id; }
	}

	this(Vec2f newSize, uint maxListLength = 5U) {
		_maxListLength = maxListLength;
		size = newSize;

		_list = new VList(size * Vec2f(1f, _maxListLength));
        _list.setAlign(GuiAlignX.Left, GuiAlignY.Top);

        _cancelTrigger = new DropDownListCancelTrigger;
        _cancelTrigger.setAlign(GuiAlignX.Left, GuiAlignY.Top);
        _cancelTrigger.size = size;
        _cancelTrigger.setCallback(this, "cancel");

        _label = new Label;
        _label.setAlign(GuiAlignX.Center, GuiAlignY.Center);
        super.addChildGui(_label);
	}

	override void onSubmit() {
		if(!isLocked) {
            _isUnrolled = !_isUnrolled;

            if(_isUnrolled) {
                setOverlay(_cancelTrigger);
                setOverlay(_list);
            }
            else {
                stopOverlay();
                triggerCallback();
            }
		}
	}

    override void onCallback(string id) {
        if(id == "cancel") {
            _isUnrolled = false;
            stopOverlay();
            triggerCallback();
        }
    }

	override void update(float deltaTime) {
		if(_isUnrolled) {
			Vec2f newSize = size * Vec2f(1f, _maxListLength + 1f);
            _cancelTrigger.position = origin;
			_list.position = origin + Vec2f(0f, _size.y);
			_list.update(deltaTime);

            int id;
            foreach(gui; _list.getList()) {
                if(gui.hasFocus) {
                    _isUnrolled = false;
                    selected = id;

                    stopOverlay();
					triggerCallback();
                }
                id ++;
            }
		}
	}

	override void draw() {
		super.draw();
		auto guis = _list.getList();
		if(guis.length > _list.selected) {
			auto gui = cast(DropDownListSubElement)(guis[_list.selected]);
            _label.text = gui.label.text;
		}
		drawRect(origin, size, Color.white);
	}

	protected override void addChildGui(GuiElement gui) {
		_list.addChildGui(gui);
	}

    void add(string msg) {
        auto gui = new DropDownListSubElement(msg);
		addChildGui(gui);
	}

	override void removeChildrenGuis() {
		_list.removeChildrenGuis();
	}

	override void removeChildGui(uint id) {
		_list.removeChildGui(id);
	}

	override int getChildrenGuisCount() {
		return _list.getChildrenGuisCount();
	}

	GuiElement[] getList() {
		return _list.getList();
	}
}