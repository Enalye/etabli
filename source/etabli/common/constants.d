module etabli.common.constants;

version (Windows) {
    enum Etabli_Exe = "redist.exe";
    enum Etabli_Library = "etabli.dll";
}
version (posix) {
    enum Etabli_Exe = "redist";
    enum Etabli_Library = "etabli.so";
}

enum Etabli_Version_Major = 0;
enum Etabli_Version_Minor = 1;
enum Etabli_Version_Display = "0.1";

/// Identifiant utilisé dans les fichiers devant être validés
enum Etabli_Version_ID = Etabli_Version_Major * 1000 + Etabli_Version_Minor;

enum Etabli_Project_File = "etabli.ffd";

// Initialisation fenêtre
enum Etabli_Window_Width_Default = 800;

enum Etabli_Window_Height_Default = 600;

enum Etabli_Window_Enabled_Default = true;

/// Fichier de configuration
enum Etabli_Configuration_Extension = ".acf";

/// Fichier d’application
enum Etabli_Application_Extension = ".atl";

/// Fichier de données
enum Etabli_Archive_Extension = ".pqt";

/// Fichier de ressource farfadet
enum Etabli_Resource_Extension = ".res";

/// Fichier de ressource compilé
enum Etabli_Resource_Compiled_Extension = ".resc";

enum Etabli_Environment_MagicWord = "etabli";

enum Etabli_Resource_Compiled_MagicWord = "resc";

static immutable Etabli_Dependencies = [
    "SDL2.dll", "SDL2_image.dll", "SDL2_ttf.dll"
];
