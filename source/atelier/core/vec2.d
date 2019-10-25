/**
    Vec2

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.vec2;

import std.math;

import atelier.core.vec3;
import atelier.core.vec4;

enum double degToRad = std.math.PI / 180.0;
enum double radToDeg = 180.0 / std.math.PI;

/// Represent a mathematical 2-dimensional vector.
struct Vec2(T) {
	static assert(__traits(isArithmetic, T));

	static if(__traits(isUnsigned, T)) {
		/// {1, 1} vector. Its length is not one !
		enum one = Vec2!T(1u, 1u);
		/// Null vector.
		enum zero = Vec2!T(0u, 0u);
	}
	else {
		static if(__traits(isFloating, T)) {
			/// {1, 1} vector. Its length is not one !
			enum one = Vec2!T(1f, 1f);
			/// {0.5, 0.5} vector. Its length is not 0.5 !
			enum half = Vec2!T(.5f, .5f);
				/// Null vector.
			enum zero = Vec2!T(0f, 0f);
		}
		else {
			/// {1, 1} vector. Its length is not one !
			enum one = Vec2!T(1, 1);
				/// Null vector.
			enum zero = Vec2!T(0, 0);
		}
	}

	/// x-axis coordinate.
	T x,
	/// y-axis coordinate.
		y;

	/// Changes {x, y}
	void set(T nx, T ny) {
		x = nx;
		y = ny;
	}

	/// The distance between this point and the other one.
	T distance(Vec2!T v) const {
		static if(__traits(isUnsigned, T))
			alias V = int;
		else
			alias V = T;

		V px = x - v.x,
			py = y - v.y;

		static if(__traits(isFloating, T))
			return std.math.sqrt(px * px + py * py);
		else
			return cast(T)std.math.sqrt(cast(float)(px * px + py * py));
	}

	/// The distance between this point and the other one squared.
	/// Not square rooted, so no crash and more efficient.
	T distanceSquared(Vec2!T v) const {
		static if(__traits(isUnsigned, T))
			alias V = int;
		else
			alias V = T;

		V px = x - v.x,
			py = y - v.y;

		return px * px + py * py;
	}

	/// Dot product of the 2 vectors.
	T dot(const Vec2!T v) const {
		return x * v.x + y * v.y;
	}

	/// Cross product of the 2 vectors.
	T cross(const Vec2!T v) const {
		static if(__traits(isUnsigned, T))
			return cast(int)(x * v.y) - cast(int)(y * v.x);
		else
			return (x * v.y) - (y * v.x);
	}

	/// The normal axis of this vector.
	Vec2!T normal() const {
		return Vec2!T(-y, x);
	}

	/// Reflect this vector inside another one that represents the area change.
	Vec2!T reflect(const Vec2!T v) const {
		static if(__traits(isFloating, T)) {
			const T dotNI2 = 2.0 * x * v.x + y * v.y;
			return Vec2!T(cast(T)(x - dotNI2 * v.x), cast(T)(y - dotNI2 * v.y));
		}
		else {
			const T dotNI2 = 2 * x * v.x + y * v.y;
			static if(__traits(isUnsigned, T))
				return Vec2!T(cast(int)(x) - cast(int)(dotNI2 * v.x), cast(int)(y) - cast(int)(dotNI2 * v.y));
			else
				return Vec2!T(x - dotNI2 * v.x, y - dotNI2 * v.y);
		}
	}

	/// Refracts this vector onto another one that represents the area change.
	Vec2!T refract(const Vec2!T v, float eta) const {
		static if(__traits(isFloating, T)) {
			const T dotNI = (x * v.x + y * v.y);
			T k = 1.0 - eta * eta * (1.0 - dotNI * dotNI);
			if (k < .0)
				return Vec2!T(T.init, T.init);
			else {
				const double s = (eta * dotNI + sqrt(k));
				return Vec2!T(eta * x - s * v.x, eta * y - s * v.y);
			}
		}
		else {
			const float dotNI = cast(float)(x * v.x + y * v.y);
			float k = 1.0f - eta * eta * (1.0f - dotNI * dotNI);
			if (k < 0f)
				return Vec2!T(T.init, T.init);
			else {
				const float s = (eta * dotNI + sqrt(k));
				return Vec2!T(cast(T)(eta * x - s * v.x), cast(T)(eta * y - s * v.y));
			}
		}
	}

	/// The smaller vector possible between the two.
    Vec2!T min(const Vec2!T v) const {
        return Vec2!T(x < v.x ? x : v.x, y < v.y ? y : v.y);
    }

	/// The larger vector possible between the two.
    Vec2!T max(const Vec2!T v) const {
        return Vec2!T(x > v.x ? x : v.x, y > v.y ? y : v.y);
    }

	/// Remove negative components.
	Vec2!T abs() const {
		static if(__traits(isFloating, T))
			return Vec2!T(x < .0 ? -x : x, y < .0 ? -y : y);
		else static if(__traits(isUnsigned, T))
			return Vec2!T(x < 0U ? -x : x, y < 0U ? -y : y);
		else
			return Vec2!T(x < 0 ? -x : x, y < 0 ? -y : y);
	}

	/// Truncate the values.
	Vec2!T floor() const {
		static if(__traits(isFloating, T))
			return Vec2!T(std.math.floor(x), std.math.floor(y));
		else
			return this;
	}

	/// Round up the values.
	Vec2!T ceil() const {
		static if(__traits(isFloating, T))
			return Vec2!T(std.math.ceil(x), std.math.ceil(y));
		else
			return this;
	}

	/// Round the values to the nearest integer.
	Vec2!T round() const {
		static if(__traits(isFloating, T))
			return Vec2!T(std.math.round(x), std.math.round(y));
		else
			return this;
	}

	static if(__traits(isFloating, T)) {
		/// Returns the vector actual angle.
		T angle() const {
			return std.math.atan2(y, x) * radToDeg;
		}
	
		/// Add an angle to this vector.
		Vec2!T rotate(T angle) {
			const T radians = angle * degToRad;
			const T px = x, py = y;
			const T c = std.math.cos(radians);
			const T s = std.math.sin(radians);
			x = px * c - py * s;
			y = px * s + py * c;
			return this;
		}

		/// Returns a vector with an added angle without modifying this one.
		Vec2!T rotated(T angle) const {
			const T radians = angle * degToRad;
			const T c = std.math.cos(radians);
			const T s = std.math.sin(radians);
			return Vec2f(x * c - y * s, x * s + y * c);
		}

		/// Returns a unit vector with an angle.
		static Vec2!T angled(T angle) {
			const T radians = angle * degToRad;
			return Vec2f(std.math.cos(radians), std.math.sin(radians));
		}
	}

	/// Adds x and y.
	T sum() const {
		return x + y;
	}

	/// The total length of this vector.
	/// Must be non-null.
	T length() const {
		assert(this != Vec2!T.zero, "Null vector");
		static if(__traits(isFloating, T))
			return std.math.sqrt(x * x + y * y);
		else
			return cast(T)std.math.sqrt(cast(float)(x * x + y * y));
	}

	/// The squared length of this vector.
	/// Can be null, and more efficiant than length.
	T lengthSquared() const  {
		return x * x + y * y;
	}

	/// Transform this vector in a unit vector.
	void normalize() {
		assert(this != Vec2!T.zero, "Null vector");
		static if(__traits(isFloating, T))
			const T len = std.math.sqrt(x * x + y * y);
		else
			const T len = cast(T)std.math.sqrt(cast(float)(x * x + y * y));

		x /= len;
		y /= len;
	}

	/// Returns a unit vector from this one without modifying this one.
	Vec2!T normalized() const  {
		assert(this != Vec2!T.zero, "Null vector");
		static if(__traits(isFloating, T))
			const T len = std.math.sqrt(x * x + y * y);
		else
			const T len = cast(T)std.math.sqrt(cast(float)(x * x + y * y));

		return Vec2!T(x / len, y / len);
	}

	/// Bounds the vector between those two.
	Vec2!T clamp(const Vec2!T min, const Vec2!T max) const {
		Vec2!T v = {x, y};
		if (v.x < min.x) v.x = min.x;
		else if(v.x > max.x) v.x = max.x;
		if (v.y < min.y) v.y = min.y;
		else if (v.y > max.y) v.y = max.y;
		return v;
	}

	/// Bounds the vector between those boundaries.
	Vec2!T clamp(const Vec4!T clip) const {
		Vec2!T v = {x, y};
		if (v.x < clip.x) v.x = clip.x;
		else if(v.x > clip.z) v.x = clip.z;
		if (v.y < clip.y) v.y = clip.y;
		else if (v.y > clip.w) v.y = clip.w;
		return v;
	}

	/// Is this vector between those boundaries ?
	bool isBetween(const Vec2!T min, const Vec2!T max) const {
		if (x < min.x) return false;
		else if (x > max.x) return false;
		if (y < min.y) return false;
		else if (y > max.y) return false;
		return true;
	}

	static if(__traits(isFloating, T)) {
		/// Returns an interpolated vector from this vector to the end vector by a factor. \
		/// Does not modify this vector.
		Vec2!T lerp(Vec2!T end, float t) const {
			return (this * (1.0 - t)) + (end * t);
		}
	}

	/// While conserving the x/y ratio, returns the largest vector possible that fits inside the other vector. (like a size) \
	/// Does not modify this vector. \
	/// Must be non-null.
	Vec2!T fit(const Vec2!T v) const {
		assert(v != Vec2!T.zero, "Null vector");
		return (x / y) < (v.x / v.y) ?
			Vec2!T(x * v.y / y, v.y):
			Vec2!T(v.x, y * v.x / x);
	}

	/// Equality operations
	bool opEquals(const Vec2!T v) const @safe pure nothrow {
		return (x == v.x) && (y == v.y);
	}

	/// Unary operations
	Vec2!T opUnary(string op)() const @safe pure nothrow {
		return mixin("Vec2!T(" ~ op ~ " x, " ~ op ~ " y)");
	}

	/// Binary operations
	Vec2!T opBinary(string op)(const Vec2!T v) const @safe pure nothrow {
		return mixin("Vec2!T(x " ~ op ~ " v.x, y " ~ op ~ " v.y)");
	}

	/// Binary operations
	Vec2!T opBinary(string op)(T s) const @safe pure nothrow {
		return mixin("Vec2!T(x " ~ op ~ " s, y " ~ op ~ " s)");
	}

	/// Binary operations
	Vec2!T opBinaryRight(string op)(T s) const @safe pure nothrow {
		return mixin("Vec2!T(s " ~ op ~ " x, s " ~ op ~ " y)");
	}

	/// Assignment
	Vec2!T opOpAssign(string op)(Vec2!T v) @safe pure nothrow {
		mixin("x = x" ~ op ~ "v.x;y = y" ~ op ~ "v.y;");
		return this;
	}

	/// Assignment
	Vec2!T opOpAssign(string op)(T s) @safe pure nothrow {
		mixin("x = x" ~ op ~ "s;y = y" ~ op ~ "s;");
		return this;
	}

	/// Conversion
	Vec2!U opCast(V: Vec2!U, U)() const @safe pure nothrow {
		return V(cast(U)x, cast(U)y);
	}

	/// Hash value.
	size_t toHash() const @safe pure nothrow {
		import std.typecons: tuple;
		return tuple(x, y).toHash();
	}
}

alias Vec2f = Vec2!(float);
alias Vec2i = Vec2!(int);
alias Vec2u = Vec2!(uint);