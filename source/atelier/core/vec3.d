/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.core.vec3;

import std.math;
import atelier.core.vec2;

/// Represent a mathematical 3-dimensional vector.
struct Vec3(T) {
    static assert(__traits(isArithmetic, T));

	static if(__traits(isUnsigned, T)) {
		/// {1, 1, 1} vector. Its length is not one !
		enum one = Vec3!T(1u, 1u, 1u);
		/// Null vector.
		enum zero = Vec3!T(0u, 0u, 0u);
	}
    else {
		static if(__traits(isFloating, T)) {
			/// {1, 1} vector. Its length is not one !
			enum one = Vec3!T(1f, 1f, 1f);
			/// {0.5, 0.5} vector. Its length is not 0.5 !
			enum half = Vec3!T(.5f, .5f, .5f);
            /// Null vector.
			enum zero = Vec3!T(0f, 0f, 0f);
            /// {-1, 0, 0} vector.
            enum left = Vec3!T(-1f, 0, 0);
            /// {1, 0, 0} vector.
            enum right = Vec3!T(1f, 0, 0);
            /// {0, -1, 0} vector.
            enum down = Vec3!T(0, -1f, 0);
            /// {0, 1, 0} vector.
            enum up = Vec3!T(0, 1f, 0);
            /// {0, 0, -1} vector.
            enum bottom = Vec3!T(0, 0, -1f);
			/// {0, 0, 1} vector.
            enum top = Vec3!T(0, 0, 1f);
		}
		else {
			/// {1, 1, 1} vector. Its length is not one !
			enum one = Vec3!T(1, 1, 1);
            /// Null vector.
			enum zero = Vec3!T(0, 0, 0);
            /// {-1, 0, 0} vector.
            enum left = Vec3!T(-1, 0, 0);
            /// {1, 0, 0} vector.
            enum right = Vec3!T(1, 0, 0);
            /// {0, -1, 0} vector.
            enum down = Vec3!T(0, -1, 0);
            /// {0, 1, 0} vector.
            enum up = Vec3!T(0, 1, 0);
            /// {0, 0, -1} vector.
            enum bottom = Vec3!T(0, 0, -1);
			/// {0, 0, 1} vector.
            enum top = Vec3!T(0, 0, 1);
		}
	}

    /// x-axis coordinate.
	T x;
	/// y-axis coordinate.
	T y;
    /// z-axis coordinate.
	T z;

    @property {
        /// Return a 2-dimensional vector with {x, y}
		Vec2!T xy() const { return Vec2!T(x, y); }
        /// Ditto
		Vec2!T xy(Vec2!T v) {
			x = v.x;
			y = v.y;
			return v;
		}

        /// Return a 2-dimensional vector with {y, z}
		Vec2!T yz() const { return Vec2!T(y, z); }
        /// Ditto
		Vec2!T yz(Vec2!T v) {
			y = v.x;
			z = v.y;
			return v;
		}

        /// Return a 2-dimensional vector with {x, z}
        Vec2!T xz() const { return Vec2!T(x, z); }
        /// Ditto
		Vec2!T xz(Vec2!T v) {
			x = v.x;
			z = v.y;
			return v;
		}
	}

    /// Build a new 3-dimensional vector.
    this(T x_, T y_, T z_) {
		x = x_;
		y = y_;
		z = z_;
	}

    /// Ditto
	this(Vec2!T xy_, T z_) {
		x = xy_.x;
		y = xy_.y;
		z = z_;
	}

    /// Ditto
    this(T x_, Vec2!T yz_) {
		x = x_;
		y = yz_.x;
		z = yz_.y;
	}

	/// Changes {x, y, z}
	void set(T x_, T y_, T z_) {
		x = x_;
		y = y_;
		z = z_;
	}

    /// Ditto
	void set(Vec2!T xy_, T z_) {
		x = xy_.x;
		y = xy_.y;
		z = z_;
	}

    /// Ditto
    void set(T x_, Vec2!T yz_) {
		x = x_;
		y = yz_.x;
		z = yz_.y;
	}

    /// The distance between this point and the other one.
	T distance(Vec3!T v) const {
		static if(__traits(isUnsigned, T))
			alias V = int;
		else
			alias V = T;

		V px = x - v.x,
			py = y - v.y,
			pz = z - v.z;

		static if(__traits(isFloating, T))
			return std.math.sqrt(px * px + py * py + pz * pz);
		else
			return cast(T) std.math.sqrt(cast(float) (px * px + py * py + pz * pz));
	}

	/// The distance between this point and the other one squared.
	/// Not square rooted, so no crash and more efficient.
	T distanceSquared(Vec3!T v) const {
		static if(__traits(isUnsigned, T))
			alias V = int;
		else
			alias V = T;

		V px = x - v.x,
			py = y - v.y,
			pz = z - v.z;

		return px * px + py * py + pz * pz;
	}

    /// The smaller vector possible between the two.
    Vec3!T min(const Vec3!T v) const {
        return Vec3!T(x < v.x ? x : v.x, y < v.y ? y : v.y, z < v.z ? z : v.z);
    }

	/// The larger vector possible between the two.
    Vec3!T max(const Vec3!T v) const {
        return Vec3!T(x > v.x ? x : v.x, y > v.y ? y : v.y, z > v.z ? z : v.z);
    }

