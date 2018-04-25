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

module audio.music;

import std.string: toStringz;

import derelict.sdl2.sdl;
import derelict.sdl2.mixer;

class Music {
	private {
		Mix_Music* _chunk;
		bool _isLooped = false;
		float _length = 0f;
		float _volume = 0f;
	}

	@property {
		bool isLoaded() const { return _chunk !is null; }

		bool isLooped() const { return _isLooped; }
		bool isLooped(bool newIsLooped) { return _isLooped = newIsLooped; }

		bool isPaused() const {
			return Mix_PausedMusic() == 1;
		}

		bool isFading() const {
			return Mix_FadingMusic() > 0;
		}

		bool isPlaying() const {
			return Mix_PlayingMusic() == 1;
		}

		float volume() const { return _volume; }
		float volume(float newVolume) {
			_volume = newVolume;
			Mix_VolumeMusic(cast(int)(_volume * MIX_MAX_VOLUME));
			return _volume;
		}
	}

	this(Mix_Music* chunk) {
		load(chunk);
	}

	this(string path) {
		load(path);
	}

	~this() {
		unload();
	}

	void load(string path) {
		auto chunk = Mix_LoadMUS(toStringz(path));
		if(!chunk)
			throw new Exception("Could not load sound \'" ~ path ~ "\'");
		load(chunk);
	}

	void load(Mix_Music* chunk) {
		_chunk = chunk;
		_volume = 1f;
	}

	void unload() {
		if(_chunk)
			Mix_FreeMusic(_chunk);
		_chunk = null;
	}

	void play() {
		Mix_PlayMusic(_chunk, _isLooped ? -1 : 0);
	}

	void fadeIn(float fadingDuration) {
		Mix_FadeInMusic(_chunk, _isLooped ? -1 : 0, cast(int)(fadingDuration * 1000f));
	}

	void pause() {
		Mix_PauseMusic();
	}

	void resume() {
		Mix_ResumeMusic();
	}

	void stop() {
		Mix_HaltMusic();
	}

	void fadeOut(float seconds) {
		Mix_FadeOutMusic(cast(int)(seconds * 1000f));
	}

	void rewind() {
		Mix_RewindMusic();
	}

	void setPosition(float position) {
		Mix_RewindMusic();
		Mix_SetMusicPosition(position);
	}
}