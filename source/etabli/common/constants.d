module etabli.common.constants;

version (Windows) {
    enum etabli_Exe = "etabli.exe";
}
version (posix) {
    enum etabli_Exe = "etabli";
}

enum etabli_Version_Major = 0;
enum etabli_Version_Minor = 1;
enum etabli_Version_Display = "0.1";

/// Identifiant utilisé dans les fichiers devant être validés
enum etabli_Version_ID = etabli_Version_Major * 1000 + etabli_Version_Minor;

enum etabli_Project_File = "etabli.json";

// etabli.json
enum etabli_Project_DefaultConfiguration_Node = "defaultConfig";

enum etabli_Project_Configurations_Node = "configs";

enum etabli_Project_DefaultConfigurationName = "app";

enum etabli_Project_Name_Node = "name";

enum etabli_Project_Source_Node = "source";

enum etabli_Project_Resources_Node = "resources";

enum etabli_Project_Export_Node = "export";

enum etabli_Project_Window_Node = "window";

enum etabli_Project_Window_Enabled_Node = "enabled";

enum etabli_Project_Window_Title_Node = "title";

enum etabli_Project_Window_Width_Node = "width";

enum etabli_Project_Window_Height_Node = "height";

enum etabli_Project_Window_Icon_Node = "icon";

// Initialisation fenêtre
enum etabli_Window_Width_Default = 800;

enum etabli_Window_Height_Default = 600;

enum etabli_Window_Enabled_Default = true;

enum etabli_Window_Icon_Default = etabli_StandardLibrary_File ~ "/lapis.png";

/// GRB: **GR**imoire **B**ytecode
enum etabli_Bytecode_Extension = ".grb";

/// ACFG: **A**lchimie **C**on**F**iguration
enum etabli_Configuration_Extension = ".acf";

/// AME: **A**lchimie **M**achine **E**nvironement
enum etabli_Environment_Extension = ".dh";

/// ARC: **P**a**Q**ue**T**
enum etabli_Archive_Extension = ".pqt";

/// ARS: **A**lchimie **R**e**S**source
enum etabli_Resource_Extension = ".ars";

/// ARSC: **A**lchimie **R**e**S**source **C**ompiled
enum etabli_Resource_Compiled_Extension = ".arsc";

enum etabli_StandardLibrary_File = "codex";

enum etabli_StandardLibrary_Path = etabli_StandardLibrary_File ~ etabli_Archive_Extension;

enum etabli_Environment_MagicWord = "etabli";

enum etabli_Resource_Compiled_MagicWord = "rscdh";
