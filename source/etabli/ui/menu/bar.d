/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.menu.bar;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.core;
import etabli.ui.panel;
import etabli.ui.menu.list;
import etabli.ui.menu.button;

class MenuBar : UIElement {
    private {
        HBox _box;
        Container _container;
        MenuList _list;
        float _barHeight = 35f;
        uint _currentListId;

        MenuButton[] _menuButtons;
        MenuList[] _menuLists;
    }

    this() {
        setAlign(UIAlignX.left, UIAlignY.top);

        setSize(Vec2f(0f, _barHeight));
        setSizeLock(false, true);

        _container = new Container;
        addUI(_container);

        _box = new HBox;
        _box.setAlign(UIAlignX.left, UIAlignY.center);
        _box.setChildAlign(UIAlignY.top);
        _box.setMargin(Vec2f(8f, 4f));
        addUI(_box);

        addEventListener("register", &_onSize);
        addEventListener("parentSize", &_onSize);
        addEventListener("size", { _container.setSize(getSize()); });
    }

    private MenuList _getList(string menuName) {
        MenuList list;

        for (uint i; i < _menuLists.length; ++i) {
            if (_menuLists[i].name == menuName) {
                list = _menuLists[i];
                break;
            }
        }
        if (!list) {
            list = new MenuList(this, cast(uint) _menuLists.length, menuName);
            MenuButton btn = new MenuButton(this, cast(uint) _menuLists.length, menuName);
            _box.addUI(btn);

            _menuLists ~= list;
            _menuButtons ~= btn;
        }
        return list;
    }

    UIElement add(string menuName, string itemName) {
        MenuList list = _getList(menuName);
        return list.add(itemName);
    }

    void addSeparator(string menuName) {
        MenuList list = _getList(menuName);
        list.addSeparator();
    }

    private void _onSize() {
        setWidth(getParentWidth());
    }

    package void removeList(uint id) {
        if (_currentListId == id)
            return;

        if (_list) {
            _list.startRemove();
            _list = null;
        }
    }

    package void leaveMenu(uint id) {
        _currentListId = uint.max;
    }

    package void switchMenu(uint id) {
        _currentListId = id;

        if (!_list) {
            return;
        }

        if (_list && _list.id == id) {
            return;
        }
        toggleMenu(id);
    }

    package void toggleMenu(uint id) {
        if (_list) {
            uint listId = _list.id;
            _list.startRemove();
            _list = null;
            if (listId == id) {
                return;
            }
        }

        _list = _menuLists[id];
        _list.setPosition(getPosition() + _menuButtons[id].getPosition() + Vec2f(0f, getHeight()));
        _list.runState("visible");

        UIElement parent = getParent();
        if (parent) {
            parent.addUI(_list);
        }
        else {
            Etabli.ui.addUI(_list);
        }
    }
}
