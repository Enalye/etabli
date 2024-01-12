module etabli.ui.separator;

import etabli.core;
import etabli.render;
import etabli.ui.gui_element;

/// Horizontal bar
class HSeparator : UIElement {
    override void draw() {
        drawLine(Vec2f(origin.x, center.y), Vec2f(origin.x + size.x, center.y), color, alpha);
    }
}

/// Vertical bar
class VSeparator : UIElement {
    override void draw() {
        drawLine(Vec2f(center.x, origin.y), Vec2f(center.x, origin.y + size.y), color, alpha);
    }
}