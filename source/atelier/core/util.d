/**
    Useful functions

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.util;

public import std.math;
public import std.algorithm.comparison : clamp, min, max;

import atelier.core.vec2;

/// The square root of 2, then divided by 2.
enum sqrt2_2 = std.math.sqrt(2.0) / 2.0;
/// 2 times PI.
enum pi2 = PI * 2f;

/// Interpolation, returns a value between a and b. \
/// If t = 0, returns a. \
/// If t = 1, returns b.
T lerp(T)(T a, T b, float t) {
    return t * b + (1f - t) * a;
}

/// Reverse lerp, returns a value between 0 and 1. \
/// 0 if v = a. \
/// 1 if v = b.
float rlerp(float a, float b, float v) {
    return (v - a) / (b - a);
}

/// The minimal angle (in degrees) between 2 other angles.
float angleBetween(float a, float b) {
    const float delta = (b - a) % 360f;
    return ((2f * delta) % 360f) - delta;
}

/// Interpolation between an angle a and b. \
/// If t = 0, returns a. \
/// If t = 1, returns b.
float angleLerp(float a, float b, float t) {
    return a + angleBetween(a, b) * t;
}

/// Scale a vector to fit the specified vector while keeping its ratio.
Vec2f scaleToFit(Vec2f src, Vec2f dst) {
    float scale;
    if (dst.x / dst.y > src.x / src.y)
        scale = dst.y / src.y;
    else
        scale = dst.x / src.x;
    return src * scale;
}

/// Linear interpolation to approach a target
float approach(float value, float target, float step) {
    return value > target ? max(value - step, target) : min(value + step, target);
}