	/// Remove negative components.
	Vec3!T abs() const {
		static if(__traits(isFloating, T))
			return Vec3!T(x < .0 ? -x : x, y < .0 ? -y : y, z < .0 ? -z : z);
		else static if(__traits(isUnsigned, T))
			return Vec3!T(x < 0U ? -x : x, y < 0U ? -y : y, z < 0U ? -z : z);
		else
			return Vec3!T(x < 0 ? -x : x, y < 0 ? -y : y, z < 0 ? -z : z);
	}

	/// Truncate the values.
	Vec3!T floor() const {
		static if(__traits(isFloating, T))
			return Vec3!T(std.math.floor(x), std.math.floor(y), std.math.floor(z));
		else
			return this;
	}

	/// Round up the values.
	Vec3!T ceil() const {
		static if(__traits(isFloating, T))
			return Vec3!T(std.math.ceil(x), std.math.ceil(y), std.math.ceil(z));
		else
			return this;
	}

	/// Round the values to the nearest integer.
	Vec3!T round() const {
		static if(__traits(isFloating, T))
			return Vec3!T(std.math.round(x), std.math.round(y),std.math.round(z));
		else
			return this;
	}

    /// Adds x, y and z.
	T sum() const {
		return x + y + z;
	}

	/// The total length of this vector.
	T length() const {
		static if(__traits(isFloating, T))
			return std.math.sqrt(x * x + y * y + z * z);
		else
			return cast(T) std.math.sqrt(cast(float) (x * x + y * y + z * z));
	}

	/// The squared length of this vector.
	/// Can be null, and more efficiant than length.
	T lengthSquared() const  {
		return x * x + y * y + z * z;
	}

	/// Transform this vector in a unit vector.
	void normalize() {
		if(this == Vec3!T.zero)
			return;
		static if(__traits(isFloating, T))
			const T len = std.math.sqrt(x * x + y * y + z * z);
		else
			const T len = cast(T) std.math.sqrt(cast(float) (x * x + y * y + z * z));

		x /= len;
		y /= len;
		z /= len;
	}

	/// Returns a unit vector from this one without modifying this one.
	Vec3!T normalized() const  {
		if(this == Vec3!T.zero)
			return this;
		static if(__traits(isFloating, T))
			const T len = std.math.sqrt(x * x + y * y + z * z);
		else
			const T len = cast(T) std.math.sqrt(cast(float) (x * x + y * y + z * z));

		return Vec3!T(x / len, y / len, z / len);
	}

	/// Bounds the vector between those two.
	Vec3!T clamp(const Vec3!T min, const Vec3!T max) const {
		Vec3!T v = this;
		if (v.x < min.x) v.x = min.x;
		else if(v.x > max.x) v.x = max.x;
		if (v.y < min.y) v.y = min.y;
		else if (v.y > max.y) v.y = max.y;
        if (v.z < min.z) v.z = min.z;
		else if (v.z > max.z) v.z = max.z;
		return v;
	}

	/// Is this vector between those boundaries ?
	bool isBetween(const Vec3!T min, const Vec3!T max) const {
		if (x < min.x) return false;
		else if (x > max.x) return false;
		if (y < min.y) return false;
		else if (y > max.y) return false;
        if (z < min.z) return false;
		else if (z > max.z) return false;
		return true;
	}

	static if(__traits(isFloating, T)) {
		/// Returns an interpolated vector from this vector to the end vector by a factor. \
		/// Does not modify this vector.
		Vec3!T lerp(Vec3!T end, float t) const {
			return (this * (1.0 - t)) + (end * t);
		}
	}

    /// Operators.
    bool opEquals(const Vec3!T v) const {
		return (x == v.x) && (y == v.y) && (z == v.z);
	}

    /// Ditto
    Vec3!T opUnary(string op)() const {
		return mixin("Vec3!T(" ~ op ~ " x, " ~ op ~ " y, " ~ op ~ " z)");
	}

    /// Ditto
	Vec3!T opBinary(string op)(const Vec3!T v) const {
		return mixin("Vec3!T(x " ~ op ~ " v.x, y " ~ op ~ " v.y, z " ~ op ~ " v.z)");
	}

    /// Ditto
	Vec3!T opBinary(string op)(T s) const {
		return mixin("Vec3!T(x " ~ op ~ " s, y " ~ op ~ " s, z " ~ op ~ " s)");
	}

    /// Ditto
	Vec3!T opBinaryRight(string op)(T s) const {
		return mixin("Vec3!T(s " ~ op ~ " x, s " ~ op ~ " y, s " ~ op ~ " z)");
	}

    /// Ditto
	Vec3!T opOpAssign(string op)(Vec3!T v) {
		mixin("x = x" ~ op ~ "v.x;y = y" ~ op ~ "v.y;z = z" ~ op ~ "v.z;");
		return this;
	}

    /// Ditto
	Vec3!T opOpAssign(string op)(T s) {
		mixin("x = x" ~ op ~ "s;y = y" ~ op ~ "s;z = z" ~ op ~ "s;");
		return this;
	}

    /// Ditto
	Vec3!U opCast(V: Vec3!U, U)() const {
		return V(cast(U) x, cast(U) y, cast(U) z);
	}
}

alias Vec3f = Vec3!(float);
alias Vec3i = Vec3!(int);
alias Vec3u = Vec3!(uint);