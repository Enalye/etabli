/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.ui.core.icon;

import etabli.common;
import etabli.core;
import etabli.render;
import etabli.ui.core.element;

final class Icon : UIElement {
    private {
        Sprite _icon;
    }

    this(string icon) {
        isEnabled = false;
        setIcon(icon);
    }

    void setIcon(string icon) {
        if (_icon) {
            _icon.remove();
        }

        _icon = Etabli.res.get!Sprite(icon);
        _icon.anchor = Vec2f.zero;
        _icon.position = Vec2f.zero;
        setSize(_icon.size);
        addImage(_icon);
    }
}
