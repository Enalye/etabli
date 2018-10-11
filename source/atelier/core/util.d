/**
    Useful functions

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.util;

public import std.math;

import atelier.core.vec2;

enum sqrt2_2 = std.math.sqrt(2.0) / 2.0;
enum pi2 = PI * 2f;

T lerp(T)(T a, T b, float t) {
	return t * b + (1f - t) * a;
}

float rlerp(float a, float b, float v) {
	return (v - a) / (b - a);
}

float angleBetween(float a, float b) {
	float delta = (b - a) % 360f;
	return ((2f * delta) % 360f) - delta;
}

float angleLerp(float a, float b, float t) {
	return a + angleBetween(a, b) * t;
}

Vec2f scaleToFit(Vec2f src, Vec2f dst) {
	float scale;
	if(dst.x / dst.y > src.x / src.y)
		scale = dst.y / src.y;
	else
		scale = dst.x / src.x;
	return src * scale;
}