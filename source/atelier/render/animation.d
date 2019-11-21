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
		Texture _texture;
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

		/// Texture.
		Texture texture(Texture texture_) { return _texture = texture_; }
		/// Ditto
		const(Texture) texture() const { return _texture; }
	}

	/// Texture regions (the source size) for each frames.
	Vec4i[] frames;

    /// Destination size.
	Vec2f size;

	/// Angle in which the sprite will be rendered.
	float angle = 0f;

	/// Mirroring property.
	Flip flip = Flip.none;

	/// Color added to the tile.
    Color color = Color.white;

	/// Blending algorithm.
    Blend blend = Blend.alpha;

	/// Easing algorithm
	EasingAlgorithm easing = EasingAlgorithm.linear;

	/// Empty animation.
	this() {}

	/// Create an animation from a series of clips.
    this(Texture tex, const Vec2f size_, Vec4i[] frames_) {
		assert(tex, "Null texture");
		_texture = tex;
		size = size_;
		frames = frames_;
	}

	/// Create an animation from a tileset.
	this(Texture tex,
		const Vec4i startTileClip,
		const int columns, const int lines, const int maxcount = 0,
		const Vec2i margin = Vec2i.zero) {
		assert(tex, "Null texture");
		_texture = tex;
		size = to!Vec2f(startTileClip.zw);
		int count;
		for(int y; y < lines; y ++) {
			for(int x; x < columns; x ++) {
				Vec4i currentClip = Vec4i(
					startTileClip.x + x * (startTileClip.z + margin.x),
					startTileClip.y + y * (startTileClip.w + margin.y),
					startTileClip.z,
					startTileClip.w);
				frames ~= currentClip;

				if(maxcount > 0) {
					count ++;
					if(count >= maxcount)
						return;
				}
			}
		}
	}

	/// Copy ctor.
	this(Animation animation) {
		_timer = animation._timer;
		_texture = animation._texture;
		frames = animation.frames;
		size = animation.size;
		angle = animation.angle;
		flip = animation.flip;
		color = animation.color;
		blend = animation.blend;
		easing = animation.easing;
	}

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
		assert(_texture, "No _texture loaded.");
		assert(_currentFrameID < frames.length, "Animation frame id out of bounds.");
		
		const Vec4i currentClip = frames[_currentFrameID];
		const Vec2f finalSize = size * transformScale();
        _texture.setColorMod(color, blend);
        _texture.draw(transformRenderSpace(position), finalSize, currentClip, angle, flip);
        _texture.setColorMod(Color.white);
	}
}