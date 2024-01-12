module etabli.common.json;

import std.conv : to;
import std.exception : enforce;
import std.file;
import std.json;
import std.path;
import std.utf : validate;

/// Représente un nœud json
final class Json {
    private {
        JSONValue _json;
    }

    /// Ctor
    this() {
    }

    /// Charge depuis un fichier
    this(string path) {
        load(path);
    }

    /// Charge depuis des données bruts
    this(const(ubyte[]) data) {
        load(data);
    }

    private this(JSONValue node) {
        _json = node;
    }

    /// Charge depuis un fichier
    void load(string path) {
        _json = parseJSON(readText(path));
    }

    /// Charge depuis des données bruts
    void load(const(ubyte[]) data) {
        string text = cast(string) data;
        validate(text);
        _json = parseJSON(text);
    }

    /// Enregistre vers un fichier
    void save(string path, bool readable = true) {
        std.file.write(path, toJSON(_json, readable));
    }

    /// Vérifie l’existence d’une clé
    bool has(string key) {
        return ((key in _json.object) !is null);
    }

    /// S’assure de l’existence d’une clé
    private void _assert(string key) {
        enforce(key in _json.object, "la clé `" ~ key ~ "` n’est pas définie");
    }

    /// Récupère le nœud associé à la clé
    Json getObject(string key) {
        _assert(key);
        return new Json(_json.object[key]);
    }

    /// Récupère le texte associé à la clé
    string getString(string key) {
        _assert(key);
        return _json.object[key].str;
    }

    /// Ditto
    string getString(string key, string defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return _json.object[key].str;
    }

    /// Récupère l’entier associé à la clé
    int getInt(string key) {
        _assert(key);

        JSONValue value = _json.object[key];
        switch (value.type()) with (JSONType) {
        case integer:
            return cast(int) value.integer;
        case uinteger:
            return cast(int) value.uinteger;
        case float_:
            return cast(int) value.floating;
        case string:
            return to!int(value.str);
        default:
            throw new Exception("la clé `" ~ key ~ "` n’est pas convertissable en int");
        }
    }

    /// Ditto
    int getInt(string key, int defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getInt(key);
    }

    /// Récupère le flottant associé à la clé
    float getFloat(string key) {
        _assert(key);

        JSONValue value = _json.object[key];
        switch (value.type()) with (JSONType) {
        case integer:
            return cast(float) value.integer;
        case uinteger:
            return cast(float) value.uinteger;
        case float_:
            return value.floating;
        case string:
            try
                return to!float(value.str);
            catch (Exception e) {
                throw new Exception("la clé `" ~ key ~ "` n’est pas convertissable en float");
            }
        default:
            throw new Exception("la clé `" ~ key ~ "` n’est pas convertissable en float");
        }
    }

    /// Ditto
    float getFloat(string key, float defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getFloat(key);
    }

    /// Récupère le booléen associé à la clé
    bool getBool(string key) {
        _assert(key);

        JSONValue value = _json.object[key];
        if (value.type() == JSONType.true_) {
            return true;
        } else if (value.type() == JSONType.false_) {
            return false;
        } else {
            throw new Exception("la clé `" ~ key ~ "` n’est pas un booléen");
        }
    }

    /// Ditto
    bool getBool(string key, bool defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getBool(key);
    }

    /// Récupère les nœuds associés à la clé
    Json[] getObjects(string key) {
        _assert(key);

        Json[] array;
        foreach (ref JSONValue node; _json.object[key].array) {
            array ~= new Json(node);
        }
        return array;
    }

    /// Ditto
    Json[] getObjects(string key, Json[] defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getObjects(key);
    }

    /// Récupères les textes associés à la clé
    string[] getStrings(string key) {
        _assert(key);

        string[] array;
        foreach (JSONValue value; _json.object[key].array) {
            array ~= value.str;
        }

        return array;
    }

    /// Ditto
    string[] getStrings(string key, string[] defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getStrings(key);
    }

    /// Récupère les entiers associés à la clé
    int[] getInts(string key) {
        _assert(key);

        int[] array;
        foreach (JSONValue value; _json.object[key].array) {
            if (value.type() == JSONType.integer) {
                array ~= cast(int) value.integer;
            } else {
                array ~= to!int(value.str);
            }
        }

        return array;
    }

    /// Ditto
    int[] getInts(string key, int[] defaultValue = []) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getInts(key);
    }

    /// Récupère les flottants associés à la clé
    float[] getFloats(string key) {
        _assert(key);

        float[] array;
        foreach (JSONValue value; _json.object[key].array) {
            switch (value.type()) {
            case JSONType.string:
                array ~= to!float(value.str);
                break;
            case JSONType.integer:
                array ~= to!float(value.integer);
                break;
            case JSONType.float_:
                array ~= value.floating;
                break;
            default:
                break;
            }
        }

        return array;
    }

    /// Ditto
    float[] getFloats(string key, float[] defaultValue = []) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getFloats(key);
    }

    /// Récupère les booléens associés à la clé
    bool[] getBools(string key) {
        _assert(key);

        bool[] array;
        foreach (size_t i, JSONValue value; _json.object[key].array) {
            if (value.type() == JSONType.true_) {
                array ~= true;
            } else if (value.type() == JSONType.false_) {
                array ~= false;
            } else {
                enforce(false, "l’élément à l’index " ~ to!string(
                        i) ~ " clé `" ~ key ~ "` n’est pas un booléen");
            }
        }

        return array;
    }

    /// Ditto
    bool[] getBools(string key, bool[] defaultValue) {
        if (!(key in _json.object)) {
            return defaultValue;
        }

        return getBools(key);
    }

    /// Récupère les enfants d’un objet sous forme de tableau associatif
    Json[string] getElements() {
        Json[string] result;
        foreach (string key, ref JSONValue value; _json.object) {
            result[key] = new Json(value);
        }

        return result;
    }

    /// Assigne une valeur à la clé
    void set(T)(string key, T value) {
        static if (is(T == Json)) {
            _json[key] = JSONValue(value._json);
        } else static if (is(T == Json[])) {
            JSONValue[] array;
            foreach (element; value) {
                array ~= element._json;
            }
            _json[key] = JSONValue(array);
        } else {
            _json[key] = JSONValue(value);
        }
    }
}
