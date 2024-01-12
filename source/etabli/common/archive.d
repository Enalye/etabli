module etabli.common.archive;

import std.file;
import std.path;
import std.stdio;
import std.exception : enforce;

import etabli.common.stream;

/// Modèle d’archivage
interface IArchive {
    /// Charge un dossier
    void pack(string);

    /// Enregistre un dossier
    void unpack(string);

    /// Charge une archive
    void load(string);

    /// Enregistre une archive
    void save(string);
}

/// Conteneur permettant de sérialiser les fichiers d’un dossier
final class Archive : IArchive {
    private enum MagicWord = "CodexMagicae";

    /// Séparateur de chemin
    enum Separator = "/";

    private final class Directory {
        private {
            Directory[] _dirs;
            File[] _files;
            string _path, _name;
        }

        @property {
            string path() const {
                return _path.length ? (_path ~ Separator ~ _name) : _name;
            }

            string name() const {
                return _name;
            }
        }

        this(string path_, string name_) {
            _path = path_;
            _name = name_;
        }

        void pack(string path_) {
            auto entries = dirEntries(path_, SpanMode.shallow);
            foreach (entry; entries) {
                string entryPath = path();
                string entryName = baseName(entry.name);

                try {
                    if (entry.isDir) {
                        Directory subDir = new Directory(entryPath, entryName);
                        subDir.pack(entry.name);
                        _dirs ~= subDir;
                    }
                    else if (entry.isFile) {
                        File file = new File(entryPath, entryName);
                        file.pack(entry.name);
                        _files ~= file;
                    }
                }
                catch (Exception e) {
                    writeln("Erreur d’archivage: ", entry.name, " - ", e.msg);
                }
            }
        }

        void unpack(string path_) {
            if (!exists(path_))
                mkdir(path_);

            foreach (file; _files) {
                file.unpack(buildNormalizedPath(path_, file.name));
            }

            foreach (dir; _dirs) {
                dir.unpack(buildNormalizedPath(path_, dir.name));
            }
        }

        void load(InStream stream) {
            uint fileCount = stream.read!uint();
            string entryPath = path();
            for (uint i; i < fileCount; ++i) {
                string name = stream.read!string();
                File file = new File(entryPath, name);
                file.load(stream);
                _files ~= file;
            }

            uint dirCount = stream.read!uint();
            for (uint i; i < dirCount; ++i) {
                string name = stream.read!string();
                Directory dir = new Directory(entryPath, name);
                dir.load(stream);
                _dirs ~= dir;
            }
        }

        void save(OutStream stream) {
            stream.write!uint(cast(uint) _files.length);
            foreach (file; _files) {
                stream.write!string(file.name);
                file.save(stream);
            }

            stream.write!uint(cast(uint) _dirs.length);
            foreach (dir; _dirs) {
                stream.write!string(dir.name);
                dir.save(stream);
            }
        }

        /// Itérateur
        int opApply(int delegate(const ref File) dlg) const {
            int result;

            foreach (file; _files) {
                result = dlg(file);

                if (result)
                    return result;
            }

            foreach (dir; _dirs) {
                result = dir.opApply(dlg);

                if (result)
                    return result;
            }

            return result;
        }

        /// Ditto
        int opApply(int delegate(ref File) dlg) {
            int result;

            foreach (file; _files) {
                result = dlg(file);

                if (result)
                    return result;
            }

            foreach (dir; _dirs) {
                result = dir.opApply(dlg);

                if (result)
                    return result;
            }

            return result;
        }
    }

    /// Fichier
    final class File {
        private {
            string _path, _name;
            ubyte[] _data;
        }

        @property {
            /// Chemin du fichier
            string path() const {
                return _path ~ Separator ~ _name;
            }

            /// Nom du fichier
            string name(string name_) {
                return _name = name_;
            }

            /// Ditto
            string name() const {
                return _name;
            }

            /// Données
            ubyte[] data(ubyte[] data_) {
                return _data = data_;
            }

            /// Ditto
            const(ubyte)[] data() const {
                return _data;
            }
        }

        private this(string path_, string name_) {
            _path = path_;
            _name = name_;
        }

        private void pack(string path_) {
            _data = cast(ubyte[]) std.file.read(path_);
        }

        private void unpack(string path_) {
            std.file.write(path_, _data);
        }

        private void load(InStream stream) {
            _data = stream.read!(ubyte[])();
        }

        private void save(OutStream stream) {
            stream.write!(ubyte[])(_data);
        }

        void setRoot(string dir) {
            _path = dir;
        }
    }

    private {
        Directory _rootDir;
    }

    /// Init
    this() {
    }

    /// Charge un dossier
    void pack(string path) {
        string name = baseName(path);
        _rootDir = new Directory("", name);
        _rootDir.pack(path);
    }

    /// Enregistre un dossier
    void unpack(string path) {
        if (_rootDir)
            _rootDir.unpack(path);
    }

    /// Charge une archive
    void load(string path) {
        InStream stream = new InStream;
        stream.data = cast(ubyte[]) std.file.read(path);
        enforce(stream.read!string() == MagicWord);
        string name = stream.read!string();
        _rootDir = new Directory("", name);
        _rootDir.load(stream);
    }

    /// Enregistre une archive
    void save(string path) {
        OutStream stream = new OutStream;
        stream.write!string(MagicWord);
        if (_rootDir) {
            stream.write!string(_rootDir.name);
            _rootDir.save(stream);
        }
        std.file.write(path, stream.data);
    }

    /// Itérateur
    int opApply(int delegate(const ref File) dlg) const {
        if (_rootDir)
            return _rootDir.opApply(dlg);

        return 0;
    }

    /// Ditto
    int opApply(int delegate(ref File) dlg) {
        if (_rootDir)
            return _rootDir.opApply(dlg);

        return 0;
    }
}
