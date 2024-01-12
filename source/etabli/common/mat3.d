/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.common.mat3;

import std.math;

import etabli.common.vec2;

/// Matrice 3x3
struct Mat3(T) {
    static assert(__traits(isArithmetic, T));

    static if (__traits(isFloating, T))
        enum identity = Mat3!T([1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f]);
    else
        enum identity = Mat3!T([1, 0, 0, 0, 1, 0, 0, 0, 1]);

    T[3][3] data;
    alias data this;

    @property {
        T toAngle() const {
            return atan2(data[1][0], data[0][0]);
        }

        Vec2!T toVector() const {
            return Vec2!T(data[0][2], data[1][2]);
        }

        Vec2!T toScale() const {
            return Vec2!T(data[0][0], data[1][1]);
        }
    }

    this(Mat3!T mat) {
        static foreach (r; [0, 1, 2]) {
            static foreach (c; [0, 1, 2]) {
                data[r][c] = mat.data[r][c];
            }
        }
    }

    this(T[9] values) {
        int i;
        static foreach (r; [0, 1, 2]) {
            static foreach (c; [0, 1, 2]) {
                data[r][c] = values[i];
                i++;
            }
        }
    }

    /// Sets all values of the matrix to value (each column in each row will contain this value)
    private void clear(T value) {
        static foreach (row; [0, 1, 2]) {
            static foreach (column; [0, 1, 2]) {
                data[row][column] = value;
            }
        }
    }

    /// Mat3 multiplication with scalar
    private void scalarMultiplication(T scalar, ref Mat3 mat) const {
        for (int r = 0; r < 3; r++) {
            for (int c = 0; c < 3; c++) {
                mat.data[r][c] = data[r][c] * scalar;
            }
        }
    }

    /// Multiplication operation
    Mat3!T opBinary(string op = "*")(Mat3!T other) const {
        Mat3!T mat;

        static foreach (r; [0, 1, 2]) {
            static foreach (c; [0, 1, 2]) {
                mat.data[r][c] = 0;

                static foreach (c2; [0, 1, 2]) {
                    mat.data[r][c] += data[r][c2] * other.data[c2][c];
                }
            }
        }

        return mat;
    }

    /// Transposes the current matrix
    void transpose() {
        Mat3!T mat;

        static foreach (r; [0, 1, 2]) {
            static foreach (c; [0, 1, 2]) {
                mat.data[c][r] = data[r][c];
            }
        }

        data = mat.data;
    }

    /// Returns a transposed copy of the matrix
    Mat3!T transposed() const {
        Mat3!T mat;

        static foreach (r; [0, 1, 2]) {
            static foreach (c; [0, 1, 2]) {
                mat.data[c][r] = data[r][c];
            }
        }

        return mat;
    }

    /// Returns an identity matrix with an applied rotation around the z-axis
    static Mat3!T rotated(T alpha) {
        Mat3!T mat = Mat3!T.identity;

        const T c = cast(T) cos(alpha);
        const T s = cast(T) sin(alpha);

        mat.data[0][0] = c;
        mat.data[0][1] = -s;
        mat.data[1][0] = s;
        mat.data[1][1] = c;

        return mat;
    }

    /// Floating point T
    static if (__traits(isFloating, T)) {
        /// Rotates the current matrix around the z-axis by alpha
        Mat3!T rotate(T alpha) {
            this = Mat3!T.rotated(alpha) * this;
            return this;
        }
    }

    static {
        Mat3!T translated(Vec2!T v) {
            Mat3!T mat = Mat3!T.identity;

            mat.data[0][2] = v.x;
            mat.data[1][2] = v.y;

            return mat;
        }
    }

    /// Applys a translation on the current matrix and returns it
    Mat3!T translate(Vec2!T v) {
        this = Mat3!T.translated(v) * this;
        return this;
    }

    /// Returns a scaling matrix
    static Mat3!T scaled(Vec2!T v) {
        Mat3!T mat = Mat3!T.identity;

        mat.data[0][0] = v.x;
        mat.data[1][1] = v.y;

        return mat;
    }

    /// Ditto
    Mat3!T scale(Vec2!T v) {
        this = Mat3!T.scaled(v) * this;
        return this;
    }
}

/// Predefined matrix types
alias Mat3f = Mat3!(float);
