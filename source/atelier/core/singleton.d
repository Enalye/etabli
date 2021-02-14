/**
    Singleton

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.singleton;

/// Derivate from this class and use MyClass.get() to get your singleton.
class Singleton(T) {
    protected this() {
    }

    private static bool _isInstantiated;
    private __gshared T _instance;

    /// Returns the instance of the singleton.
    static T get() {
        if (!_isInstantiated) {
            synchronized (Singleton.classinfo) {
                if (!_instance) {
                    _instance = new T;
                }
                _isInstantiated = true;
            }
        }
        return _instance;
    }
}
