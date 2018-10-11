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

//Size MUST be a power of 2
class RingBuffer(T, uint Size = 128u): Singleton!(RingBuffer!(T, Size)) {
	static assert(Size != 0 && (Size & (Size-1)) == 0);
	private {
		const uint _bufferSize = Size;
		Mutex _writerMutex, _readerMutex;
		Semaphore _fullSemaphore, _emptySemaphore;
		uint _posWriter, _posReader, _size;
		T[_bufferSize] _buffer;
	}

	@property {
		bool isEmpty() const { return _size == 0u; }
		bool isFull() const { return _size == _bufferSize; }
	}

	this() {
		_writerMutex = new Mutex;
		_readerMutex = new Mutex;
		_fullSemaphore = new Semaphore(0u);
		_emptySemaphore = new Semaphore(Size);
	}

	void write(T value) {
		synchronized(_writerMutex) {
			_emptySemaphore.wait();
			_buffer[_posWriter] = value;
			_posWriter = (_posWriter + 1u) & (Size - 1);
			_size ++;
			_fullSemaphore.notify();
		}
	}

	T read() {
		T value;
		synchronized(_readerMutex) {
			_fullSemaphore.wait();
			value = _buffer[_posReader];
			_posReader = (_posReader + 1u) & (Size - 1);
			_size --;
			_emptySemaphore.notify();
		}
		return value;
	}

	void close() {
		foreach(i; 0 .. _bufferSize)
			_emptySemaphore.notify();
		foreach(i; 0 .. _bufferSize)
			_fullSemaphore.notify();
		_writerMutex.unlock();
		_readerMutex.unlock();
		_size = 0u;
	}

	void reset() {
		synchronized(_writerMutex) {
			synchronized(_readerMutex) {
				foreach(i; 0 .. _bufferSize)
					_emptySemaphore.notify();
				foreach(i; 0 .. _bufferSize) {
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