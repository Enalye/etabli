/**
    Ringbuffer

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.ringbuffer;

import core.sync.mutex;
import core.sync.semaphore;

import atelier.core.singleton;

/// Fixed size circular buffer. \
/// Size **must** be a power of 2.
/// Block when reading when empty or writing when full.
class RingBuffer(T, uint Size = 128u) : Singleton!(RingBuffer!(T, Size)) {
    static assert(Size != 0 && (Size & (Size - 1)) == 0);
    private {
        const uint _bufferSize = Size;
        Mutex _writerMutex, _readerMutex;
        Semaphore _fullSemaphore, _emptySemaphore;
        uint _posWriter, _posReader, _size;
        T[_bufferSize] _buffer;
    }

    @property {
        /// Is the buffer empty ?
        bool isEmpty() const {
            return _size == 0u;
        }
        /// Is the buffer full ?
        bool isFull() const {
            return _size == _bufferSize;
        }
    }

    /// Ctor
    this() {
        _writerMutex = new Mutex;
        _readerMutex = new Mutex;
        _fullSemaphore = new Semaphore(0u);
        _emptySemaphore = new Semaphore(Size);
    }

    /// Append a new value.
    void write(T value) {
        synchronized (_writerMutex) {
            _emptySemaphore.wait();
            _buffer[_posWriter] = value;
            _posWriter = (_posWriter + 1u) & (Size - 1);
            _size++;
            _fullSemaphore.notify();
        }
    }

    /// Extract a value.
    T read() {
        T value;
        synchronized (_readerMutex) {
            _fullSemaphore.wait();
            value = _buffer[_posReader];
            _posReader = (_posReader + 1u) & (Size - 1);
            _size--;
            _emptySemaphore.notify();
        }
        return value;
    }

    /// Cleanup everything, don't use the buffer afterwards.
    void close() {
        foreach (i; 0 .. _bufferSize)
            _emptySemaphore.notify();
        foreach (i; 0 .. _bufferSize)
            _fullSemaphore.notify();
        _writerMutex.unlock();
        _readerMutex.unlock();
        _size = 0u;
    }

    /// Empty the buffer.
    void reset() {
        synchronized (_writerMutex) {
            synchronized (_readerMutex) {
                foreach (i; 0 .. _bufferSize)
                    _emptySemaphore.notify();
                foreach (i; 0 .. _bufferSize) {
                    _emptySemaphore.wait();
                    _fullSemaphore.notify();
                }
                _size = 0u;
                _posReader = 0u;
                _posWriter = 0u;
            }
        }
    }
}
