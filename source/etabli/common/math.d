/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.common.math;

import std.math;
import std.traits;
public import std.algorithm.comparison : clamp, min, max;

/// Interpolation, returns a value between a and b. \
/// If t = 0, returns a. \
/// If t = 1, returns b.
T lerp(T)(T a, T b, float t) {
    return t * b + (1f - t) * a;
}

/// Reverse lerp, returns a value between 0 and 1. \
/// 0 if v = a. \
/// 1 if v = b.
double rlerp(double a, double b, double v) {
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
Vec2!T scaleToFit(T)(Vec2!T src, Vec2!T dst) {
    float scale;
    if (dst.x / dst.y > src.x / src.y) {
        scale = dst.y / src.y;
    }
    else {
        scale = dst.x / src.x;
    }

    return src * scale;
}

/// Linear interpolation to approach a target
T approach(T)(T value, T target, T step) if (isScalarType!T) {
    return value > target ? max(value - step, target) : min(value + step, target);
}

private enum DegToRadFactor = PI / 180.0;
private enum RadToDegFactor = 180.0 / PI;

/// Converti un angle en degrées en radians
T degToRad(T)(T deg) {
    return deg * DegToRadFactor;
}

/// Converti un angle en radians en degrées
T radToDeg(T)(T rad) {
    return rad * RadToDegFactor;
}

/// Converti un gain en décibels en amplitude
T dbToVol(T)(T db) {
    return pow(10.0, 0.05 * db);
}

/// Converti un gain en amplitude en décibels
T volToDb(T)(T vol) {
    return 20.0 * log10(vol);
}
