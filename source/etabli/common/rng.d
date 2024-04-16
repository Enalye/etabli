/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.common.rng;

import std.math;
import std.mathspecial;
import std.random;

final class RNG {
    private {
        ulong _state = 0x853c49e6748fea9bUL;
        ulong _inc = 0xda3e39cb94b95bdbUL;
        double spared;
        bool hasSpared = false;
        float sparef;
        bool hasSparef = false;
    }

    this() {
    }

    this(ulong initState, ulong initSeq) {
        _state = 0u;
        _inc = (initSeq << 1u) | 1u;
    }

    private uint _rand() {
        ulong oldState = _state;
        _state = oldState * 6_364_136_223_846_793_005UL + (_inc | 1u);
        uint xorShifted = cast(uint)(((oldState >> 18u) ^ oldState) >> 27u);
        uint rot = oldState >> 59u;
        return (xorShifted >> rot) | (xorShifted << ((-rot) & 31));
    }

    T rand01(T = double)() {
        return ldexp(cast(T) _rand(), -32);
    }

    T rand(T)(T maxValue) {
        static if (__traits(isFloating, T)) {
            return rand01!T() * maxValue;
        }
        else static if (is(T == uint)) {
            return _rand() % maxValue;
        }
        else static if (is(T == int)) {
            if (maxValue == 0) {
                return maxValue;
            }
            else if (maxValue > 0) {
                return (cast(int) _rand()) % maxValue;
            }
            return -((cast(int) _rand()) % -maxValue);
        }
        assert(false);
    }

    T rand(T)(T minValue, T maxValue) {
        static if (__traits(isFloating, T)) {
            T delta = maxValue - minValue;
            return minValue + rand01!T() * delta;
        }
        else static if (is(T == uint)) {
            long delta = (maxValue - minValue);
            if (delta == 0) {
                return minValue;
            }
            else if (delta < 0) {
                return cast(T)(_rand() % -delta) + maxValue;
            }
            return cast(T)(_rand() % delta) + minValue;
        }
        else static if (is(T == int)) {
            long delta = (maxValue - minValue);
            if (delta == 0) {
                return minValue;
            }
            else if (delta < 0) {
                return cast(T)(_rand() % -delta) + maxValue;
            }
            return cast(T)(_rand() % delta) + minValue;
        }
    }

    T randn(T = double)() {
        return generateGaussian(cast(T) 0.5, cast(T) 0.1);
    }

    T generateGaussian(T)(T mean, T deviation) {
        if (hasSpared) {
            hasSpared = false;
            return spared * deviation + mean;
        }
        T u, v, s;
        do {
            u = rand01!T() * cast(T) 2.0 - cast(T) 1.0;
            v = rand01!T() * cast(T) 2.0 - cast(T) 1.0;
            s = u * u + v * v;
        }
        while (s >= cast(T) 1.0 || s == cast(T) 0.0);
        s = sqrt(cast(T)-2.0 * log(s) / s);
        spared = v * s;
        hasSpared = true;
        return mean + deviation * u * s;
    }
}
