/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.file.save;

import std.file;
import std.path;
import std.string;
import std.typecons : No;
import etabli.common;
import etabli.core;
import etabli.input;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;
import etabli.ui.input;
import etabli.ui.panel;
import etabli.ui.navigation;
import etabli.ui.select;

final class SaveFile : Modal {
    private {
        PathField _uriField;
        TextField _fileNameField;
        VList _list;
        FileItem[] _items;
        FileItem _selectedItem;
        UIElement _validateBtn;
        string _directory, _value;
        string[] _extensions;
        GhostButton _prevButton, _nextButton;
        string[] _prevHistory, _nextHistory;
        SelectButton _extensionSelect;
    }

    @property {
        string value() const {
            return buildNormalizedPath(_directory, _value);
        }
    }

    this(string directory, string[] extensions = []) {
        setSize(Vec2f(700f, 500f));

        _directory = directory;
        _extensions = extensions;

        GhostButton exitBtn = new GhostButton("X");
        exitBtn.setAlign(UIAlignX.right, UIAlignY.top);
        exitBtn.setPosition(Vec2f(4f, 4f));
        exitBtn.addEventListener("click", &remove);
        addUI(exitBtn);

        HBox headerBox = new HBox;
        headerBox.setAlign(UIAlignX.left, UIAlignY.top);
        headerBox.setPosition(Vec2f(8f, 8f));
        headerBox.setSpacing(4f);
        addUI(headerBox);

        _prevButton = new GhostButton("<");
        _prevButton.isEnabled = false;
        _prevButton.addEventListener("click", &_onPrevious);
        headerBox.addUI(_prevButton);

        _nextButton = new GhostButton(">");
        _nextButton.isEnabled = false;
        _nextButton.addEventListener("click", &_onNext);
        headerBox.addUI(_nextButton);

        GhostButton reloadBtn = new GhostButton("R");
        reloadBtn.addEventListener("click", &_reloadDir);
        headerBox.addUI(reloadBtn);

        _uriField = new PathField(_directory);
        _uriField.setAlign(UIAlignX.left, UIAlignY.top);
        _uriField.setSize(Vec2f(450f, _uriField.getHeight()));
        _uriField.addEventListener("value", &_onUriChange);
        headerBox.addUI(_uriField);

        {
            HBox fileNameBox = new HBox;
            fileNameBox.setAlign(UIAlignX.left, UIAlignY.bottom);
            fileNameBox.setPosition(Vec2f(16f, 8f));
            fileNameBox.setSpacing(8f);
            addUI(fileNameBox);

            Label fileNameLabel = new Label("Nom du fichier:", Etabli.theme.font);
            fileNameLabel.color = Etabli.theme.onNeutral;
            fileNameBox.addUI(fileNameLabel);

            _fileNameField = new TextField;
            _fileNameField.setAlign(UIAlignX.left, UIAlignY.top);
            _fileNameField.setSize(Vec2f(200f, _uriField.getHeight()));
            _fileNameField.addEventListener("value", &_onFileName);
            fileNameBox.addUI(_fileNameField);

            if (_extensions.length) {
                _extensionSelect = new SelectButton(_extensions, _extensions[0]);
                fileNameBox.addUI(_extensionSelect);
            }
        }

        HBox footerBox = new HBox;
        footerBox.setAlign(UIAlignX.right, UIAlignY.bottom);
        footerBox.setPosition(Vec2f(8f, 8f));
        footerBox.setSpacing(8f);
        addUI(footerBox);

        auto cancelBtn = new NeutralButton("Annuler");
        cancelBtn.addEventListener("click", &remove);
        footerBox.addUI(cancelBtn);

        _validateBtn = new AccentButton("Enregistrer");
        _validateBtn.isEnabled = false;
        _validateBtn.addEventListener("click", &_onValidate);
        footerBox.addUI(_validateBtn);

        _list = new VList;
        _list.setAlign(UIAlignX.right, UIAlignY.top);
        _list.setSize(Vec2f(getWidth() - 16f, 400f));
        _list.setPosition(Vec2f(8f, 50f));
        addUI(_list);

        _reloadDir();
    }

    private void _onPrevious() {
        if (!_prevHistory.length)
            return;

        _nextHistory ~= _directory;
        _directory = _prevHistory[$ - 1];
        _prevHistory.length--;
        _prevButton.isEnabled = _prevHistory.length > 0;
        _nextButton.isEnabled = _nextHistory.length > 0;
        _reloadDir();
    }

