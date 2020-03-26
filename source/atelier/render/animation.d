/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
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
	/// Change the way the animation is playing.
	/// once: Play each frames sequencially then stop.
	/// reverse: Play each frames from the last to the first one then stop.
	/// loop: Like "once", but go back to the first frame instead of stopping.
	/// loopReverse: Like "reverse", but go back to the last frame instead of stopping.
	/// bounce: Play like the "once" mode, then "reverse", then "once", etc
	/// bounceReverse: Like "bounce", but the order is reversed.
	enum Mode {
		once,
        reverse,
		loop,
        loopReverse,
		bounce,
        bounceReverse
	}

	private {
		Texture _texture;
		Timer _timer;
		int _currentFrameId;
		bool _isRunning = true, _isReversed;
	}

	@property {
		/// Is the animation currently playing ?
		bool isPlaying() const { return _timer.isRunning; }

		/// Duration in seconds from witch the timer goes from 0 to 1 (framerate dependent). \
        /// Only positive non-null values.
		float duration() const { return _timer.duration; }
		/// Ditto
		float duration(float v) { return _timer.duration = v; }

		/// The current frame being used.
		int currentFrameID() const { return _currentFrameId; }

		/// Texture.
		Texture texture(Texture texture_) { return _texture = texture_; }
		/// Ditto
		const(Texture) texture() const { return _texture; }
	}

	/// Texture regions (the source size) for each frames.
	Vec4i[] frames;

    /// Destination size.
	Vec2f size;

	/// Relative center of the sprite.
	Vec2f anchor = Vec2f.half;

	/// Angle in which the sprite will be rendered.
	float angle = 0f;

	/// Behavior of the animation.
	Mode mode = Mode.loop;

	/// Mirroring property.
	Flip flip = Flip.none;

	/// Color added to the tile.
    Color color = Color.white;

	/// Blending algorithm.
    Blend blend = Blend.alpha;

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
		anchor = animation.anchor;
		angle = animation.angle;
		flip = animation.flip;
		color = animation.color;
		blend = animation.blend;
		mode = animation.mode;
	}

	/// Starts the animation from the beginning.
	void start() {
		_timer.start();
		reset();
		_isRunning = true;
	}

	/// Stops and resets the animation.
	void stop() {
		_timer.stop();
		reset();
		_isRunning = false;
	}

	/// Pauses the animation where it is.
	void pause() {
		_timer.pause();
		_isRunning = false;
	}

	/// Resumes the animation from where it was.
	void resume() {
		_timer.resume();
		_isRunning = true;
	}

	/// Goes back to starting settings.
    void reset() {
        final switch(mode) with(Mode) {
        case once:
            _currentFrameId = 0;
            _isReversed = false;
            break;
        case reverse:
            _currentFrameId = (cast(int) frames.length) - 1;
            _isReversed = false;
            break;
        case loop:
            _currentFrameId = 0;
            _isReversed = false;
            break;
        case loopReverse:
            _currentFrameId = (cast(int) frames.length) - 1;
            _isReversed = false;
            break;
        case bounce:
            _currentFrameId = 0;
            _isReversed = false;
            break;
        case bounceReverse:
            _currentFrameId = (cast(int) frames.length) - 1;
            _isReversed = true;
            break;
        }
    }

	/// Run the animation.
	void update(float deltaTime) {
		_timer.update(deltaTime);
		if(!_timer.isRunning && _isRunning) {
			advance();
		}
	}
	
	/// Go to the next frame.
	void advance() {
		_timer.start();
		if(!frames.length) {
			_currentFrameId = -1;
			return;
		}
		final switch(mode) with(Mode) {
		case once:
			_currentFrameId ++;
			if(_currentFrameId >= frames.length) {
				_currentFrameId = (cast(int) frames.length) - 1;
				_isRunning = false;
			}
			break;
        case reverse:
			_currentFrameId --;
			if(_currentFrameId < 0) {
				_currentFrameId = 0;
				_isRunning = false;
			}
			break;
        case loop:
			_currentFrameId ++;
			if(_currentFrameId >= frames.length) {
				_currentFrameId = 0;
			}
			break;
        case loopReverse:
			_currentFrameId --;
			if(_currentFrameId < 0) {
				_currentFrameId = (cast(int) frames.length) - 1;
			}
			break;
        case bounce:
        case bounceReverse:
			if(_isReversed) {
				_currentFrameId --;
				if(_currentFrameId <= 0) {
					_currentFrameId = 0;
					_isReversed = false;
				}
			}
			else {
				_currentFrameId ++;
				if((_currentFrameId + 1) >= frames.length) {
					_currentFrameId = (cast(int) frames.length) - 1;
					_isReversed = true;
				}
			}
			break;
		}
	}
	
	/// Render the current frame.
	void draw(const Vec2f position) {
		if(_currentFrameId < 0 || !frames.length)
			return;
		assert(_texture, "No texture loaded.");
		assert(_currentFrameId < frames.length, "Animation frame id out of bounds.");
		
		const Vec4i currentClip = frames[_currentFrameId];
		const Vec2f finalSize = size * transformScale();
        _texture.setColorMod(color, blend);
        _texture.draw(transformRenderSpace(position), finalSize, currentClip, angle, flip, anchor);
        _texture.setColorMod(Color.white);
	}
}