/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.navigation.breadcrumbs;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.button;
import etabli.ui.core;

final class Breadcrumbs : UIElement {
    private {
        GhostButton[] _parts;
        Label[] _separators;
        HBox _box;
        string[] _path;
        float _maxWidth;
    }

    @property {
        string[] value() {
            return _path;
        }

        string[] value(string[] path) {
            if (_path == path)
                return _path;
            _path = path;
            _reloadPath();
            return _path;
        }
    }

    this(string[] path = [], float maxWidth = 250f) {
        _path = path;
        _maxWidth = maxWidth;

        _box = new HBox;
        _box.setAlign(UIAlignX.left, UIAlignY.center);
        _box.setSpacing(4f);
        addUI(_box);

        _reloadPath();

        _box.addEventListener("size", &_onSize);
    }

    void addPath(string element) {
        _path ~= element;

        if (_parts.length > 0) {
            Label sep = new Label(">", Etabli.theme.font);
            sep.color = Etabli.theme.onNeutral;
            _box.addUI(sep);
            _separators ~= sep;
        }

        GhostButton btn = new GhostButton(element);
        btn.addEventListener("click", ((i) => ({ _onCrumbClick(i); }))(_parts.length));
        _box.addUI(btn);
        _parts ~= btn;
    }

    void removePath() {
        if (!_parts.length)
            return;
        _parts[$ - 1].remove();
        _parts.length--;

        if (!_separators.length)
            return;
        _separators[$ - 1].remove();
        _separators.length--;
    }

    private void _onSize() {
        Vec2f size = _box.getSize();

        if (size.x > _maxWidth) {
            _box.setPosition(Vec2f(_maxWidth - size.x, 0f));
            size.x = _maxWidth;
        }
        else {
            _box.setPosition(Vec2f.zero);
        }

        setSize(size);
    }

    private void _reloadPath() {
        _box.clearUI();
        _parts.length = 0;
        _separators.length = 0;
        foreach (element; _path) {
            addPath(element);
        }
    }

    private void _onCrumbClick(size_t index) {
        for (size_t i = index + 1; i < _parts.length; ++i) {
            _parts[i].remove();
        }
        _parts.length = index + 1;

        for (size_t i = index; i < _separators.length; ++i) {
            _separators[i].remove();
        }
        _separators.length = index;

        _path.length = _parts.length;

        dispatchEvent("value", false);
    }
}
