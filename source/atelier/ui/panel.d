/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module atelier.ui.panel;

import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element;

class Panel: GuiElement {
	private {
		Sprite _cornerULSprite, _cornerURSprite, _cornerDLSprite, _cornerDRSprite;
		Sprite _borderUpSprite, _borderDownSprite, _borderLeftSprite, _borderRightSprite;
	}
	
	this() {
		isInteractable = false;
		_cornerULSprite = fetch!Sprite("gui_window_corner_up_left");
		_cornerURSprite = fetch!Sprite("gui_window_corner_up_right");
		_cornerDLSprite = fetch!Sprite("gui_window_corner_down_left");
		_cornerDRSprite = fetch!Sprite("gui_window_corner_down_right");
		_borderUpSprite = fetch!Sprite("gui_window_border_up");
		_borderDownSprite = fetch!Sprite("gui_window_border_down");
		_borderLeftSprite = fetch!Sprite("gui_window_border_left");
		_borderRightSprite = fetch!Sprite("gui_window_border_right");
	}

	override void draw() {
		Vec2f panelSize = size - 16f;
		Vec2f halfSize = panelSize / 2f;

		drawFilledRect(center - halfSize, panelSize, Color.white * .11f);
		drawFilledRect(center - halfSize, Vec2f(panelSize.x, 50f), Color.white);
		drawFilledRect(center + Vec2f(-halfSize.x, halfSize.y - 50f), Vec2f(panelSize.x, 50f), Color.white);
		
		_cornerULSprite.drawUnchecked(center - halfSize);
		_cornerURSprite.drawUnchecked(center + Vec2f(halfSize.x, -halfSize.y));
		_cornerDLSprite.drawUnchecked(center + Vec2f(-halfSize.x, halfSize.y));
		_cornerDRSprite.drawUnchecked(center + halfSize);

		_borderUpSprite.size = Vec2f(panelSize.x - 16f, 16f);
		_borderDownSprite.size = Vec2f(panelSize.x - 16f, 16f);
		_borderLeftSprite.size = Vec2f(16f, panelSize.y - 16f);
		_borderRightSprite.size = Vec2f(16f, panelSize.y - 16f);

		_borderUpSprite.drawUnchecked(center + Vec2f(0f, -halfSize.y));
		_borderDownSprite.drawUnchecked(center + Vec2f(0f, halfSize.y));
		_borderLeftSprite.drawUnchecked(center + Vec2f(-halfSize.x, 0f));
		_borderRightSprite.drawUnchecked(center + Vec2f(halfSize.x, 0f));
	}
}