    private void _onNext() {
        if (!_nextHistory.length)
            return;

        _prevHistory ~= _directory;
        _directory = _nextHistory[$ - 1];
        _nextHistory.length--;
        _prevButton.isEnabled = _prevHistory.length > 0;
        _nextButton.isEnabled = _nextHistory.length > 0;
        _reloadDir();
    }

    private void _onUriChange() {
        string path = _uriField.value;
        if (exists(path)) {
            if (!isDir(path)) {
                path = dirName(path);
            }

            _prevHistory ~= _directory;
            _nextHistory.length = 0;
            _prevButton.isEnabled = true;
            _nextButton.isEnabled = false;

            _directory = path;
            _reloadDir();
        }
        else {
            _uriField.value = _directory;
        }
    }

    private void _onFileName() {
        _validateBtn.isEnabled = _fileNameField.value.length > 0;
    }

    private void _onValidate() {
        if (!_selectedItem)
            return;

        _value = _selectedItem.path;
        if (!isDir(_value)) {
            dispatchEvent("value", false);
        }
        else {
            _prevHistory ~= _directory;
            _nextHistory.length = 0;
            _prevButton.isEnabled = true;
            _nextButton.isEnabled = false;
        }
    }

    package void validateItem(FileItem item_) {
        _selectedItem = item_;
        _value = _selectedItem.path;
        if (!isDir(_value)) {
            dispatchEvent("value", false);
        }
        else {
            _prevHistory ~= _directory;
            _nextHistory.length = 0;
            _prevButton.isEnabled = true;
            _nextButton.isEnabled = false;

            _directory = _value;
            _uriField.value = _directory;
            _reloadDir();
        }
    }

    package void selectItem(FileItem item_) {
        _selectedItem = item_;
        foreach (item; _items) {
            item._updateValue(item == item_);
        }
        if (!isDir(_selectedItem.path)) {
            _fileNameField.value = _selectedItem.name;
        }
    }

    private void _reloadDir() {
        _value = "";
        _list.clearList();
        _selectedItem = null;
        foreach (file; dirEntries(_directory, SpanMode.shallow)) {
            if (!file.isDir && _extensions.length) {
                string fileExt = extension(file);
                bool isValid;
                foreach (ext; _extensions) {
                    if (icmp(fileExt, ext) == 0) {
                        isValid = true;
                        break;
                    }
                }
                if (!isValid)
                    continue;
            }

            FileItem element = new FileItem(file, this);
            _items ~= element;
            _list.addList(element);
        }
    }
}

private final class FileItem : UIElement {
    private {
        Rectangle _rectangle;
        Label _label;
        SaveFile _browser;
        bool _isSelected;
        string _path, _name;
    }

    @property {
        string path() const {
            return _path;
        }

        string name() const {
            return _name;
        }
    }

    this(string path_, SaveFile browser) {
        _path = path_;
        _name = baseName(_path);
        _browser = browser;
        setSize(Vec2f(getParentWidth() - 9f, 32f));

        _rectangle = Rectangle.fill(getSize());
        _rectangle.anchor = Vec2f.zero;
        _rectangle.color = Etabli.theme.foreground;
        _rectangle.isVisible = false;
        addImage(_rectangle);

        _label = new Label(_name, Etabli.theme.font);
        _label.setAlign(UIAlignX.left, UIAlignY.center);
        _label.setPosition(Vec2f(8f, 0f));
        _label.color = Etabli.theme.onNeutral;
        addUI(_label);

        addEventListener("click", &_onClick);
        addEventListener("mouseenter", &_onMouseEnter);
        addEventListener("mouseleave", &_onMouseLeave);
    }

    private void _onClick() {
        _browser.selectItem(this);

        InputEvent.MouseButton ev = Etabli.ui.input.asMouseButton();
        if (ev.clicks > 1) {
            _browser.validateItem(this);
        }
    }

    package void _updateValue(bool value) {
        _isSelected = value;

        if (_isSelected) {
            removeEventListener("mouseenter", &_onMouseEnter);
            removeEventListener("mouseleave", &_onMouseLeave);
            _isSelected = true;
            _rectangle.color = Etabli.theme.accent;
            _label.color = Etabli.theme.onAccent;
            _rectangle.isVisible = true;
        }
        else {
            _isSelected = false;
            _rectangle.color = Etabli.theme.foreground;
            _label.color = Etabli.theme.onNeutral;
            _rectangle.isVisible = isHovered();
            addEventListener("mouseenter", &_onMouseEnter);
            addEventListener("mouseleave", &_onMouseLeave);
        }
    }

    private void _onMouseEnter() {
        _rectangle.isVisible = true;
    }

    private void _onMouseLeave() {
        _rectangle.isVisible = false;
    }
}
