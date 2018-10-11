/**
    Singleton

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.singleton;

class Singleton(T) {
	protected this() {}
	private static bool _isInstantiated;
	private __gshared T _instance;
 
	static T get() {
		if(!_isInstantiated) {
			synchronized(Singleton.classinfo) {
				if (!_instance) {
					_instance = new T;
				}
				_isInstantiated = true;
			}
		}
		return _instance;
	}
}