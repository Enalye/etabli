/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.common.timer;

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
        int _time = 0, _duration = 60;
        bool _isRunning = false, _isReversed = false;
        Mode _mode = Mode.once;
    }

    @property {
        /// The relative time elapsed between 0 and 1.
        float value01() const {
            return cast(float) _time / cast(float) _duration;
        }

        /// Time elapsed between 0 and the max duration.
        int value() const {
            return _time;
        }

        /// Duration in seconds from witch the timer goes from 0 to 1 (framerate dependent). \
        /// Only positive non-null values.
        int duration() const {
            return _duration;
        }
        /// Ditto
        int duration(int duration_) {
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
        Mode mode(Mode mode_) {
            return _mode = mode_;
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
    void start(int duration_) {
        _isRunning = true;
        _duration = duration_;
        reset();
    }

    /// Ditto
    void start(int duration_, Mode mode_) {
        _isRunning = true;
        _duration = duration_;
        _mode = mode_;
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
            _time = 0;
            _isReversed = false;
            break;
        case reverse:
            _time = _duration;
            _isReversed = false;
            break;
        case loop:
            _time = 0;
            _isReversed = false;
            break;
        case loopReverse:
            _time = _duration;
            _isReversed = false;
            break;
        case bounce:
            _time = 0;
            _isReversed = false;
            break;
        case bounceReverse:
            _time = _duration;
            _isReversed = false;
            break;
        }
    }

    /// Update with the current deltatime (~1)
    /// If you don't call update, the timer won't advance.
    void update(int ticks = 1) {
        if (!_isRunning)
            return;

        if (_duration <= 0) {
            _time = _isReversed ? 0 : _duration;
            _isRunning = false;
            return;
        }

        final switch (_mode) with (Mode) {
        case once:
            if (_time < _duration)
                _time += ticks;
            if (_time >= _duration) {
                _time = _duration;
                _isRunning = false;
            }
            break;
        case reverse:
            if (_time > 0)
                _time -= ticks;
            if (_time <= 0) {
                _time = 0;
                _isRunning = false;
            }
            break;
        case loop:
            if (_time < _duration)
                _time += ticks;
            if (_time >= _duration)
                _time = (_time - _duration) + ticks;
            break;
        case loopReverse:
            if (_time > 0)
                _time -= ticks;
            if (_time <= 0)
                _time = (_duration - _time) - ticks;
            break;
        case bounce:
            if (_isReversed) {
                if (_time > 0)
                    _time -= ticks;
                if (_time <= 0) {
                    _time = -(_time - ticks);
                    _isReversed = false;
                }
            }
            else {
                if (_time < _duration)
                    _time += ticks;
                if (_time >= _duration) {
                    _time = _duration - ((_time - _duration) + ticks);
                    _isReversed = true;
                }
            }
            break;
        case bounceReverse:
            if (_isReversed) {
                if (_time < _duration)
                    _time += ticks;
                if (_time >= _duration) {
                    _time = _duration - ((_time - _duration) + ticks);
                    _isReversed = false;
                }
            }
            else {
                if (_time > 0)
                    _time -= ticks;
                if (_time <= 0) {
                    _time = -(_time - ticks);
                    _isReversed = true;
                }
            }
            break;
        }
    }
}
