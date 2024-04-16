/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.navigation.tabbar;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.navigation.list;

final class TabBar : UIElement {
    private {
        HList _list;
        string _value, _lastRemovedTab;
    }

    @property {
        string value() {
            return _value;
        }

        string lastRemovedTab() {
            return _lastRemovedTab;
        }
    }

    this() {
        _list = new HList(3f);
        _list.setAlign(UIAlignX.left, UIAlignY.top);
        _list.setHeight(35f);
        addUI(_list);

        setSize(_list.getSize());
        setSizeLock(false, true);

        addEventListener("size", &_onSize);
    }

    private void _onSize() {
        _list.setWidth(getWidth());
    }

    bool hasTab(string id) {
        Tab[] tabs = cast(Tab[]) _list.getList();

        foreach (Tab tab; tabs) {
            if (tab._id == id && tab.isAlive())
                return true;
        }
        return false;
    }

    void addTab(string name, string id, string icon = "") {
        Tab tab = new Tab(this, name, id, icon);
        _list.addList(tab);
        select(tab);
    }

    void select(string id) {
        Tab[] tabs = cast(Tab[]) _list.getList();

        bool hasValue;
        foreach (Tab tab; tabs) {
            if (tab._id == id) {
                hasValue = true;
            }
            tab.updateValue(tab._id == id);
        }

        if (!tabs.length) {
            if (_value != "") {
                _value = "";
                dispatchEvent("value", false);
                return;
            }
        }

        if (!hasValue) {
            tabs[0].updateValue(true);
            _value = tabs[0]._id;
        }

        if (_value != id) {
            _value = id;
            dispatchEvent("value", false);
        }
    }

    private void select(Tab tab_) {
        Tab[] tabs = cast(Tab[]) _list.getList();

        foreach (Tab tab; tabs) {
            tab.updateValue(tab_ == tab);
        }

        if (_value != tab_._id) {
            _value = tab_._id;
            dispatchEvent("value", false);
        }
    }

    private void unselect(Tab tab_) {
        Tab[] tabs = cast(Tab[]) _list.getList();

        for (int i; i < (cast(int) tabs.length); ++i) {
            if (tab_ == tabs[i]) {
                if (i > 0) {
                    tabs[i - 1].updateValue(true);
                    _value = tabs[i - 1]._id;
                }
                else if (i + 1 < tabs.length) {
                    tabs[i + 1].updateValue(true);
                    _value = tabs[i + 1]._id;
                }
                break;
            }
        }

        if (tabs.length <= 1)
            _value = "";

        dispatchEvent("value", false);
    }
}

private final class Tab : UIElement {
    private {
        TabBar _bar;
        Rectangle _rect;
        Label _nameLabel;
        string _id;
        Icon _icon;
        IconButton _removeBtn;
        bool _isSelected;
    }

    this(TabBar bar, string name, string id, string icon) {
        _bar = bar;
        _id = id;

        if (icon.length) {
            _icon = new Icon(icon);
            _icon.setAlign(UIAlignX.left, UIAlignY.center);
            _icon.setPosition(Vec2f(8f, 0f));
            addUI(_icon);
        }
        _nameLabel = new Label(name, Etabli.theme.font);
        _nameLabel.setAlign(UIAlignX.center, UIAlignY.center);
        addUI(_nameLabel);

        _removeBtn = new IconButton("editor:exit");
        _removeBtn.setAlign(UIAlignX.right, UIAlignY.center);
        _removeBtn.setPosition(Vec2f(4f, 0f));
        _removeBtn.addEventListener("click", &_onRemove);
        _removeBtn.isVisible = false;
        addUI(_removeBtn);

        if (_icon) {
            setSize(Vec2f(_nameLabel.getWidth() + _icon.getWidth() + _removeBtn.getWidth() + 32f,
                    32f));
        }
        else {
            setSize(Vec2f(_nameLabel.getWidth() + _removeBtn.getWidth() + 16f, 32f));
        }

        _rect = Rectangle.fill(getSize());
        _rect.anchor = Vec2f.zero;
        _rect.color = Etabli.theme.container;
        addImage(_rect);

        addEventListener("mouseenterinside", { _removeBtn.isVisible = true; });

        addEventListener("mouseleaveinside", { _removeBtn.isVisible = false; });

        addEventListener("click", &_onClick);
    }

    private void _onClick() {
        if (_isSelected)
            return;

        _bar.select(this);
    }

    private void updateValue(bool value) {
        _isSelected = value;
        _rect.color = _isSelected ? Etabli.theme.foreground : Etabli.theme.container;
    }

    private void _onRemove() {
        if (_isSelected) {
            _bar.unselect(this);
        }
        remove();
        _bar._lastRemovedTab = _id;
        _bar.dispatchEvent("close", false);
    }
}
