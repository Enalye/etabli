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

module script.vm;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;

import core.indexedarray;
import script.primitive;
import script.compiler;

class Vm {
	enum Opcode {
		Kill, Yield, Task, AnonymousTask, DecreaseIntStack, DecreaseFloatStack, DecreaseStringStack,
		SetInt, SetFloat, SetString,
		GetInt, GetFloat, GetString,
		LoadInt, LoadFloat, LoadBool, LoadString,
		PushGlobalInt, PushGlobalFloat, PushGlobalString,
		PopGlobalInt, PopGlobalFloat, PopGlobalString,

		EqualInt, EqualAssignFloat, EqualString, NotEqualInt, NotEqualAssignFloat, NotEqualString,
		GreaterOrEqualInt, GreaterOrEqualAssignFloat,
		LesserOrEqualInt, LesserOrEqualAssignFloat,
		GreaterInt, GreaterAssignFloat,
		LesserInt, LesserAssignFloat,

		And, Or, Not,
		ConcatenateString,
		AddInt, AddFloat,
		SubstractInt, SubstractFloat,
		MultiplyInt, MultiplyFloat,
		DivideInt, DivideFloat,
		ModulusInt, ModulusFloat,
		MinusInt, MinusFloat,
		IncrementInt, IncrementFloat,
		DecrementInt, DecrementFloat,

		SetStack, Call, AnonymousCall, PrimitiveCall, Return,
		Jump, JumpEqual, JumpNotEqual
	}

	class Coroutine {
		int[256] ivalues;
		float[256] fvalues;
		dstring[256] svalues;
		uint[64] callStack;
		int[] istack;
		float[] fstack;
		dstring[] sstack;
		uint pc,
			valuesPos, //Local variables: Access with ivalues[valuesPos + variableIndex]
			stackPos;
	}

	uint[] opcodes;

	int[] iconsts;
	float[] fconsts;
	dstring[] sconsts;

	int[] iglobals;
	float[] fglobals;
	dstring[] sglobals;

	int[] iglobalStack;
	float[] fglobalStack;
	dstring[] sglobalStack;

	IndexedArray!(Coroutine, 256u) coroutines = new IndexedArray!(Coroutine, 256u)();

	this() {}

	this(Bytecode bytecode) {
		load(bytecode);
	}

	void dump() {
		writeln("\n----- VM DUMP ------");
		uint i;
		foreach(uint a; opcodes) {
			Opcode op = cast(Opcode)getInstruction(a);
			if(op >= Opcode.Jump && op <= Opcode.JumpNotEqual)
				writeln("[", i, "] ", cast(Opcode)getInstruction(a), " ", i + getSignedValue(a));
			else
				writeln("[", i, "] ", cast(Opcode)getInstruction(a), " ", getValue(a));
			i++;
		}
	}

	void load(Bytecode bytecode) {
		iconsts = bytecode.iconsts;
		fconsts = bytecode.fconsts;
		sconsts = bytecode.sconsts;
		opcodes = bytecode.opcodes;

		coroutines.push(new Coroutine());
		//dump();

		if(opcodes.length)
			run();
	}

