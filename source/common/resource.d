/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module common.resource;

import std.typecons;
import std.file;
import std.path;
import std.algorithm: count;
import std.conv: to;

import core.util;
import core.json;
import core.vec2;
import render.all;
import script.all;
import audio.all;

private {
	void*[string] _caches;
	string[string] _cachesSubFolder;
	string _dataFolder = "./";
}

void loadResources() {
	//Path to 'data/'
	auto path = buildNormalizedPath(absolutePath(_dataFolder));

	auto textureCache = new DataCache!Texture(path, getResourceSubFolder!Texture, "*.{png,bmp,jpg}");
	auto fontCache = new DataCache!Font(path, getResourceSubFolder!Font, "*.{ttf}");
	auto spriteCache = new SpriteCache!Sprite(path, getResourceSubFolder!Sprite, "*.{sprite}", textureCache);
	auto tilesetCache = new TilesetCache!Tileset(path, getResourceSubFolder!Tileset, "*.{tileset}", textureCache);
	auto soundCache = new DataCache!Sound(path, getResourceSubFolder!Sound, "*.{wav,ogg}");
	auto musicCache = new DataCache!Music(path, getResourceSubFolder!Music, "*.{wav,ogg,mp3}");

	setResourceCache!Texture(textureCache);
	setResourceCache!Font(fontCache);
	setResourceCache!Sprite(spriteCache);
	setResourceCache!Tileset(tilesetCache);
	setResourceCache!Sound(soundCache);
	setResourceCache!Music(musicCache);
}

void setResourceFolder(string dataFolder) {
	_dataFolder = dataFolder;
}

string getResourceFolder() {
	return buildNormalizedPath(absolutePath(_dataFolder));
}

void setResourceSubFolder(T)(string subFolder) {
	_cachesSubFolder[T.stringof] = subFolder;
}

string getResourceSubFolder(T)() {
	auto subFolder = T.stringof in _cachesSubFolder;
	if(!subFolder)
		return "";
	return *subFolder;
}

void setResourceCache(T)(ResourceCache!T cache) {
	_caches[T.stringof] = cast(void*)cache;
}

void getResourceCache(T)() {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return cast(ResourceCache!T)(*cache);
}

bool canFetch(T)(string name) {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return (cast(ResourceCache!T)*cache).canGet(name);
}

bool canFetchPack(T)(string name = ".") {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return (cast(ResourceCache!T)*cache).canGetPack(name);
}

T fetch(T)(string name) {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return (cast(ResourceCache!T)*cache).get(name);
}

T[] fetchPack(T)(string name = ".") {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return (cast(ResourceCache!T)*cache).getPack(name);
}

string[] fetchPackNames(T)(string name = ".") {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return (cast(ResourceCache!T)*cache).getPackNames(name);
}

Tuple!(T, string)[] fetchPackTuples(T)(string name = ".") {
	auto cache = T.stringof in _caches;
	if(!cache)
		throw new Exception("No cache of type \'" ~ T.stringof ~ "\' has been declared");
	return (cast(ResourceCache!T)*cache).getPackTuples(name);
}

private class ResourceCache(T) {
	protected {
		Tuple!(T, string)[] _data;
		uint[string] _ids;
		uint[][string] _packs;
	}

	protected this() {}

	bool canGet(string name) {
		return (buildNormalizedPath(name) in _ids) !is null;
	}

	bool canGetPack(string pack = ".") {
		return (buildNormalizedPath(pack) in _packs) !is null;
	}

	T get(string name) {
		name = buildNormalizedPath(name);

		auto p = (name in _ids);
		if(p is null)
			throw new Exception("Resource: no \'" ~ name ~ "\' loaded");
		return _data[*p][0];
	}

	T[] getPack(string pack = ".") {
		pack = buildNormalizedPath(pack);

		auto p = (pack in _packs);
		if(p is null)
			throw new Exception("Resource: no pack \'" ~ pack ~ "\' loaded");

		T[] result;
		foreach(i; *p)
			result ~= _data[i][0];
		return result;
	}

	string[] getPackNames(string pack = ".") {
		pack = buildNormalizedPath(pack);

		auto p = (pack in _packs);
		if(p is null)
			throw new Exception("Resource: no pack \'" ~ pack ~ "\' loaded");

		string[] result;
		foreach(i; *p)
			result ~= _data[i][1];
		return result;
	}

	Tuple!(T, string)[] getPackTuples(string pack = ".") {
		pack = buildNormalizedPath(pack);

		auto p = (pack in _packs);
		if(p is null)
			throw new Exception("Resource: no pack \'" ~ pack ~ "\' loaded");

		Tuple!(T, string)[] result;
		foreach(i; *p)
			result ~= _data[i];
		return result;
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
			T sprite = T(texture);

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
        import std.stdio;
        writeln(file);
		foreach(string tag, JSONValue value; sheetJson.object) {
			if((tag in _ids) !is null)
				throw new Exception("Duplicate tileset defined \'" ~ tag ~ "\' in \'" ~ file ~ "\'");
            Vec2i grid, startPos, tileSize;
            int nbTiles;

            //Max number of tiles the tileset cannot exceeds
            nbTiles = getJsonInt(value, "nbtiles", -1);

            //Upper left border of the tileset
            startPos.x = getJsonInt(value, "x", 0);
            startPos.y = getJsonInt(value, "y", 0);

            //Tile size
            tileSize.x = getJsonInt(value, "w");
            tileSize.y = getJsonInt(value, "h");

            grid.x = getJsonInt(value, "columns", 1);
            grid.y = getJsonInt(value, "lines", 1);

            string type = getJsonStr(value, "type", ".");

            T tileset = T(texture, grid, tileSize);
            tileset.scale = Vec2f(getJsonFloat(value, "scalex", 1f), getJsonFloat(value, "scaley", 1f));

            uint id = cast(uint)_data.length;
            _packs[type] ~= id;
            _ids[tag] = id;
            _data ~= tuple(tileset, tag);
        }
	}
}