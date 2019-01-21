/**
    Dropdown list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
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

    string getSelectedName() {
        auto list = cast(DropDownListSubElement[])getList();
        if(selected() >= list.length)
            return "";
        return list[selected()].label.text;
    }

    void setSelectedName(string name) {
        auto list = cast(DropDownListSubElement[])getList();
        int i;
        foreach(btn; list) {
            if(btn.label.text == name) {
                selected(i);
                triggerCallback();
                return;
            }
            i ++;
        }
    }
}