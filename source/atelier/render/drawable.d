/**
    Drawable 

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.drawable;

import atelier.core.vec2;

/// Everything that can be rendered.
interface Drawable {
    /// Render the drawable.
	void draw(const Vec2f position);
}