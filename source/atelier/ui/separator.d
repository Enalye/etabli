module atelier.ui.separator;

import atelier.core;
import atelier.render;
import atelier.ui.gui_element;

/// Horizontal bar
class HSeparator : GuiElement {
    override void draw() {
        drawLine(Vec2f(origin.x, center.y), Vec2f(origin.x + size.x, center.y), color, alpha);
    }
}

/// Vertical bar
class VSeparator : GuiElement {
    override void draw() {
        drawLine(Vec2f(center.x, origin.y), Vec2f(center.x, origin.y + size.y), color, alpha);
    }
}