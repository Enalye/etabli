/**
    Animation

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.render.animation;

import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import atelier.common;
import atelier.core;

import atelier.render.window, atelier.render.texture, atelier.render.drawable;
import atelier.render.tileset, atelier.render.sprite;

/// Series of animation frames played successively.
final class Animation : Drawable {
	private {
		Timer _timer;
		int _currentFrameID;
	}

	@property {
		/// Is the animation currently playing ?
		bool isPlaying() const { return _timer.isRunning; }

		/// Animation behaviour.
		Timer.Mode mode() const { return _timer.mode; }
		/// Ditto
		Timer.Mode mode(Timer.Mode v) { return _timer.mode = v; }

		/// Duration in seconds from witch the timer goes from 0 to 1 (framerate dependent). \
        /// Only positive non-null values.
		float duration() const { return _timer.duration; }
		/// Ditto
		float duration(float v) { return _timer.duration = v; }

		/// The current frame being used.
		int currentFrameID() const { return _currentFrameID; }
	}

    /// Source material.
    Texture texture;

	/// Texture regions (the source size) for each frames.
	Vec4i[] frames;

    /// Destination size.
	Vec2f size = Vec2f.zero;

	/// Angle in which the sprite will be rendered.
	float angle = 0f;

	/// Mirroring property.
	Flip flip = Flip.none;

	/// Color added to the tile.
    Color color = Color.white;

	/// Blending algorithm.
    Blend blend = Blend.alpha;

	/// Easing algorithm
	EasingAlgorithm easing;

	/// Ctor
    this() {}

	/// Starts the animation from the beginning.
	void start() {
		_timer.start();
		_currentFrameID = 0U;
	}

	/// Stops and resets the animation.
	void stop() {
		_timer.stop();
		_currentFrameID = 0U;
	}

	/// Pauses the animation where it is.
	void pause() {
		_timer.pause();
	}

	/// Resumes the animation from where it was.
	void resume() {
		_timer.resume();
	}

	/// Run the animation.
	void update(float deltaTime) {
		_timer.update(deltaTime);
		const float easedTime = getEasingFunction(easing)(_timer.value01());
		if(!frames.length)
			_currentFrameID = -1;
		else
			_currentFrameID = clamp(cast(int)lerp(0f, to!float(frames.length), easedTime), 0, (cast(int) frames.length) - 1);       
	}
	
	/// Render the current frame.
	void draw(const Vec2f position) {
		if(_currentFrameID < 0 || !frames.length)
			return;
		assert(texture, "No texture loaded.");
		assert(_currentFrameID < frames.length, "Animation frame id out of bounds.");
		
		const Vec4i currentClip = frames[_currentFrameID];
		const Vec2f finalSize = size * transformScale();
        texture.setColorMod(color, blend);
        texture.draw(transformRenderSpace(position), finalSize, currentClip, angle, flip);
        texture.setColorMod(Color.white);
	}
}