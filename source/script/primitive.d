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

module script.primitive;

import std.exception;
import std.conv;
import std.stdio;

import script.parser;
import script.vm;

class Primitive {
	void function(Vm.Coroutine) callback;
	VariableType[] signature;
	VariableType returnType;
	dstring name, mangledName;
	uint index;
}

Primitive[] primitives;
bool isLoaded = false;

void bindPrimitive(void function(Vm.Coroutine) callback, dstring name, VariableType returnType, VariableType[] signature) {
	Primitive primitive = new Primitive;
	primitive.callback = callback;
	primitive.signature = signature;
	primitive.returnType = returnType;
	primitive.name = name;
	primitive.mangledName = mangleName(name, signature);
	primitive.index = cast(uint)primitives.length;
	primitives ~= primitive;
	//writeln("Mangled name: ", primitive.mangledName);
}

bool isPrimitiveDeclared(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return true;
	}
	return false;
}

Primitive getPrimitive(dstring mangledName) {
	foreach(primitive; primitives) {
		if(primitive.mangledName == mangledName)
			return primitive;
	}
	throw new Exception("Undeclared primitive " ~ to!string(mangledName));
}

void loadPrimitives() {
	bindPrimitive(&prints, "print", VariableType.VoidType, [VariableType.StringType]);
	bindPrimitive(&printi, "print", VariableType.VoidType, [VariableType.IntType]);
	bindPrimitive(&printf, "print", VariableType.VoidType, [VariableType.FloatType]);
	bindPrimitive(&printa, "print", VariableType.VoidType, [VariableType.AnyType]);
	bindPrimitive(&toStringi, "to_string", VariableType.StringType, [VariableType.IntType]);
	bindPrimitive(&toStringf, "to_string", VariableType.StringType, [VariableType.FloatType]);
	bindPrimitive(&toInta, "to_int", VariableType.IntType, [VariableType.AnyType]);
	bindPrimitive(&toAnyi, "to_any", VariableType.AnyType, [VariableType.IntType]);
	isLoaded = true;
}

void prints(Vm.Coroutine coro) {
	writeln(coro.sstack[$ - 1]);
	coro.sstack.length --;
}

void printi(Vm.Coroutine coro) {
	writeln(coro.istack[$ - 1]);
	coro.sstack.length --;
}

void printf(Vm.Coroutine coro) {
	writeln(coro.fstack[$ - 1]);
	coro.sstack.length --;
}

void printa(Vm.Coroutine coro) {
	writeln(coro.astack[$ - 1].getString());
	coro.astack.length --;
}

void toStringi(Vm.Coroutine coro) {
	coro.sstack ~= to!dstring(coro.istack[$ - 1]);
	coro.istack.length --;
}

void toStringf(Vm.Coroutine coro) {
	coro.sstack ~= to!dstring(coro.fstack[$ - 1]);
	coro.fstack.length --;
}

void toInta(Vm.Coroutine coro) {
	coro.istack ~= (coro.astack[$ - 1]).getInteger();
	coro.astack.length --;
}

void toAnyi(Vm.Coroutine coro) {
	Vm.AnyValue value;
	value.setInteger(coro.istack[$ - 1]);
	coro.astack ~= value;
	coro.istack.length --;
}