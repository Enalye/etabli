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

module atelier.ui.save;

import std.file;
import std.path;
import std.conv: to;

import atelier.core;
import atelier.common;

import atelier.ui.widget;
import atelier.ui.modal;
import atelier.ui.button;
import atelier.ui.list.vlist;
import atelier.ui.inputfield;

private {
	InStream _loadedStream = null;
}

void setSaveWindow(Widget callbackWidget, string callbackId, OutStream stream, string path, string extension) {
	path = buildNormalizedPath(absolutePath(path));
	if(!extension.length)
		throw new Exception("Cannot save without a file extension");
	auto modal = new SaveWindow(stream, path, extension);
	modal.setCallback(callbackWidget, callbackId);
	setModalWindow(modal);
}

void setLoadWindow(Widget callbackWidget, string callbackId, string path, string extension) {
	InStream stream = new InStream;
	path = buildNormalizedPath(absolutePath(path));
	if(!extension.length)
		throw new Exception("Cannot save without a file extension");
	auto modal = new LoadWindow(stream, path, extension);
	modal.setCallback(callbackWidget, callbackId);
	_loadedStream = null;
	setModalWindow(modal);
}

InStream getLoadedStream() {
	return _loadedStream;
}

class SaveWindow: ModalWindow {
	private {
		OutStream _stream;
		string _path, _extension;
		InputField _inputField;
	}

	this(OutStream stream, string path, string extension) {
		super("Saving", Vec2f(250f, 25f));
		_stream = stream;
		_path = path;
		_extension = extension;
		_inputField = new InputField(layout.size, "Sans Titre", true);
		layout.addChild(_inputField);
	}

	override void onEvent(Event event) {
		super.onEvent(event);
		if(event.type == EventType.Callback) {
			if(event.id == "apply") {
				string fullPath = buildPath(_path, setExtension(_inputField.text, _extension));
				if(!isValidPath(fullPath))
					throw new Exception("Error saving file: invalid path \'" ~ fullPath ~ "\'");
				write(fullPath, _stream.data);
				triggerCallback();
			}
		}
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		applyBtn.isLocked = (_inputField.text.length == 0L);
	}
}

class LoadWindow: ModalWindow {
	private {
		InStream _stream;
		string[] _files;
		VList _list;
	}

	this(InStream stream, string path, string extension) {
		super("Loading", Vec2f(250f, 200f));
		_stream = stream;
		_list = new VList(layout.size);
		foreach(file; dirEntries(path, "*." ~ extension, SpanMode.depth)) {
			_files ~= file;
			string relativeFileName = stripExtension(baseName(file));
			auto btn = new TextButton(relativeFileName);
			_list.addChild(btn);
		}
		layout.addChild(_list);
	}

	override void onEvent(Event event) {
		super.onEvent(event);

		if(event.type == EventType.Callback) {
			if(event.id == "apply") {
				if(_list.selected < _files.length) {
					string fileName = _files[_list.selected];
					if(!exists(fileName))
						throw new Exception("Error saving file: invalid path \'" ~ fileName ~ "\'");
					_stream.set(cast(ubyte[])(read(fileName)));
					if(_stream.length)
						_loadedStream = _stream;
					else
						_loadedStream = null;
					triggerCallback();
				}
			}
		}
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		applyBtn.isLocked = (_files.length == 0L);
	}
}