/**
    IndexedArray

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.core.indexedarray;

import std.parallelism;
import std.range;
import std.typecons;

/**
	Special Array that remove fragmentation while keeping indexes valid.
*/
class IndexedArray(T, uint _capacity, bool _useParallelism = false) {
	private uint _dataTop = 0u;
	private uint _availableIndexesTop = 0u;
	private uint _removeTop = 0u;

	private T[_capacity] _dataTable;
	private uint[_capacity] _availableIndexes;
	private uint[_capacity] _translationTable;
	private uint[_capacity] _reverseTranslationTable;
	private uint[_capacity] _removeTable;

	@property {
		uint length() const { return _dataTop; }
		uint capacity() const { return _capacity; }
		ref T[_capacity] data() { return _dataTable; }
	}

	uint push(T value) {
		uint index;

		if((_dataTop + 1u) == _capacity) {
			throw new Exception("IndexedArray overload");
		}

		if(_availableIndexesTop) {
			//Take out the last available index on the list.
			_availableIndexesTop--;
			index = _availableIndexes[_availableIndexesTop];
		}
		else {
			//Or use a new id.
			index = _dataTop;
		}

		//Add the value to the data stack.
		_dataTable[_dataTop] = value;
		_translationTable[index] = _dataTop;
		_reverseTranslationTable[_dataTop] = index;

		++_dataTop;

		return index;
	}

	void pop(uint index) {
		uint valueIndex = _translationTable[index];

		//Push the index on the available indexes stack.
		_availableIndexes[_availableIndexesTop] = index;
		_availableIndexesTop++;

		//Invalidate the index.
		_translationTable[index] = -1;

		//Take the top value on the stack and fill the gap.
		_dataTop--;
		if (valueIndex < _dataTop) {
			uint userIndex = _reverseTranslationTable[_dataTop];
			_dataTable[valueIndex] = _dataTable[_dataTop];
			_translationTable[userIndex] = valueIndex;
			_reverseTranslationTable[valueIndex] = userIndex;
		}
	}

	void reset() {
		_dataTop = 0u;
		_availableIndexesTop = 0u;
		_removeTop = 0u;
	}

	void markInternalForRemoval(uint index) {
		synchronized {
			_removeTable[_removeTop] = _reverseTranslationTable[index];
			_removeTop ++;
		}
	}

	void markForRemoval(uint index) {
		_removeTable[_removeTop] = index;
		_removeTop ++;
	}


	void sweepMarkedData() {
		for(uint i = 0u; i < _removeTop; i++) {
			pop(_removeTable[i]);
		}
		_removeTop = 0u;
	}

static if(_useParallelism) {
	int opApply(int delegate(ref T) dlg) {
		int result;

		foreach(i; parallel(iota(_dataTop))) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}
}
else {
	int opApply(int delegate(ref T) dlg) {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}
}

	int opApply(int delegate(const ref T) dlg) const {
		int result;

		foreach(i;  0u .. _dataTop) {
			result = dlg(_dataTable[i]);

			if(result)
				break;
		}

		return result;
	}

static if(_useParallelism) {
	int opApply(int delegate(ref T, uint) dlg) {
		int result;

		foreach(i; parallel(iota(_dataTop))) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}
}
else {
	int opApply(int delegate(ref T, uint) dlg) {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}
}

	int opApply(int delegate(const ref T, uint) dlg) const {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(_dataTable[i], i);

			if(result)
				break;
		}

		return result;
	}

	int opApply(int delegate(const Tuple!(const uint, const T)) dlg) const {
		int result;

		foreach(i; 0u .. _dataTop) {
			result = dlg(tuple!(const uint, const T)(_reverseTranslationTable[i], _dataTable[i]));

			if(result)
				break;
		}

		return result;
	}

	T opIndex(uint index) {
		return _dataTable[_translationTable[index]];
	}

    bool has(uint index) {
        if(index > _dataTop)
            return false;
        if(_translationTable[index] == -1)
            return false;
        return true;
    }

	/// Returns the first element in the list
	T first() {
		assert(_dataTop > 0);
		return _dataTable[0];
	}

	/// Returns the last element in the list
	T last() {
		assert(_dataTop > 0);
		return _dataTable[_dataTop - 1];
	}
}