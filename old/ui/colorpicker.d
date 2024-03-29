/**
    Color picker

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.ui.colorpicker;

import etabli.core;
import etabli.render;
import etabli.common;

import etabli.ui;

/+
class ColorViewer: UIElement {
	Color color;

	this() {}

	override void onEvent(Event event) {}
	override void update(float deltaTime) {}
	override void draw() {
		drawFilledRect(center - size / 2f, size, color);
	}
}

class ColorPicker: UIElement {
	private {
		DropDownList _blendList;
		Slider _redSlider, _blueSlider, _greenSlider, _alphaSlider;
		ColorViewer _viewer;
	}

	@property {
		Color color() const {
			return Color(_redSlider.value01, _blueSlider.value01,
				_greenSlider.value01, _alphaSlider.value01);
		}

		Blend blend() const {
			switch(_blendList.selected) {
			case 0:
				return Blend.AlphaBlending;
			case 1:
				return Blend.AdditiveBlending;
			case 2:
				return Blend.ModularBlending;
			case 3:
				return Blend.NoBlending;
			default:
				throw new Exception("Invalid kind of blending");
			}
		}
	}

	this(Color newColor = Color.white, Blend newBlend = Blend.AlphaBlending) {
		Slider makeSlider(VContainer container, string title) {
			auto slider = new HSlider;
			slider.min = 0;
			slider.min = 255;
			slider.step = 255;
			slider.size = Vec2f(255f, 10f);

			auto hc = new HContainer;
			hc.spacing = Vec2f(10f, 0f);
			hc.addNodeGui(new Label(title));
			hc.addNodeGui(slider);
			container.addNodeGui(hc);
			return slider;
		}

		auto container = new VContainer;
		container.spacing = Vec2f(0f, 10f);
		_redSlider = makeSlider(container, "R");
		_blueSlider = makeSlider(container, "G");
		_greenSlider = makeSlider(container, "B");
		_alphaSlider = makeSlider(container, "A");

		_blendList = new DropDownList(Vec2f(200f, 25f), 4U);
		foreach(mode; [
			"Alpha Blending", "Additive Blending",
			"Modular Blending", "No Blending"])
			_blendList.add(mode);
		container.addNodeGui(_blendList);

		_redSlider.value01 = newColor.r;
		_blueSlider.value01 = newColor.g;
		_greenSlider.value01 = newColor.b;
		_alphaSlider.value01 = newColor.a;

		_viewer = new ColorViewer;
		_viewer.size = Vec2f(100f, 100f);

		auto hc2 = new HContainer;
		hc2.spacing = Vec2f(20f, 5f);
		hc2.addNodeGui(container);
		hc2.addNodeGui(_viewer);

		super("Couleur", hc2.size);
		layout.addNodeGui(hc2);

		switch(newBlend) with(Blend) {
		case AlphaBlending:
			_blendList.selected = 0U;
			break;
		case AdditiveBlending:
			_blendList.selected = 1U;
			break;
		case ModularBlending:
			_blendList.selected = 2U;
			break;
		case NoBlending:
			_blendList.selected = 3U;
			break;
		default:
			_blendList.selected = 0U;
		}
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		_viewer.color = color();
	}
}+/
