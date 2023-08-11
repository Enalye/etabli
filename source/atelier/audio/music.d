/**
    Music

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.audio.music;

import std.string : toStringz;

import bindbc.sdl;

/// Music
class Music {
    private {
        Mix_Music* _chunk;
        bool _isLooping, _ownData;
        float _length = 0f;
        float _volume = 0f;
    }

    @property {
        bool isLoaded() const {
            return _chunk !is null;
        }

        bool isLooping() const {
            return _isLooping;
        }

        bool isLooping(bool isLooping_) {
            return _isLooping = isLooping_;
        }

        bool isPaused() const {
            return Mix_PausedMusic() == 1;
        }

        bool isFading() const {
            return Mix_FadingMusic() > 0;
        }

        bool isPlaying() const {
            return Mix_PlayingMusic() == 1;
        }

        float volume() const {
            return _volume;
        }

        float volume(float newVolume) {
            _volume = newVolume;
            Mix_VolumeMusic(cast(int)(_volume * MIX_MAX_VOLUME));
            return _volume;
        }
    }

    this(Music music) {
        _chunk = music._chunk;
        _isLooping = music._isLooping;
        _length = music._length;
        _volume = music._volume;
        _ownData = false;
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
        if (!chunk)
            throw new Exception("Could not load sound \'" ~ path ~ "\'");
        load(chunk);
    }

    void load(Mix_Music* chunk) {
        _chunk = chunk;
        _volume = 1f;
        _ownData = true;
    }

    void unload() {
        if (!_ownData)
            return;
        if (_chunk)
            Mix_FreeMusic(_chunk);
        _chunk = null;
    }

    void play() {
        Mix_PlayMusic(_chunk, _isLooping ? -1 : 0);
    }

    void fadeIn(float fadingDuration) {
        Mix_FadeInMusic(_chunk, _isLooping ? -1 : 0, cast(int)(fadingDuration * 1000f));
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