	void run() {
		coroutinesLabel: for(uint index = 0u; index < coroutines.length; index ++) {
			Coroutine coro = coroutines.data[index];
			for(;;) {
				uint opcode = opcodes[coro.pc];
				switch (getInstruction(opcode)) with(Opcode) {
				case Task:
					Coroutine newCoro = new Coroutine;
					newCoro.pc = getValue(opcode);
					coroutines.push(newCoro);
					coro.pc ++;
					break;
				case AnonymousTask:
					Coroutine newCoro = new Coroutine;
					newCoro.pc = coro.istack[$ - 1];
					coro.istack.length --;
					coroutines.push(newCoro);
					coro.pc ++;
					break;
				case Kill:
					coroutines.markInternalForRemoval(index);
					continue coroutinesLabel;
				case Yield:
					coro.pc ++;
					continue coroutinesLabel;
				case DecreaseIntStack:
					coro.istack.length -= getValue(opcode);
					coro.pc ++;
					break;
				case DecreaseFloatStack:
					coro.fstack.length -= getValue(opcode);
					coro.pc ++;
					break;
				case DecreaseStringStack:
					coro.sstack.length -= getValue(opcode);
					coro.pc ++;
					break;
				case SetInt:
					coro.ivalues[coro.valuesPos + getValue(opcode)] = coro.istack[$ - 1];
					coro.pc ++;
					break;
				case SetFloat:
					coro.fvalues[coro.valuesPos + getValue(opcode)] = coro.fstack[$ - 1];
					coro.pc ++;
					break;
				case SetString:
					coro.svalues[coro.valuesPos + getValue(opcode)] = coro.sstack[$ - 1];
					coro.pc ++;
					break;
				case GetInt:
					coro.istack ~= coro.ivalues[coro.valuesPos + getValue(opcode)];
					coro.pc ++;
					break;
				case GetFloat:
					coro.fstack ~= coro.fvalues[coro.valuesPos + getValue(opcode)];
					coro.pc ++;
					break;
				case GetString:
					coro.sstack ~= coro.svalues[coro.valuesPos + getValue(opcode)];
					coro.pc ++;
					break;
				case LoadInt:
					coro.istack ~= iconsts[getValue(opcode)];
					coro.pc ++;
					break;
				case LoadFloat:
					coro.fstack ~= fconsts[getValue(opcode)];
					coro.pc ++;
					break;
				case LoadBool:
					coro.istack ~= getValue(opcode);
					coro.pc ++;
					break;
				case LoadString:
					coro.sstack ~= sconsts[getValue(opcode)];
					coro.pc ++;
					break;
				case PushGlobalInt:
					uint nbParams = getValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						iglobalStack ~= coro.istack[($ - nbParams) + i];
					coro.istack.length -= nbParams;
					coro.pc ++;
					break;
				case PushGlobalFloat:
					uint nbParams = getValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						fglobalStack ~= coro.fstack[($ - nbParams) + i];
					coro.fstack.length -= nbParams;
					coro.pc ++;
					break;
				case PushGlobalString:
					uint nbParams = getValue(opcode);
					for(uint i = 0u; i < nbParams; i++)
						sglobalStack ~= coro.sstack[($ - nbParams) + i];
					coro.sstack.length -= nbParams;
					coro.pc ++;
					break;
				case PopGlobalInt:
					coro.istack ~= iglobalStack[$ - 1];
					iglobalStack.length --;
					coro.pc ++;
					break;
				case PopGlobalFloat:
					coro.fstack ~= fglobalStack[$ - 1];
					fglobalStack.length --;
					coro.pc ++;
					break;
				case PopGlobalString:
					coro.sstack ~= sglobalStack[$ - 1];
					sglobalStack.length --;
					coro.pc ++;
					break;
				case AddInt:
					coro.istack[$ - 2] += coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case AddFloat:
					coro.fstack[$ - 2] += coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case ConcatenateString:
					coro.sstack[$ - 2] ~= coro.sstack[$ - 1];
					coro.sstack.length --;
					coro.pc ++;
					break;
				case SubstractInt:
					coro.istack[$ - 2] -= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case SubstractFloat:
					coro.fstack[$ - 2] -= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case MultiplyInt:
					coro.istack[$ - 2] *= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case MultiplyFloat:
					coro.fstack[$ - 2] *= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case DivideInt:
					coro.istack[$ - 2] /= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case DivideFloat:
					coro.fstack[$ - 2] /= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;	
				case ModulusInt:
					coro.istack[$ - 2] %= coro.istack[$ - 1];
					coro.istack.length --;
					coro.pc ++;
					break;
				case ModulusFloat:
					coro.fstack[$ - 2] %= coro.fstack[$ - 1];
					coro.fstack.length --;
					coro.pc ++;
					break;
				case MinusInt:
					coro.istack[$ - 1] = -coro.istack[$ - 1];
					coro.pc ++;
					break;
				case MinusFloat:
					coro.fstack[$ - 1] = -coro.fstack[$ - 1];
					coro.pc ++;
					break;
				case IncrementInt:
					coro.istack[$ - 1] ++;
					coro.pc ++;
					break;
				case IncrementFloat:
					coro.fstack[$ - 1] += 1f;
					coro.pc ++;
					break;
				case DecrementInt:
					coro.istack[$ - 1] --;
					coro.pc ++;
					break;
				case DecrementFloat:
					coro.fstack[$ - 1] -= 1f;
					coro.pc ++;
					break;
				case Return:
					coro.stackPos -= 2;
					coro.pc = coro.callStack[coro.stackPos + 1u];
					coro.valuesPos -= coro.callStack[coro.stackPos];
					break;
				case SetStack:
					coro.callStack[coro.stackPos] = getValue(opcode);
					coro.pc ++;
					break;
				case Call:
					coro.valuesPos += coro.callStack[coro.stackPos];
					coro.callStack[coro.stackPos + 1u] = coro.pc + 1u;
					coro.stackPos += 2;
					coro.pc = getValue(opcode);
					break;
				case AnonymousCall:
					coro.valuesPos += coro.callStack[coro.stackPos];
					coro.callStack[coro.stackPos + 1u] = coro.pc + 1u;
					coro.stackPos += 2;
					coro.pc = coro.istack[$ - 1];
					coro.istack.length --;
					break;
				case PrimitiveCall:
					primitives[getValue(opcode)].callback(coro);
					coro.pc ++;
					break;
				case Jump:
					coro.pc += getSignedValue(opcode);
					break;
				case JumpEqual:
					if(coro.istack[$ - 1])
						coro.pc ++;
					else
						coro.pc += getSignedValue(opcode);
					coro.istack.length --;
					break;
				case JumpNotEqual:
					if(coro.istack[$ - 1])
						coro.pc += getSignedValue(opcode);
					else
						coro.pc ++;
					coro.istack.length --;
					break;
				default:
					throw new Exception("Invalid instruction");
				}
			}
		}
		coroutines.sweepMarkedData();

		if(coroutines.length)
			goto coroutinesLabel;
	}

	void call() {
	}

	pure uint getValue(uint opcode) {
		return (opcode >> 8u) & 0xffffff;
	}

	pure int getSignedValue(uint opcode) {
		return (cast(int)((opcode >> 8u) & 0xffffff)) - 0x800000;
	}

	pure uint getInstruction(uint opcode) {
		return opcode & 0xff;
	}

	pure uint makeOpcode(uint instr, uint value1, uint value2) {
		return ((value2 << 16u) & 0xffff0000) | ((value1 << 8u) & 0xff00) | (instr & 0xff);
	}
}