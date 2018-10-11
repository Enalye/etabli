/**
    Sound

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.audio.sound;

import std.string: toStringz;

import derelict.sdl2.sdl;
import derelict.sdl2.mixer;

private {
	uint _topChannelIndex = 0u;
}

void createSoundGroup(int index, int size) {
	if(size <= 0)
		throw new Exception("Invalid sound group size");
	_topChannelIndex += Mix_GroupChannels(_topChannelIndex, _topChannelIndex + (size - 1), index);
}

class Sound {
	private {
		Mix_Chunk* _chunk;
		int _groupId = -1;
		int _currentChannelId = -1;
		bool _isLooped = false;
		float _length = 0f;
		float _volume = 0f;
	}

	@property {
		bool isLoaded() const { return _chunk !is null; }

		bool isLooped() const { return _isLooped; }
		bool isLooped(bool newIsLooped) { return _isLooped = newIsLooped; }

		bool isPaused() const {
			if(isChunkPlaying())
				return Mix_Paused(_currentChannelId) == 1;
			return false;
		}

		float length() const { return _length; }

		float volume() const { return _volume; }
		float volume(float newVolume) {
			_volume = newVolume;
			Mix_VolumeChunk(_chunk, cast(int)(_volume * MIX_MAX_VOLUME));
			return _volume;
		}

		int group() const { return _groupId; }
		int group(int newGroup) { return _groupId = newGroup; }
	}

	this(Mix_Chunk* chunk) {
		load(chunk);
	}

	this(string path) {
		load(path);
	}

	~this() {
		unload();
	}

	void load(string path) {
		auto chunk = Mix_LoadWAV(toStringz(path));
		if(!chunk)
			throw new Exception("Could not load sound \'" ~ path ~ "\'");
		load(chunk);
	}

	void load(Mix_Chunk* chunk) {
		_chunk = chunk;
		_length = (cast(float)_chunk.alen) / (44100f * 4f);
		_volume = (cast(float)_chunk.volume) / MIX_MAX_VOLUME;
	}

	void unload() {
		if(_chunk)
			Mix_FreeChunk(_chunk);
		_chunk = null;
	}

	void play(float maxDuration = 0f) {
		int availableChannel = -1;
		if(_groupId != -1) {
			availableChannel = Mix_GroupAvailable(_groupId);
			if(-1 == availableChannel)
				availableChannel = Mix_GroupOldest(_groupId);
		}
		/+
			todo: Unregister then register each effects here.
		+/
		if(maxDuration > 0f)
			_currentChannelId = Mix_PlayChannelTimed(availableChannel, _chunk,
				_isLooped ? -1 : 0,
				cast(int)(maxDuration * 1000f));
		else
			_currentChannelId = Mix_PlayChannel(availableChannel, _chunk,
				_isLooped ? -1 : 0);
	}

	void fadeIn(float fadingDuration, float maxDuration = 0f) {
		int availableChannel = -1;
		if(_groupId != -1) {
			availableChannel = Mix_GroupAvailable(_groupId);
			if(-1 == availableChannel)
				availableChannel = Mix_GroupOldest(_groupId);
		}
		/+
			todo: Unregister then register each effects here.
		+/
		if(maxDuration > 0f)
			_currentChannelId = Mix_FadeInChannelTimed(availableChannel, _chunk,
				_isLooped ? -1 : 0,
				cast(int)(fadingDuration * 1000f),
				cast(int)(maxDuration * 1000f));
		else
			_currentChannelId = Mix_FadeInChannel(availableChannel, _chunk,
				_isLooped ? -1 : 0,
				cast(int)(fadingDuration * 1000f));
	}

	void pause() {
		if(isChunkPlaying())
			Mix_Pause(_currentChannelId);
	}

	void resume() {
		if(isChunkPlaying())
			Mix_Resume(_currentChannelId);
	}

	void stop() {
		if(isChunkPlaying())
			Mix_HaltChannel(_currentChannelId);
	}

	void stop(float seconds) {
		if(isChunkPlaying)
			Mix_ExpireChannel(_currentChannelId, cast(int)(seconds * 1000f));
	}

	void fadeOut(float seconds) {
		if(isChunkPlaying())
			Mix_FadeOutChannel(_currentChannelId, cast(int)(seconds * 1000f));
	}

	void fadeOutGroup(float seconds) {
		if(_groupId == -1)
			return;
		Mix_FadeOutGroup(_groupId, cast(int)(seconds * 1000f));
	}

	void stopGroup() {
		if(_groupId == -1)
			return;
		Mix_HaltGroup(_groupId);
	}

	void pauseAll() {
		Mix_Pause(-1);
	}

	void resumeAll() {
		Mix_Resume(-1);
	}

	private bool isChunkPlaying() const {
		if(_currentChannelId == -1)
			return false;
		return _chunk == Mix_GetChunk(_currentChannelId);
	}
}