/**
   Drawable 

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.drawable;

import atelier.core.vec2;

interface IDrawable {
	void draw(const Vec2f pos);
}