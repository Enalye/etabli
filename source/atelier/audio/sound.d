/**
    Sound

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.audio.sound;

import std.string : toStringz;
import std.algorithm.comparison : clamp;
import bindbc.sdl, bindbc.sdl.mixer;

private {
    uint _topChannelIndex = 0u;
}

/// Create a group with a number of reserved channels for sounds in the same category.
void createSoundGroup(int index, int size) {
    if (size <= 0)
        throw new Exception("Invalid sound group size");
    _topChannelIndex += Mix_GroupChannels(_topChannelIndex, _topChannelIndex + (size - 1), index);
}

/// Interrupt all sounds currently playing
void pauseSounds() {
    Mix_Pause(-1);
}

/// Resume all stopped sounds
void resumeSounds() {
    Mix_Resume(-1);
}

/// Sound
final class Sound {
    private {
        Mix_Chunk* _chunk;
        int _groupId = -1;
        int _currentChannelId = -1;
        bool _isLooping, _ownData;
        float _length = 0f;
        float _volume = 0f;
        ubyte _leftPanning = 0, _rightPanning = 0, _distance = 0;
        short _angle = 0;
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

        bool isPlaying() const {
            if (isChunkPlaying())
                return Mix_Playing(_currentChannelId) == 1;
            return false;
        }

        bool isPaused() const {
            if (isChunkPlaying())
                return Mix_Paused(_currentChannelId) == 1;
            return false;
        }

        float length() const {
            return _length;
        }

        float volume() const {
            return _volume;
        }

        float volume(float volume_) {
            _volume = volume_;
            Mix_VolumeChunk(_chunk, cast(int)(_volume * MIX_MAX_VOLUME));
            return _volume;
        }

        int group() const {
            return _groupId;
        }

        int group(int groupId_) {
            return _groupId = groupId_;
        }
    }

    this(Sound sound) {
        _chunk = sound._chunk;
        _groupId = sound._groupId;
        _currentChannelId = sound._currentChannelId;
        _isLooping = sound._isLooping;
        _length = sound._length;
        _volume = sound._volume;
        _ownData = false;
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
        if (!chunk)
            throw new Exception("Could not load sound \'" ~ path ~ "\'");
        load(chunk);
    }

    void load(Mix_Chunk* chunk) {
        _chunk = chunk;
        _length = (cast(float) _chunk.alen) / (44_100f * 4f);
        _volume = (cast(float) _chunk.volume) / MIX_MAX_VOLUME;
        _ownData = true;
    }

    void unload() {
        if (!_ownData)
            return;
        if (_chunk)
            Mix_FreeChunk(_chunk);
        _chunk = null;
    }

    void play(float maxDuration = 0f) {
        int availableChannel = -1;
        if (_groupId != -1) {
            availableChannel = Mix_GroupAvailable(_groupId);
            if (-1 == availableChannel)
                availableChannel = Mix_GroupOldest(_groupId);
        }
        /+
			todo: Unregister then register each effects here.
		+/
        if (maxDuration > 0f)
            _currentChannelId = Mix_PlayChannelTimed(availableChannel, _chunk,
                    _isLooping ? -1 : 0, cast(int)(maxDuration * 1_000f));
        else
            _currentChannelId = Mix_PlayChannel(availableChannel, _chunk, _isLooping ? -1 : 0);

        if (_leftPanning || _rightPanning)
            Mix_SetPanning(_currentChannelId, _leftPanning, _rightPanning);
        if (_angle || _distance)
            Mix_SetPosition(_currentChannelId, _angle, _distance);
        else if (_distance)
            Mix_SetDistance(_currentChannelId, _distance);

    }

    void fadeIn(float fadingDuration, float maxDuration = 0f) {
        int availableChannel = -1;
        if (_groupId != -1) {
            availableChannel = Mix_GroupAvailable(_groupId);
            if (-1 == availableChannel)
                availableChannel = Mix_GroupOldest(_groupId);
        }
        /+
			todo: Unregister then register each effects here.
		+/
        if (maxDuration > 0f)
            _currentChannelId = Mix_FadeInChannelTimed(availableChannel, _chunk, _isLooping
                    ? -1 : 0, cast(int)(fadingDuration * 1_000f), cast(int)(maxDuration * 1_000f));
        else
            _currentChannelId = Mix_FadeInChannel(availableChannel, _chunk,
                    _isLooping ? -1 : 0, cast(int)(fadingDuration * 1_000f));
    }

    void pause() {
        if (isChunkPlaying())
            Mix_Pause(_currentChannelId);
    }

    void resume() {
        if (isChunkPlaying())
            Mix_Resume(_currentChannelId);
    }

    void stop() {
        if (isChunkPlaying())
            Mix_HaltChannel(_currentChannelId);
    }

    void stop(float seconds) {
        if (isChunkPlaying)
            Mix_ExpireChannel(_currentChannelId, cast(int)(seconds * 1_000f));
    }

    void fadeOut(float seconds) {
        if (isChunkPlaying()) {
            auto duration = cast(int)(seconds * 1_000f);
            Mix_FadeOutChannel(_currentChannelId, duration);

            // Prevents a glitch when a sound with fadeIn is fadeOut in the same frame or the next one
            // This causes the sound to never stops. Idk why (maybe threads stuff), but this fixes it.
            Mix_ExpireChannel(_currentChannelId, duration);
        }
    }

    void fadeOutGroup(float seconds) {
        if (_groupId == -1)
            return;
        Mix_FadeOutGroup(_groupId, cast(int)(seconds * 1_000f));
    }

    void stopGroup() {
        if (_groupId == -1)
            return;
        Mix_HaltGroup(_groupId);
    }

    private bool isChunkPlaying() const {
        if (_currentChannelId == -1)
            return false;
        return _chunk == Mix_GetChunk(_currentChannelId);
    }

    void setDistance(float distance) {
        _distance = cast(ubyte) clamp(distance * 255f, 0f, 255f);
        if (!isChunkPlaying())
            return;
        Mix_SetDistance(_currentChannelId, _distance);
    }

    void setPanning(float left, float right) {
        _leftPanning = cast(ubyte) clamp(left * 255f, 0f, 255f);
        _rightPanning = cast(ubyte) clamp(right * 255f, 0f, 255f);
        if (!isChunkPlaying())
            return;
        Mix_SetPanning(_currentChannelId, _leftPanning, _rightPanning);
    }

    void setPosition(float angle, float distance) {
        _angle = cast(short) angle;
        _distance = cast(ubyte) clamp(distance * 255f, 0f, 255f);
        if (!isChunkPlaying())
            return;
        Mix_SetPosition(_currentChannelId, _angle, _distance);
    }
}
