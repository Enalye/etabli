module etabli.common.resource;

import std.typecons;
import std.algorithm : count;
import std.conv : to;
import std.exception : enforce;
import std.traits : isCopyable;

import etabli.common.json;
import etabli.common.stream;

/// Type gérée par le système de ressource
interface Resource(T) {
    /// Donne accès à la ressource à partir du prototype
    T fetch();
}

/// Gestionnaire des ressources
final class ResourceManager {
    /// Logique de chargement d’une ressource d’un type donné
    static struct Loader {
        alias CompilerFunc = void function(string, Json, OutStream);
        alias LoaderFunc = void function(InStream);
        /// Fonction de sérialisation
        CompilerFunc compile;
        /// Fonction de désérialisation
        LoaderFunc load;
    }

    private alias FileData = const(ubyte)[];

    private {
        FileData[string] _files;
        Loader[string] _loaders;
        void*[string] _caches;
    }

    /// Données d’une ressource
    static struct ResourceData(T) if (is(T == class) && is(T : Resource!T)) {
        /// Le prototype de la ressource mise en cache
        T prototype;
        /// Construit le prototype de la ressource
        T delegate() builder;
    }

    /// Cache pour les ressources d’un type donné
    static private final class Cache(T) if (is(T == class) && is(T : Resource!T)) {
        private {
            ResourceData!(T)[string] _data;
        }

        /// Ajoute le chargeur d’une ressource
        void setBuilder(string name, T delegate() builder) {
            ResourceData!T data;
            data.builder = builder;
            _data[name] = data;
        }

        /// Récupère le prototype d’une ressource
        T getPrototype(string name) {
            auto p = (name in _data);
            enforce(p, "la ressource `" ~ name ~ "` n’existe pas");
            if (!p.prototype) {
                p.prototype = p.builder();
            }
            return p.prototype;
        }

        /// Récupère le prototype d’une ressource
        T get(string name) {
            auto p = getPrototype(name);
            return p.fetch();
        }
    }

    /// Init
    this() {

    }

    /// Charge un fichier
    void write(string path, FileData data) {
        _files[path] = data;
    }

    /// Retourne les données d’un fichier chargé
    FileData read(string path) const {
        auto p = path in _files;
        enforce(p, "le fichier `" ~ path ~ "` n’existe pas");
        return *p;
    }

    /// Ditto
    string readText(string path) const {
        import std.utf : validate;

        string text = cast(string) read(path);
        validate(text);
        return text;
    }

    /// Ajoute un type de ressource
    void setLoader(string type, Loader.CompilerFunc compilerFunc, Loader.LoaderFunc loaderFunc) {
        Loader loader;
        loader.compile = compilerFunc;
        loader.load = loaderFunc;
        _loaders[type] = loader;
    }

    Loader getLoader(string type) const {
        auto p = type in _loaders;
        enforce(p, "aucune fonction de définie pour le type `" ~ type ~ "`");
        return *p;
    }

    /// Definit une nouvelle ressource
    void store(T)(string name, T delegate() builder)
            if (is(T == class) && is(T : Resource!T)) {
        static assert(!__traits(isAbstractClass, T), "`" ~ T.stringof ~ "` est une classe abstraite");

        auto p = T.stringof in _caches;
        Cache!T cache;

        if (p) {
            cache = cast(Cache!T)*p;
        } else {
            cache = new Cache!T;
            _caches[T.stringof] = cast(void*) cache;
        }

        cache.setBuilder(name, builder);
    }

    /// Retourne le prototype d’une ressource
    T getPrototype(T)(string name) if (is(T == class) && is(T : Resource!T)) {
        static assert(!__traits(isAbstractClass, T), "`" ~ T.stringof ~ "` est une classe abstraite");

        auto p = T.stringof in _caches;
        enforce(p, "la ressource `" ~ name ~ "` n’existe pas");
        return cast(T)(cast(Cache!T)*p).getPrototype(name);
    }

    /// Retourne une ressource
    T get(T)(string name) if (is(T == class) && is(T : Resource!T)) {
        static assert(!__traits(isAbstractClass, T), "`" ~ T.stringof ~ "` est une classe abstraite");

        auto p = T.stringof in _caches;
        enforce(p, "la ressource `" ~ name ~ "` n’existe pas");
        return cast(T)(cast(Cache!T)*p).get(name);
    }
}
