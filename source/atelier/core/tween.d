/**
    Tweening

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.tween;

import std.math;

import atelier.common;
import atelier.core.util;

/// Change the way Timer behave. \
/// Stopped: It will do nothing and isRunning will be false. \
/// Once: Will run from 0 to 1 in one duration then stop. \
/// Loop: Will run from 0 to 1 in one duration then restart from 0 again, etc. \
/// Bounce: Will run from 0 to 1 in one duration then from 1 to 0, etc. \
enum TimeMode {
	Stopped,
	Once,
	Loop,
	Bounce
}

/**
	Simple updatable timer. \
	Start with start(Duration, TimeMode) and update with update(Deltatime). \
	Returns a value between 0 and 1.
*/
struct Timer {
	private {
		float _time = 0f, _speed = 0f;
		bool _isReversed = false;
		TimeMode _mode = TimeMode.Stopped;
	}

	@property {
		/// The relative time elapsed between 0 and 1.
		float time() const { return _time; }

		/// Duration in seconds from witch the timer goes from 0 to 1 (framerate dependent).
		float duration() const { return _speed * nominalFps; }
		/// Ditto
		float duration(float newDuration) {
			if(newDuration <= 0f) {
				_speed = 0f;
				_time = 1f;
			}
			else
				_speed = 1f / (nominalFps * newDuration);
			return newDuration;
		}

		/// Is the timer currently running ?
		bool isRunning() const { return (_mode != TimeMode.Stopped); }

		/// Is the timer behaving backwards ?
		bool isReversed() const { return _isReversed; }
		/// Ditto
		bool isReversed(bool newIsReversed) { return _isReversed = newIsReversed; }

		/// Current behavior of the timer.
		TimeMode mode() const { return _mode; }
	}
	
	/// Immediatly starts the timer with the specified behavior and running time. \
	/// Note that Loop and Bounce will never stop until you tell him to.
	void start(float newDuration, TimeMode newTimeMode = TimeMode.Once) {
		_time = 0f;
		_isReversed = false;
		duration(newDuration);
		_mode = newTimeMode;
	}

	/// Same as start() but goes in reverse (from 1 to 0).
	void startReverse(float newDuration, TimeMode newTimeMode = TimeMode.Once) {
		_time = 1f;
		_isReversed = true;
		duration(newDuration);
		_mode = newTimeMode;
	}

	/// Immediatly stops the timer.
    void stop() {
        _mode = TimeMode.Stopped;
    }

	/// Update with the current deltatime (~1)
	/// If you don't call update, the timer won't advance.
	void update(float deltaTime) {
		final switch(_mode) with(TimeMode) {
		case Stopped:
			break;
		case Once:
			if(_isReversed) {
				if(_time > 0f)
					_time -= _speed * deltaTime;
				if(_time < 0f) {
					_time = 0f;
					_mode = TimeMode.Stopped;
				}
			}
			else {
				if(_time < 1f)
					_time += _speed * deltaTime;
				if(_time > 1f) {
					_time = 1f;
					_mode = TimeMode.Stopped;
				}
			}
			break;
		case Loop:
			if(_time < 1f)
				_time += _speed * deltaTime;
			if(_time > 1f)
				_time = (_time - 1f) + (_speed * deltaTime);
			break;
		case Bounce:
			if(_isReversed) {
				if(_time > 0f)
					_time -= _speed * deltaTime;
				if(_time < 0f) {
					_time = -(_time - (_speed * deltaTime));
					_isReversed = false;
				}
			}
			else {
				if(_time < 1f)
					_time += _speed * deltaTime;
				if(_time > 1f) {
					_time = 1f - ((_time - 1f) + (_speed * deltaTime));
					_isReversed = true;
				}
			}
			break;
		}
	}
}

alias EasingFunction = float function(float);

/// Returns an easing function.
EasingFunction getEasingFunction(string name) {
    switch(name) {
    case "linear": return &easeLinear;
    case "sine-in": return &easeInSine;
    case "sine-out": return &easeOutSine;
    case "sine-in-out": return &easeInOutSine;
    case "quad-in": return &easeInQuad;
    case "quad-out": return &easeOutQuad;
    case "quad-in-out": return &easeInOutQuad;
    case "cubic-in": return &easeInCubic;
    case "cubic-out": return &easeOutCubic;
    case "cubic-in-out": return &easeInOutCubic;
    case "quart-in": return &easeInQuart;
    case "quart-out": return &easeOutQuart;
    case "quart-in-out": return &easeInOutQuart;
    case "quint-in": return &easeInQuint;
    case "quint-out": return &easeOutQuint;
    case "quint-in-out": return &easeInOutQuint;
    case "exp-in": return &easeInExp;
    case "exp-out": return &easeOutExp;
    case "exp-in-out": return &easeInOutExp;
    case "circ-in": return &easeInCirc;
    case "circ-out": return &easeOutCirc;
    case "circ-in-out": return &easeInOutCirc;
    case "back-in": return &easeInBack;
    case "back-out": return &easeOutBack;
    case "back-in-out": return &easeInOutBack;
    case "elastic-in": return &easeInElastic;
    case "elastic-out": return &easeOutElastic;
    case "elastic-in-out": return &easeInOutElastic;
    case "bounce-in": return &easeInBounce;
    case "bounce-out": return &easeOutBounce;
    case "bounce-in-out": return &easeInOutBounce;
    default:
        throw new Exception("Undefined ease function " ~ name);
    }
}

