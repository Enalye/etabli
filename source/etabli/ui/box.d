/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.ui.box;

import etabli.ui.element;

import etabli.common;
import etabli.render;

abstract class Box : UIElement {
    Vec2f padding = Vec2f.zero;
    Vec2f margin = Vec2f.zero;
    float spacing = 0f;
}

class HBox : Box {
    override void update() {
        float x = margin.x, y = padding.y;

        foreach (UIElement child; children) {
            child.alignX = UIElement.AlignX.left;
            child.alignY = UIElement.AlignY.top;
            child.position.y = margin.y;
            child.position.x = x;
            x += child.size.x + spacing;
            y = max(y, child.size.y + margin.y * 2f);
        }
        x = max(padding.x, x + margin.x);

        size.x = x;
        size.y = y;
    }
}

class VBox : Box {
    override void update() {
        float x = padding.x, y = margin.y;

        foreach (UIElement child; children) {
            child.alignX = UIElement.AlignX.left;
            child.alignY = UIElement.AlignY.top;
            child.position.x = margin.x;
            child.position.y = y;
            y += child.size.y + spacing;
            x = max(x, child.size.x + margin.x * 2f);
        }
        y = max(padding.y, y + margin.y);

        size.x = x;
        size.y = y;
    }
}
