/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.common.stream;

import std.array;
import std.bitmanip;
import std.conv;
import std.exception : enforce;
import std.string;
import std.traits;

/// Sérialiseur
class OutStream {
    private Appender!(const ubyte[]) _buffer;

    /// Init
    this() {
        _buffer = appender!(const ubyte[])();
    }

    @property {
        /// Données internes
        const(ubyte)[] data() const {
            return _buffer.data;
        }
        /// Taille des données
        size_t length() const {
            return _buffer.data.length;
        }
    }

    /// Ajoute un string
    void write(string values) {
        write!(char[])(cast(char[]) values);
    }

    /// Ajoute un wstring
    void write(wstring values) {
        write!(wchar[])(cast(wchar[]) values);
    }

    /// Ajoute un dstring
    void write(dstring values) {
        write!(dchar[])(cast(dchar[]) values);
    }

    /// Ajoute une liste
    void write(T : T[])(T[] values) if (isScalarType!T) {
        // Taille de la liste
        ubyte[size_t.sizeof] sizeValues = nativeToBigEndian!size_t(values.length);
        foreach (ubyte b; sizeValues)
            _buffer.append!ubyte(b);
        // Liste des valeurs
        foreach (T v; values)
            foreach (ubyte b; nativeToBigEndian(v))
                _buffer.append!ubyte(b);
    }

    /// Ajoute une valeur
    void write(T)(T value) if (isScalarType!T) {
        // Taille de la valeur
        ubyte[size_t.sizeof] sizeValues = nativeToBigEndian!size_t(1u);
        foreach (ubyte b; sizeValues)
            _buffer.append!ubyte(b);
        // Liste des valeurs
        foreach (ubyte b; nativeToBigEndian(value))
            _buffer.append!ubyte(b);
    }
}

/// Désérialiseur
class InStream {
    private ubyte[] _buffer;

    @property {
        /// Données internes
        void data(ubyte[] buffer) {
            _buffer = buffer;
        }
        /// Ditto
        ref ubyte[] data() {
            return _buffer;
        }

        /// Taille des données
        size_t length(size_t len) {
            return _buffer.length = len;
        }
        /// Ditto
        size_t length() const {
            return _buffer.length;
        }
    }

    /// Prend les données
    void set(const ubyte[] buffer) {
        _buffer = buffer.dup;
    }

    /// Extrait un string
    string read(T : string)() {
        return to!string(read!(char[])());
    }

    /// Extrait un wstring
    wstring read(T : wstring)() {
        return to!wstring(read!(wchar[])());
    }

    /// Extrait un dstring
    dstring read(T : dstring)() {
        return to!dstring(read!(dchar[])());
    }

    /// Extrait une liste
    T[] read(T : T[])() if (isScalarType!T) {
        T[] values;
        const size_t size = _buffer.read!size_t();
        if (size == 0)
            return values;
        foreach (_; 0 .. size)
            values ~= _buffer.read!T();
        return values;
    }

    /// Extrait une valeur
    T read(T)() if (isScalarType!T) {
        const size_t size = _buffer.read!size_t();
        enforce(size == 1uL, "impossible de désérialiser");
        return _buffer.read!T();
    }
}

unittest {
    auto o = new OutStream;
    auto i = new InStream;

    o.write!int(179);
    o.write!(int[])([1, 2, 3, 0, 4, 5]);
    o.write!string("hello");
    o.write!bool(true);
    i.set(o.data);

    assert(i.read!int() == 179, "échec de sérialisation");
    assert(i.read!(int[])() == [1, 2, 3, 0, 4, 5], "échec de sérialisation");
    assert(i.read!string() == "hello", "échec de sérialisation");
    assert(i.read!bool() == true, "échec de sérialisation");
}