/// Linear 
float easeLinear(float t) {
	return t;
}

/// Sine
float easeInSine(float t) {
	return sin((t - 1f) * PI_2) + 1f;
}

float easeOutSine(float t) {
	return sin(t * PI_2);
}

float easeInOutSine(float t) {
	return (1f - cos(t * PI)) / 2f;
}

//Quad
float easeInQuad(float t) {
	return t * t;
}

float easeOutQuad(float t) {
	return -(t * (t - 2));
}

float easeInOutQuad(float t) {
	if(t < .5f)
		return 2f * t * t;
	else
		return (-2f * t * t) + (4f * t) - 1f;
}

//Cubic
float easeInCubic(float t) {
	return t * t * t;
}

float easeOutCubic(float t) {
	t = (t - 1f);
	t = (t * t * t + 1f);
	return t;
}

float easeInOutCubic(float t) {
	if(t < .5f)
		return 4f * t * t * t;
	else {
		float f = ((2f * t) - 2f);
		return .5f * f * f * f + 1f;
	}
}

//Quart
float easeInQuart(float t) {
	return t * t * t * t;
}

float easeOutQuart(float t) {
	float f = (t - 1f);
	return f * f * f * (1f - t) + 1f;
}

float easeInOutQuart(float t) {
	if(t < .5f)
		return 8f * t * t * t * t;
	else {
		float f = (t - 1f);
		return -8f * f * f * f * f + 1f;
	}
}

//Quint
float easeInQuint(float t) {
	return t * t * t * t * t;
}

float easeOutQuint(float t) {
	float f = (t - 1f);
	return f * f * f * f * f + 1f;
}

float easeInOutQuint(float t) {
	if(t < .5f)
		return 16f * t * t * t * t * t;
	else {
		float f = ((2f * t) - 2f);
		return  .5f * f * f * f * f * f + 1f;
	}
}

//Exp
float easeInExp(float t) {
	return (t == 0f) ? t : pow(2f, 10f * (t - 1f));
}

float easeOutExp(float t) {
	return (t == 1f) ? t : 1f - pow(2f, -10f * t);
}

float easeInOutExp(float t) {
	if(t == 0f || t == 1f)
		return t;
	if(t < .5f)
		return .5f * pow(2f, (20f * t) - 10f);
	else
		return -.5f * pow(2f, (-20f * t) + 10f) + 1f;
}

//Circ
float easeInCirc(float t) {
	return 1f - sqrt(1f - (t * t));
}

float easeOutCirc(float t) {
	return sqrt((2f - t) * t);
}

float easeInOutCirc(float t) {
	if(t < .5f)
		return .5f * (1f - sqrt(1f - 4f * (t * t)));
	else
		return .5f * (sqrt(-((2f * t) - 3f) * ((2f * t) - 1f)) + 1f);
}

//Back
float easeInBack(float t) {
	return t * t * t - t * sin(t * PI);
}

float easeOutBack(float t) {
	float f = (1f - t);
	return 1f - (f * f * f - f * sin(f * PI));
}

float easeInOutBack(float t) {
	if(t < .5f) {
		t *= 2f;
		return (t * t * t - t * sin(t * PI)) / 2f;
	}
	t = (1f - (2f*t - 1f));
	return (1f - (t * t * t - t * sin(t * PI))) / 2f + .5f;
}

//Elastic
float easeInElastic(float t) {
	return sin(13f * PI_2 * t) * pow(2f, 10f * (t - 1f));
}

float easeOutElastic(float t) {
	return sin(-13f * PI_2 * (t + 1)) * pow(2f, -10f * t) + 1f;
}

float easeInOutElastic(float t) {
	if(t < .5f)
		return .5f * sin(13f * PI_2 * (2f * t)) * pow(2f, 10f * ((2f * t) - 1f));
	else
		return .5f * (sin(-13f * PI_2 * ((2f * t - 1f) + 1f)) * pow(2f, -10f * (2f * t - 1f)) + 2f);
}

//Bounce
float easeInBounce(float t) {
	return 1f - easeOutBounce(1f - t);
}

float easeOutBounce(float t) {
	if(t < 4f/11f)
		return (121f * t * t)/16f;
	else if(t < 8f/11f)
		return (363f/40f * t * t) - (99f/10f * t) + 17f/5f;
	else if(t < 9f/10f)
		return (4356f/361f * t * t) - (35442f/1805f * t) + 16061f/1805f;
	return (54f/5f * t * t) - (513f/25f * t) + 268f/25f;
}

float easeInOutBounce(float t) {
	if(t < .5f)
		return easeInBounce(t * 2f) / 2f;
	else
		return easeOutBounce(t * 2f - 1f) / 2f + .5f;
}