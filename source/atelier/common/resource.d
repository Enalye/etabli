/**
    Resource

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.common.resource;

import std.typecons;
import std.file;
import std.path;
import std.algorithm: count;
import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.audio;

private {
	void*[string] _caches;
	string[string] _cachesSubFolder;
}

void setResourceCache(T)(ResourceCache!T cache) {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	_caches[T.stringof] = cast(void*)cache;
}

void getResourceCache(T)() {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return cast(ResourceCache!T)(*cache);
}

/// Is an object of this name and of this type stored ?
bool canFetch(T)(string name) {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).canGet(name);
}

/// Is an set of this name and of this type stored ?
bool canFetchPack(T)(string name = ".") {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).canGetPack(name);
}

/// Returns a stored resource.
T fetch(T)(string name) {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).get(name);
}

/// Returns all resources of a set.
T[] fetchPack(T)(string name = ".") {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).getPack(name);
}

/// Returns all resources' name of a set.
string[] fetchPackNames(T)(string name = ".") {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).getPackNames(name);
}

/// Returns all resources of a set as a tuple of the resource + its name.
Tuple!(T, string)[] fetchPackTuples(T)(string name = ".") {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).getPackTuples(name);
}

/// Returns everything of this type as tuples of the resources + their name.
Tuple!(T, string)[] fetchAllTuples(T)() {
	static assert(!__traits(isAbstractClass, T), "Fetch cannot instanciate the abstract class " ~ T.stringof);
	auto cache = T.stringof in _caches;
	assert(cache, "No cache declared of type "  ~ T.stringof);
	return (cast(ResourceCache!T)*cache).getAllTuples();
}

/// Internal cache storing all loaded resources.
class ResourceCache(T) {
	protected {
		Tuple!(T, string)[] _data;
		uint[string] _ids;
		uint[][string] _packs;
	}

	this() {}

	bool canGet(string name) {
		return (name in _ids) !is null;
	}

	bool canGetPack(string pack = ".") {
		return (buildNormalizedPath(pack) in _packs) !is null;
	}

	T get(string name) {
		auto p = (name in _ids);
		assert(p, "Resource: no \'" ~ name ~ "\' loaded");
		return new T(_data[*p][0]);
	}

	T[] getPack(string pack = ".") {
		pack = buildNormalizedPath(pack);

		auto p = (pack in _packs);
		assert(p, "Resource: no pack \'" ~ pack ~ "\' loaded");

		T[] result;
		foreach(i; *p)
			result ~= new T(_data[i][0]);
		return result;
	}

	string[] getPackNames(string pack = ".") {
		pack = buildNormalizedPath(pack);

		auto p = (pack in _packs);
		assert(p, "Resource: no pack \'" ~ pack ~ "\' loaded");

		string[] result;
		foreach(i; *p)
			result ~= _data[i][1];
		return result;
	}

	Tuple!(T, string)[] getPackTuples(string pack = ".") {
		pack = buildNormalizedPath(pack);

		auto p = (pack in _packs);
		assert(p, "Resource: no pack \'" ~ pack ~ "\' loaded");

		Tuple!(T, string)[] result;
		foreach(i; *p)
			result ~= _data[i];
		return result;
	}

    Tuple!(T, string)[] getAllTuples() {
		return _data;
	}

    void set(T value, string tag, string pack = "") {
        uint id = cast(uint)_data.length;
        if(pack.length)
            _packs[pack] ~= id;
        _ids[tag] = id;
        _data ~= tuple(value, tag);
    }
}

class DataCache(T): ResourceCache!T {
	this(string path, string sub, string filter) {
		path = buildPath(path, sub);

		if(!exists(path) || !isDir(path))
			throw new Exception("The specified path is not a valid directory: \'" ~ path ~ "\'");
		auto files = dirEntries(path, filter, SpanMode.depth);
		foreach(file; files) {
			string relativeFileName = stripExtension(relativePath(file, path));
			string folder = dirName(relativeFileName);
			uint id = cast(uint)_data.length;

			_packs[folder] ~= id;
			_ids[relativeFileName] = id;
			_data ~= tuple(new T(file), relativeFileName);
		}
	}
}

private class SpriteCache(T): ResourceCache!T {
	this(string path, string sub, string filter, ResourceCache!Texture cache) {
		path = buildPath(path, sub);

		if(!exists(path) || !isDir(path))
			throw new Exception("The specified path is not a valid directory: \'" ~ path ~ "\'");
		auto files = dirEntries(path, filter, SpanMode.depth);
		foreach(file; files) {
			string relativeFileName = stripExtension(relativePath(file, path));
			string folder = dirName(relativeFileName);

			auto texture = cache.get(relativeFileName);
			loadJson(file, texture);
		}
	}

	private void loadJson(string file, Texture texture) {
		auto sheetJson = parseJSON(readText(file));
		foreach(string tag, JSONValue value; sheetJson.object) {
			if((tag in _ids) !is null)
				throw new Exception("Duplicate sprite defined \'" ~ tag ~ "\' in \'" ~ file ~ "\'");
			T sprite = new T(texture);

			//Clip
			sprite.clip.x = getJsonInt(value, "x");
			sprite.clip.y = getJsonInt(value, "y");
			sprite.clip.z = getJsonInt(value, "w");
			sprite.clip.w = getJsonInt(value, "h");

			//Size/scale
			sprite.size = to!Vec2f(sprite.clip.zw);
			sprite.size *= Vec2f(getJsonFloat(value, "scalex", 1f), getJsonFloat(value, "scaley", 1f));
			
			//Flip
			bool flipH = getJsonBool(value, "fliph", false);
			bool flipV = getJsonBool(value, "flipv", false);

			if(flipH && flipV)
				sprite.flip = Flip.BothFlip;
			else if(flipH)
				sprite.flip = Flip.HorizontalFlip;
			else if(flipV)
				sprite.flip = Flip.VerticalFlip;
			else
				sprite.flip = Flip.NoFlip;

			//Center expressed in texels, it does the same thing as Anchor
			Vec2f center = Vec2f(getJsonFloat(value, "centerx", -1f), getJsonFloat(value, "centery", -1f));
			if(center.x > -.5f) //Temp
				sprite.anchor.x = center.x / cast(float)(sprite.clip.z);
			if(center.y > -.5f)
				sprite.anchor.y = center.y / cast(float)(sprite.clip.w);

			//Anchor, same as Center but uses a relative coordinate system where [.5,.5] is the center
			if(center.x < 0f) //Temp
				sprite.anchor.x = getJsonFloat(value, "anchorx", .5f);
			if(center.y < 0f)
				sprite.anchor.y = getJsonFloat(value, "anchory", .5f);

			//Type
			string type = getJsonStr(value, "type", ".");

			//Register sprite
			uint id = cast(uint)_data.length;
			_packs[type] ~= id;
			_ids[tag] = id;
			_data ~= tuple(sprite, tag);
		}
	}
}

private class TilesetCache(T): ResourceCache!T {
	this(string path, string sub, string filter, ResourceCache!Texture cache) {
		path = buildPath(path, sub);

		if(!exists(path) || !isDir(path))
			throw new Exception("The specified path is not a valid directory: \'" ~ path ~ "\'");
		auto files = dirEntries(path, filter, SpanMode.depth);
		foreach(file; files) {
			string relativeFileName = stripExtension(relativePath(file, path));
			string folder = dirName(relativeFileName);

			auto texture = cache.get(relativeFileName);
			loadJson(file, texture);
		}
	}

	private void loadJson(string file, Texture texture) {
		auto sheetJson = parseJSON(readText(file));
		foreach(string tag, JSONValue value; sheetJson.object) {
			if((tag in _ids) !is null)
				throw new Exception("Duplicate tileset defined \'" ~ tag ~ "\' in \'" ~ file ~ "\'");
            Vec4i clip;
            int columns, lines, maxtiles;

            //Max number of tiles the tileset cannot exceeds
            maxtiles = getJsonInt(value, "tiles", -1);

            //Upper left border of the tileset
            clip.x = getJsonInt(value, "x", 0);
            clip.y = getJsonInt(value, "y", 0);

            //Tile size
            clip.z = getJsonInt(value, "w");
            clip.w = getJsonInt(value, "h");

            columns = getJsonInt(value, "columns", 1);
            lines = getJsonInt(value, "lines", 1);

            string type = getJsonStr(value, "type", ".");

            T tileset = new T(texture, clip, columns, lines, maxtiles);
            tileset.scale = Vec2f(getJsonFloat(value, "scalex", 1f), getJsonFloat(value, "scaley", 1f));

            //Flip
			bool flipH = getJsonBool(value, "fliph", false);
			bool flipV = getJsonBool(value, "flipv", false);

			if(flipH && flipV)
				tileset.flip = Flip.BothFlip;
			else if(flipH)
				tileset.flip = Flip.HorizontalFlip;
			else if(flipV)
				tileset.flip = Flip.VerticalFlip;
			else
				tileset.flip = Flip.NoFlip;

            uint id = cast(uint)_data.length;
            _packs[type] ~= id;
            _ids[tag] = id;
            _data ~= tuple(tileset, tag);
        }
	}
}