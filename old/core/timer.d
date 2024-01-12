/**
    Tweening

    Copyright: (c) Enalye 2019
    License: Zlib
    Authors: Enalye
*/

module etabli.core.timer;

import std.algorithm.comparison : clamp;
import etabli.common;

/**
	Simple updatable timer. \
	Start with start() and update with update(Deltatime). \
	Returns a value between 0 and 1.
*/
struct Timer {
    /// Change the way Timer behave. \
    /// once: Will run from 0 to 1 in one duration then stop. \
    /// reverse: Will run from 1 to 0 in one duration then stop. \
    /// loop: Will run from 0 to 1 in one duration then restart from 0 again, etc. \
    /// loopReverse: Will run from 1 to 0 in one duration then restart from 1 again, etc. \
    /// bounce: Will run from 0 to 1 in one duration then from 1 to 0, etc. \
    /// bounceReverse: Will run from 1 to 0 in one duration then from 0 to 1, etc.
    enum Mode {
        once,
        reverse,
        loop,
        loopReverse,
        bounce,
        bounceReverse
    }

    private {
        float _time = 0f, _duration = 1f;
        bool _isRunning = false, _isReversed = false;
        Mode _mode = Mode.once;
    }

    @property {
        /// The relative time elapsed between 0 and 1.
        float value01() const {
            return _time;
        }
        /// Ditto
        float value01(float value_) {
            return _time = clamp(value_, 0f, 1f);
        }

        /// Time elapsed between 0 and the max duration.
        float value() const {
            return _time * _duration;
        }
        /// Ditto
        float value(float value_) {
            return _time = clamp(value_ / _duration, 0f, 1f);
        }

        /// Duration in seconds from witch the timer goes from 0 to 1 (framerate dependent). \
        /// Only positive non-null values.
        float duration() const {
            return _duration;
        }
        /// Ditto
        float duration(float duration_) {
            return _duration = duration_;
        }

        /// Is the timer currently running ?
        bool isRunning() const {
            return _isRunning;
        }

        /// Current behavior of the timer.
        Mode mode() const {
            return _mode;
        }
        /// Ditto
        Mode mode(Mode v) {
            return _mode = v;
        }
    }

    /// Immediatly starts the timer. \
    /// Note that loop and bounce behaviours will never stop until you tell him to.
    void start() {
        _isRunning = true;
        reset();
    }

    /// Immediatly starts the timer with the specified running time. \
    /// Note that loop and bounce behaviours will never stop until you tell him to.
    void start(float duration_) {
        _isRunning = true;
        duration(duration_);
        reset();
    }

    /// Immediatly stops the timer and resets it.
    void stop() {
        _isRunning = false;
        reset();
    }

    /// Interrupts the timer without resetting it.
    void pause() {
        _isRunning = false;
    }

    /// Resumes the timer from where it was stopped.
    void resume() {
        _isRunning = true;
    }

    /// Goes back to starting settings.
    void reset() {
        final switch (_mode) with (Mode) {
        case once:
            _time = 0f;
            _isReversed = false;
            break;
        case reverse:
            _time = 1f;
            _isReversed = false;
            break;
        case loop:
            _time = 0f;
            _isReversed = false;
            break;
        case loopReverse:
            _time = 1f;
            _isReversed = false;
            break;
        case bounce:
            _time = 0f;
            _isReversed = false;
            break;
        case bounceReverse:
            _time = 1f;
            _isReversed = false;
            break;
        }
    }

    /// Update with the current deltatime (~1)
    /// If you don't call update, the timer won't advance.
    void update(float deltaTime) {
        if (!_isRunning)
            return;
        if (_duration <= 0f) {
            _time = _isReversed ? 0f : 1f;
            _isRunning = false;
            return;
        }
        const float stepInterval = deltaTime / (getNominalFPS() * _duration);
        final switch (_mode) with (Mode) {
        case once:
            if (_time < 1f)
                _time += stepInterval;
            if (_time >= 1f) {
                _time = 1f;
                _isRunning = false;
            }
            break;
        case reverse:
            if (_time > 0f)
                _time -= stepInterval;
            if (_time <= 0f) {
                _time = 0f;
                _isRunning = false;
            }
            break;
        case loop:
            if (_time < 1f)
                _time += stepInterval;
            if (_time >= 1f)
                _time = (_time - 1f) + stepInterval;
            break;
        case loopReverse:
            if (_time > 0f)
                _time -= stepInterval;
            if (_time <= 0f)
                _time = (1f - _time) - stepInterval;
            break;
        case bounce:
            if (_isReversed) {
                if (_time > 0f)
                    _time -= stepInterval;
                if (_time <= 0f) {
                    _time = -(_time - stepInterval);
                    _isReversed = false;
                }
            }
            else {
                if (_time < 1f)
                    _time += stepInterval;
                if (_time >= 1f) {
                    _time = 1f - ((_time - 1f) + stepInterval);
                    _isReversed = true;
                }
            }
            break;
        case bounceReverse:
            if (_isReversed) {
                if (_time < 1f)
                    _time += stepInterval;
                if (_time >= 1f) {
                    _time = 1f - ((_time - 1f) + stepInterval);
                    _isReversed = false;
                }
            }
            else {
                if (_time > 0f)
                    _time -= stepInterval;
                if (_time <= 0f) {
                    _time = -(_time - stepInterval);
                    _isReversed = true;
                }
            }
            break;
        }
    }
}
