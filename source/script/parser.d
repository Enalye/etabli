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

module script.parser;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.math;
import std.file;
import std.meta;

import script.vm;
import script.lexer;
import script.primitive;

enum VariableType {
	VoidType, IntType, FloatType, BoolType, StringType,
	ArrayType, ObjectType,/* AnyType,*/ FunctionType, TaskType
}

struct Instruction {
	Vm.Opcode opcode;
	uint value;
}

class Variable {
	VariableType type;
	uint index;
	bool isGlobal;
}

class Function {
	Variable[dstring] localVariables;
	Instruction[] instructions;
	uint stackSize, index;

	dstring name;
	VariableType[] signature;
	VariableType returnType;
	bool isTask, isAnonymous;

	FunctionCall[] functionCalls;
	Function anonParent;
	uint position, anonReference, anonIndex;

	uint nbStringParameters, nbIntegerParameters, nbFloatParameters;
}

class FunctionCall {
	dstring mangledName;
	uint position;
	Function caller, functionToCall;
	VariableType expectedType;
}

dstring mangleName(dstring name, VariableType[] signature) {
	dstring mangledName = name;

	foreach(type; signature) {
		mangledName ~= "$";

		final switch(type) with(VariableType) {
		case VoidType:
			mangledName ~= "v";
			break;
		case IntType:
			mangledName ~= "i";
			break;
		case FloatType:
			mangledName ~= "r";
			break;
		case BoolType:
			mangledName ~= "b";
			break;
		case StringType:
			mangledName ~= "s";
			break;
		case ArrayType:
			mangledName ~= "n";
			break;
		case ObjectType:
			mangledName ~= "o";
			break;
		/*case AnyType:
			mangledName ~= "a";
			break;*/
		case FunctionType:
			mangledName ~= "f";
			break;
		case TaskType:
			mangledName ~= "t";
			break;
		}
	}
	return mangledName;
}

class Parser {
	int[] iconsts;
	float[] fconsts;
	dstring[] sconsts;

	uint scopeLevel;

	Variable[dstring] globalVariables;
	Function[dstring] functions;
	Function[] anonymousFunctions;

	uint current;
	Function currentFunction;
	Function[] functionStack;
	FunctionCall[] functionCalls;

	uint[][] breaksJumps;
	uint[][] continuesJumps;
	uint[] continuesDestinations;

	Lexeme[] lexemes;

	void reset() {
		current = 0u;
	}

	void advance() {
		if(current < lexemes.length)
			current ++;
	}

	bool checkAdvance() {
		if(isEnd())
			return false;
		
		advance();
		return true;
	}

	void openBlock() {
		scopeLevel ++;
	}

	void closeBlock() {
		scopeLevel --;
	}

	bool isEnd(int offset = 0) {
		return (current + offset) >= cast(uint)lexemes.length;
	}

	Lexeme get(int offset = 0) {
		uint position = current + offset;
		if(position < 0 || position >= cast(uint)lexemes.length) {
			logError("Unexpected end of file");
		}
		return lexemes[position];
	}

	uint registerIntConstant(int value) {
		foreach(uint index, int iconst; iconsts) {
			if(iconst == value)
				return index;
		}
		iconsts ~= value;
		return cast(uint)iconsts.length - 1;
	}

	uint registerFloatConstant(float value) {
		foreach(uint index, float fconst; fconsts) {
			if(fconst == value)
				return index;
		}
		fconsts ~= value;
		return cast(uint)fconsts.length - 1;
	}

	uint registerStringConstant(dstring value) {
		foreach(uint index, dstring sconst; sconsts) {
			if(sconst == value)
				return index;
		}
		sconsts ~= value;
		return cast(uint)sconsts.length - 1;
	}

	Variable registerLocalVariable(dstring name, VariableType type) {
		//To do: check if declared globally

		//Check if declared locally.
		auto previousVariable = (name in currentFunction.localVariables);
		if(previousVariable !is null)
			logError("Multiple declaration", "The local variable \'" ~ to!string(name) ~ "\' is already declared.");

		Variable variable = new Variable;
		variable.index = cast(uint)currentFunction.localVariables.length;
		variable.isGlobal = false;
		variable.type = type;
		currentFunction.localVariables[name] = variable;

		return variable;
	}

	void beginFunction(dstring name, VariableType[] signature, dstring[] inputVariables, bool isTask, VariableType returnType = VariableType.VoidType) {
		dstring mangledName = mangleName(name, signature);

		auto func = mangledName in functions;
		if(func is null)
			logError("Undeclared function", "The function \'" ~ to!string(name) ~ "\' is not declared.");

		functionStack ~= currentFunction;
		currentFunction = *func;
	}

	void preBeginFunction(dstring name, VariableType[] signature, dstring[] inputVariables, bool isTask, VariableType returnType = VariableType.VoidType, bool isAnonymous = false) {
		Function func = new Function;
		func.isTask = isTask;
		func.signature = signature;
		func.returnType = returnType;

		if(isAnonymous) {
			func.index = cast(uint)anonymousFunctions.length;
			func.anonParent = currentFunction;
			func.anonReference = cast(uint)currentFunction.instructions.length;
			func.name = currentFunction.name ~ "@anon"d ~ to!dstring(func.index);
			anonymousFunctions ~= func;

			//Is replaced by the addr of the function later (see solveFunctionCalls).
			addInstruction(Vm.Opcode.SetInt, 0u);

			//Reserve constant for the function's address.
			func.anonIndex = cast(uint)iconsts.length;
			iconsts ~= 0u;
		}
		else {
			func.index = cast(uint)functions.length;
			func.name = name;

			dstring mangledName = mangleName(name, signature);
			auto previousFunc = (mangledName in functions);
			if(previousFunc !is null)
				logError("Multiple declaration", "The function \'" ~ to!string(name) ~ "\' is already declared.");
		
			functions[mangledName] = func;	
		}

		functionStack ~= currentFunction;
		currentFunction = func;
		addInstruction(Vm.Opcode.SetStack, 0u);

		foreach_reverse(size_t i, inputVariable; inputVariables) {
			final switch(signature[i]) with(VariableType) {
			case VoidType:
				logError("Invalid type", "Void is not a valid parameter type");
				break;
			case IntType:
			case BoolType:
			case ObjectType:
			case FunctionType:
			case TaskType:
				func.nbIntegerParameters ++;
				if(func.isTask)
					addInstruction(Vm.Opcode.PopGlobalInt, 0u);
				break;
			case FloatType:
				func.nbFloatParameters ++;
				if(func.isTask)
					addInstruction(Vm.Opcode.PopGlobalFloat, 0u);
				break;
			case StringType:
				func.nbStringParameters ++;
				if(func.isTask)
					addInstruction(Vm.Opcode.PopGlobalString, 0u);
				break;
			case ArrayType:
				logError("Invalid type", "Array parameters are not yet supported");
				break;
			}

			Variable newVar = new Variable;
			newVar.type = signature[i];
			newVar.index = cast(uint)i;
			newVar.isGlobal = false;
			func.localVariables[inputVariable] = newVar;
			addSetInstruction(newVar);
		}

		if(func.nbIntegerParameters > 0u)
			addInstruction(Vm.Opcode.DecreaseIntStack, func.nbIntegerParameters);
		if(func.nbFloatParameters > 0u)
			addInstruction(Vm.Opcode.DecreaseFloatStack, func.nbFloatParameters);
		if(func.nbStringParameters > 0u)
			addInstruction(Vm.Opcode.DecreaseStringStack, func.nbStringParameters);
	}

	void endFunction() {
		setInstruction(Vm.Opcode.SetStack, 0u, cast(uint)currentFunction.localVariables.length);
		if(!functionStack.length)
			logError("Missing symbol", "A \'}\' is missing, causing a mismatch");
		currentFunction = functionStack[$ - 1];
	}

	void preEndFunction() {
		if(!functionStack.length)
			logError("Missing symbol", "A \'}\' is missing, causing a mismatch");
		currentFunction = functionStack[$ - 1];
	}

	Function* getFunction(dstring name) {
		auto func = (name in functions);
		if(func is null)
			logError("Undeclared function", "The function \'" ~ to!string(name) ~ "\' is not declared");
		return func;
	}

	Variable getVariable(dstring name) {
		auto var = (name in currentFunction.localVariables);
		if(var is null)
			logError("Undeclared variable", "The variable \'" ~ to!string(name) ~ "\' is not declared");
		return *var;
	}

	void addIntConstant(int value) {
		addInstruction(Vm.Opcode.LoadInt, registerIntConstant(value));
	}

	void addFloatConstant(float value) {
		addInstruction(Vm.Opcode.LoadFloat, registerFloatConstant(value));
	}

	void addBoolConstant(bool value) {
		addInstruction(Vm.Opcode.LoadBool, value);
	}

	void addStringConstant(dstring value) {
		addInstruction(Vm.Opcode.LoadString, registerStringConstant(value));
	}

	void addInstruction(Vm.Opcode opcode, int value = 0, bool isSigned = false) {
		if(currentFunction is null)
			logError("Not in function", "The expression is located outside of a function or task, which is forbidden");

		Instruction instruction;
		instruction.opcode = opcode;
		if(isSigned) {
			if((value >= 0x800000) || (-value >= 0x800000))
				logError("Internal failure", "An opcode\'s signed value is exceeding limits");		
			instruction.value = value + 0x800000;
		}
		else
			instruction.value = value;
		currentFunction.instructions ~= instruction;
	}

	void setInstruction(Vm.Opcode opcode, uint index, int value = 0u, bool isSigned = false) {
		if(currentFunction is null)
			logError("Not in function", "The expression is located outside of a function or task, which is forbidden");

		if(index >= currentFunction.instructions.length)
			logError("Internal failure", "An instruction's index is exeeding the function size");

		Instruction instruction;
		instruction.opcode = opcode;
		if(isSigned) {
			if((value >= 0x800000) || (-value >= 0x800000))
				logError("Internal failure", "An opcode\'s signed value is exceeding limits");				
			instruction.value = value + 0x800000;
		}
		else
			instruction.value = value;
		currentFunction.instructions[index] = instruction;
	}

	void addOperator(LexemeType lexType, VariableType varType) {
		switch(varType) with(VariableType) {
		case BoolType:
		case IntType:
			switch(lexType) with(LexemeType) {
			case Add:
				addInstruction(Vm.Opcode.AddInt);
				break;
			case Substract:
				addInstruction(Vm.Opcode.SubstractInt);
				break;
			case Multiply:
				addInstruction(Vm.Opcode.MultiplyInt);
				break;
			case Divide:
				addInstruction(Vm.Opcode.DivideInt);
				break;
			case Minus:
				addInstruction(Vm.Opcode.MinusInt);
				break;
			case Plus:
				break;
			case Increment:
				addInstruction(Vm.Opcode.IncrementInt);
				break;
			case Decrement:
				addInstruction(Vm.Opcode.DecrementInt);
				break;
			default:
				logError("Unknown operator", "An unknown operator \'" ~ to!string(lexType) ~ "\' is being used");
			}
			break;
		case FloatType:
			switch(lexType) with(LexemeType) {
			case Add:
				addInstruction(Vm.Opcode.AddFloat);
				break;
			case Substract:
				addInstruction(Vm.Opcode.SubstractFloat);
				break;
			case Multiply:
				addInstruction(Vm.Opcode.MultiplyFloat);
				break;
			case Divide:
				addInstruction(Vm.Opcode.DivideFloat);
				break;
			case Minus:
				addInstruction(Vm.Opcode.MinusInt);
				break;
			case Plus:
				break;
			case Increment:
				addInstruction(Vm.Opcode.IncrementFloat);
				break;
			case Decrement:
				addInstruction(Vm.Opcode.DecrementFloat);
				break;
			default:
				logError("Unknown operator", "An unknown operator \'" ~ to!string(lexType) ~ "\' is being used");
			}
			break;
		case StringType:
			switch(lexType) with(LexemeType) {
			case Concatenate:
				addInstruction(Vm.Opcode.ConcatenateString);
				break;
			default:
				logError("Unknown operator", "An unknown operator \'" ~ to!string(lexType) ~ "\' is being used");
			}
			break;
		default:
			logError("Invalid type", "Cannot use a \'" ~ to!string(varType) ~ "\' type in this expression");
		}
	}

	void addSetInstruction(Variable variable) {
		if(variable.isGlobal) {
			logError("Internal failure", "Global variable not implemented");
		}
		else {
			switch(variable.type) with(VariableType) {
			case BoolType:
			case ObjectType:
			case IntType:
			case FunctionType:
			case TaskType:
				addInstruction(Vm.Opcode.SetInt, variable.index);
				break;
			case FloatType:
				addInstruction(Vm.Opcode.SetFloat, variable.index);
				break;
			case StringType:
				addInstruction(Vm.Opcode.SetString, variable.index);
				break;
			default:
				logError("Invalid type", "Cannot assign to a \'" ~ to!string(variable.type) ~ "\' type");
			}
		}
	}

	void addGetInstruction(Variable variable) {
		if(variable.isGlobal) {
			logError("Internal failure", "Global variable not implemented");
		}
		else {
			switch(variable.type) with(VariableType) {
			case BoolType:
			case ObjectType:
			case IntType:
			case FunctionType:
			case TaskType:
				addInstruction(Vm.Opcode.GetInt, variable.index);
				break;
			case FloatType:
				addInstruction(Vm.Opcode.GetFloat, variable.index);
				break;
			case StringType:
				addInstruction(Vm.Opcode.GetString, variable.index);
				break;
			default:
				logError("Invalid type", "Cannot fetch from a \'" ~ to!string(variable.type) ~ "\' type");
			}
		}
	}

	VariableType addFunctionCall(dstring mangledName) {
		FunctionCall call = new FunctionCall;
		call.mangledName = mangledName;
		call.caller = currentFunction;
		functionCalls ~= call;
		currentFunction.functionCalls ~= call;

		auto func = (call.mangledName in functions);
		if(func !is null) {
			call.functionToCall = *func;
			if(func.isTask) {
				if(func.nbStringParameters > 0)
					addInstruction(Vm.Opcode.PushGlobalString, func.nbStringParameters);
				if(func.nbFloatParameters > 0)
					addInstruction(Vm.Opcode.PushGlobalFloat, func.nbFloatParameters);
				if(func.nbIntegerParameters > 0)
					addInstruction(Vm.Opcode.PushGlobalInt, func.nbIntegerParameters);
			}

			call.position = cast(uint)currentFunction.instructions.length;
			addInstruction(Vm.Opcode.Call, 0);

			return func.returnType;
		}
		else
			logError("Undeclared function", "The function \'" ~ to!string(call.mangledName) ~ "\' is not declared");

		return VariableType.VoidType;
	}

	void setOpcode(ref uint[] opcodes, uint position, Vm.Opcode opcode, uint value = 0u, bool isSigned = false) {
		Instruction instruction;
		instruction.opcode = opcode;
		if(isSigned) {
			if((value >= 0x800000) || (-value >= 0x800000))
				logError("Internal failure", "An opcode\'s signed value is exceeding limits");	
			instruction.value = value + 0x800000;
		}
		else
			instruction.value = value;

		uint makeOpcode(uint instr, uint value) {
			return ((value << 8u) & 0xffffff00) | (instr & 0xff);
		}
		opcodes[position] = makeOpcode(cast(uint)instruction.opcode, instruction.value);
	}

	void solveFunctionCalls(ref uint[] opcodes) {
		foreach(FunctionCall call; functionCalls) {
			auto func = (call.mangledName in functions);
			if(func !is null) {
				if(func.isTask)
					setOpcode(opcodes, call.position, Vm.Opcode.Task, func.position);
				else
					setOpcode(opcodes, call.position, Vm.Opcode.Call, func.position);
			}
			else
				logError("Undeclared function", "The function \'" ~ to!string(call.mangledName) ~ "\' is not declared");
		}

		foreach(func; anonymousFunctions) {
			iconsts[func.anonIndex] = func.position;
			setOpcode(opcodes, func.anonParent.position + func.anonReference, Vm.Opcode.LoadInt, func.anonIndex);
		}
	}

	void dump() {
		writeln("Code Generated:\n");
		foreach(uint i, int ivalue; iconsts)
			writeln(".iconst " ~ to!string(ivalue) ~ "\t;" ~ to!string(i));

		foreach(uint i, float fvalue; fconsts)
			writeln(".fconst " ~ to!string(fvalue) ~ "\t;" ~ to!string(i));

		foreach(uint i, dstring svalue; sconsts)
			writeln(".sconst " ~ to!string(svalue) ~ "\t;" ~ to!string(i));

		foreach(dstring funcName, Function func; functions) {
			if(func.isTask)
				writeln("\n.task " ~ funcName);
			else
				writeln("\n.function " ~ funcName);

			foreach(uint i, Instruction instruction; func.instructions) {
				writeln("[" ~ to!string(i) ~ "] " ~ to!string(instruction.opcode) ~ " " ~ to!string(instruction.value));
			}
		}
	}

	void parseScript(Lexer lexer) {
		preParseScript(lexer);
		reset();

		lexemes = lexer.lexemes;

		while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case Main:
				parseMainDeclaration();
				break;
			case TaskType:
				parseTaskDeclaration();
				break;
			case FunctionType:
				parseFunctionDeclaration();
				break;
			default:
				logError("Invalid type", "The type should be either main, func or task");
			}
		}
	}

	void preParseScript(Lexer lexer) {
		lexemes = lexer.lexemes;

		while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case Main:
				preParseMainDeclaration();
				break;
			case TaskType:
				preParseTaskDeclaration();
				break;
			case FunctionType:
				preParseFunctionDeclaration();
				break;
			default:
				logError("Invalid type", "The type should be either main, func or task");
			}
		}
	}

	VariableType[] parseSignature(ref dstring[] inputVariables) {
		VariableType[] signature;

		checkAdvance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A signature should always start with \'(\'");

		for(;;) {
			checkAdvance();
			Lexeme lex = get();

			if(lex.type == LexemeType.RightParenthesis)
				break;
			else if(!lex.isType)
				logError("Excepted type", "A valid type is expected");

			switch(lex.type) with(LexemeType) {
			case IntType:
				signature ~= VariableType.IntType;
				break;
			case FloatType:
				signature ~= VariableType.FloatType;
				break;
			case BoolType:
				signature ~= VariableType.BoolType;
				break;
			case StringType:
				signature ~= VariableType.StringType;
				break;
			case ObjectType:
				signature ~= VariableType.ObjectType;
				break;
			case FunctionType:
				signature ~= VariableType.FunctionType;
				break;
			case TaskType:
				signature ~= VariableType.TaskType;
				break;
			default:
				logError("Invalid type", "Cannot call a function with a parameter of type \'" ~ to!string(lex.type) ~ "\'");
			}

			checkAdvance();
			lex = get();
			if(get().type != LexemeType.Identifier)
				logError("Missing identifier", "Expected a name such as \'foo\'");
			inputVariables ~= lex.svalue;

			checkAdvance();
			lex = get();
			if(lex.type == LexemeType.RightParenthesis)
				break;
			else if(get().type != LexemeType.LeftCurlyBrace)
				logError("Missing symbol", "Either a \',\' or a \')\' is expected");
		}

		checkAdvance();

		return signature;
	}

	void parseMainDeclaration() {
		checkAdvance();
		beginFunction("main", [], [], false);
		parseBlock();
		addInstruction(Vm.Opcode.Kill);
		endFunction();
	}

	void preParseMainDeclaration() {
		checkAdvance();
		preBeginFunction("main", [], [], false);
		skipBlock();
		preEndFunction();
	}

	void parseTaskDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
		dstring[] inputs;
		VariableType[] signature = parseSignature(inputs);
		beginFunction(name, signature, inputs, true);
		parseBlock();
		addInstruction(Vm.Opcode.Kill);
		endFunction();
	}

	void preParseTaskDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
		dstring[] inputs;
		VariableType[] signature = parseSignature(inputs);
		preBeginFunction(name, signature, inputs, true);
		skipBlock();
		preEndFunction();
	}

	void parseFunctionDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
		dstring[] inputs;
		VariableType[] signature = parseSignature(inputs);

		if(get().isType)
			checkAdvance();

		beginFunction(name, signature, inputs, false);
		parseBlock();
		addInstruction(Vm.Opcode.Return);
		endFunction();
	}

	void preParseFunctionDeclaration() {
		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");
		dstring name = get().svalue;
		dstring[] inputs;
		VariableType[] signature = parseSignature(inputs);

		//Return Type.
		VariableType returnType = VariableType.VoidType;
		if(get().isType) {
			switch(get().type) with(LexemeType) {
			case IntType:
				returnType = VariableType.IntType;
				break;
			case FloatType:
				returnType = VariableType.FloatType;
				break;
			case BoolType:
				returnType = VariableType.BoolType;
				break;
			case StringType:
				returnType = VariableType.StringType;
				break;
			case ObjectType:
				returnType = VariableType.ObjectType;
				break;
			case FunctionType:
				returnType = VariableType.FunctionType;
				break;
			case TaskType:
				returnType = VariableType.TaskType;
				break;
			default:
				logError("Invalid type", "A " ~ to!string(get().type) ~ " is not a valid return type");
			}

			checkAdvance();
		}

		preBeginFunction(name, signature, inputs, false, returnType);
		skipBlock();
		preEndFunction();
	}

	void parseAnonymousFunction(bool isTask) {
		dstring[] inputs;
		VariableType returnType = VariableType.VoidType;
		VariableType[] signature = parseSignature(inputs);

		if(!isTask) {
			//Return Type.
			if(get().isType) {
				switch(get().type) with(LexemeType) {
				case IntType:
					returnType = VariableType.IntType;
					break;
				case FloatType:
					returnType = VariableType.FloatType;
					break;
				case BoolType:
					returnType = VariableType.BoolType;
					break;
				case StringType:
					returnType = VariableType.StringType;
					break;
				case ObjectType:
					returnType = VariableType.ObjectType;
					break;
				case FunctionType:
					returnType = VariableType.FunctionType;
					break;
				case TaskType:
					returnType = VariableType.TaskType;
					break;
				default:
					logError("Invalid type", "A " ~ to!string(get().type) ~ " is not a valid return type");
				}

				checkAdvance();
			}
		}

		preBeginFunction("$anon"d, signature, inputs, isTask, returnType, true);
		parseBlock();
		addInstruction(Vm.Opcode.Return);
		endFunction();
	}

	void parseBlock() {
		if(get().type != LexemeType.LeftCurlyBrace)
			logError("Missing symbol", "A block should always start with \'{\'");
		openBlock();

		if(!checkAdvance())
			logError("Unexpected end of file");

		whileLoop: while(!isEnd()) {
			Lexeme lex = get();
			if(lex.isType)
				parseLocalDeclaration();
			else {
				switch(lex.type) with(LexemeType) {
				case Semicolon:
					advance();
					break;
				case RightCurlyBrace:
					break whileLoop;
				case If:
					parseIfStatement();
					break;
				case While:
					parseWhileStatement();
					break;
				case Do:
					parseDoWhileStatement();
					break;
				case Return:
					parseReturnStatement();
					break;
				case Yield:
					addInstruction(Vm.Opcode.Yield, 0u);
					break;
				case Continue:
					parseContinue();
					break;
				case Break:
					parseBreak();
					break;
				case VoidType: .. case TaskType:
					parseLocalDeclaration();
					break;
				default:
					parseExpression();
					break;
				}
			}
		}

		if(get().type != LexemeType.RightCurlyBrace)
			logError("Missing symbol", "A block should always end with \'}\'");
		closeBlock();
		checkAdvance();
	}

	void skipBlock() {
		if(get().type != LexemeType.LeftCurlyBrace)
			logError("Missing symbol", "A block should always start with \'{\'");
		openBlock();

		if(!checkAdvance())
			logError("Unexpected end of file");

		whileLoop: while(!isEnd()) {
			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case RightCurlyBrace:
				break whileLoop;
			case LeftCurlyBrace:
				skipBlock();
				break;
			default:
				checkAdvance();
				break;
			}
		}
		
		if(get().type != LexemeType.RightCurlyBrace)
			logError("Missing symbol", "A block should always end with \'}\'");
		closeBlock();
		checkAdvance();
	}

	//Break
	void openBreakableSection() {
		breaksJumps ~= [null];
	}

	void closeBreakableSection() {
		if(!breaksJumps.length)
			logError("Breakable section error", "A breakable section had a mismatch");

		uint[] continues = breaksJumps[$ - 1];
		breaksJumps.length --;

		foreach(position; continues)
			setInstruction(Vm.Opcode.Jump, position, cast(int)(position - currentFunction.instructions.length), true);
	}

	void parseBreak() {
		if(!breaksJumps.length)
			logError("Non breakable statement", "The break statement is not inside a breakable statement");

		breaksJumps[$ - 1] ~= cast(uint)currentFunction.instructions.length;
		addInstruction(Vm.Opcode.Jump);
		advance();
	}

	//Continue
	void openContinuableSection() {
		continuesJumps ~= [null];
	}

	void closeContinuableSection() {
		if(!continuesJumps.length)
			logError("Continuable section error", "A continuable section had a mismatch");

		uint[] continues = continuesJumps[$ - 1];
		uint destination = continuesDestinations[$ - 1];
		continuesJumps.length --;
		continuesDestinations.length --;

		foreach(position; continues)
			setInstruction(Vm.Opcode.Jump, position, cast(int)(position - destination), true);
	}

	void setContinuableSectionDestination() {
		continuesDestinations ~= cast(uint)currentFunction.instructions.length;
	}

	void parseContinue() {
		if(!continuesJumps.length)
			logError("Non continuable statement", "The continue statement is not inside a continuable statement");

		continuesJumps[$ - 1] ~= cast(uint)currentFunction.instructions.length;
		addInstruction(Vm.Opcode.Jump);
		advance();
	}

	//Type Identifier [= EXPRESSION] ;
	void parseLocalDeclaration() {
		Lexeme lexType = get();

		checkAdvance();
		if(get().type != LexemeType.Identifier)
			logError("Missing identifier", "Expected a name such as \'foo\'");

		dstring identifier = get().svalue;
		VariableType type = VariableType.VoidType;

		switch(lexType.type) with(LexemeType) {
		case IntType:
			type = VariableType.IntType;
			break;
		case FloatType:
			type = VariableType.FloatType;
			break;
		case BoolType:
			type = VariableType.BoolType;
			break;
		case StringType:
			type = VariableType.StringType;
			break;
		case FunctionType:
			type = VariableType.FunctionType;
			break;
		case TaskType:
			type = VariableType.TaskType;
			break;
		default:
			logError("Invalid type", "Cannot declare local variable of type " ~ to!string(lexType.type));
		}

		Variable variable = registerLocalVariable(identifier, type);
		
		checkAdvance();
		switch(get().type) with(LexemeType) {
		case Assign:
			checkAdvance();
			parseExpression(type);
			addSetInstruction(variable);
			break;
		case Semicolon:
			break;
		default:
			logError("Invalid symbol", "A declaration must either be terminated by a ; or assigned with =");
		}
	}

	void parseIfStatement() {
		advance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		advance();
		parseSubExpression();
		advance();

		uint jumpPosition = cast(uint)currentFunction.instructions.length;
		addInstruction(Vm.Opcode.JumpEqual); //Jumps to if(0).

		parseBlock(); //{ .. }

		//If(1){}, jumps out.
		uint[] exitJumps;
		exitJumps ~= cast(uint)currentFunction.instructions.length;
		addInstruction(Vm.Opcode.Jump);

		//If(0) destination.
		setInstruction(Vm.Opcode.JumpEqual, jumpPosition, cast(int)(currentFunction.instructions.length - jumpPosition), true);

		bool isElseIf;
		do {
			isElseIf = false;
			if(get().type == LexemeType.Else) {
				checkAdvance();
				if(get().type == LexemeType.If) {
					isElseIf = true;
					checkAdvance();
					if(get().type != LexemeType.LeftParenthesis)
						logError("Missing symbol", "A condition should always start with \'(\'");
					checkAdvance();

					parseSubExpression();

					jumpPosition = cast(uint)currentFunction.instructions.length;
					addInstruction(Vm.Opcode.JumpEqual); //Jumps to if(0).

					parseBlock(); //{ .. }

					//If(1){}, jumps out.
					exitJumps ~= cast(uint)currentFunction.instructions.length;
					addInstruction(Vm.Opcode.Jump);

					//If(0) destination.
					setInstruction(Vm.Opcode.JumpEqual, jumpPosition, cast(int)(currentFunction.instructions.length - jumpPosition), true);
				}
				else
					parseBlock();
			}
		}
		while(isElseIf);

		foreach(uint position; exitJumps)
			setInstruction(Vm.Opcode.Jump, position, cast(int)(currentFunction.instructions.length - position), true);
	}

	void parseWhileStatement() {
		advance();
		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		/* While is breakable and continuable. */
		openBreakableSection();
		openContinuableSection();

		/* Continue jump. */
		setContinuableSectionDestination();

		uint conditionPosition,
			blockPosition = cast(uint)currentFunction.instructions.length;

		advance();
		parseSubExpression();

		advance();
		conditionPosition = cast(uint)currentFunction.instructions.length;
		addInstruction(Vm.Opcode.JumpEqual);

		parseBlock();

		addInstruction(Vm.Opcode.Jump, cast(int)(blockPosition - currentFunction.instructions.length), true);
		setInstruction(Vm.Opcode.JumpEqual, conditionPosition, cast(int)(currentFunction.instructions.length - conditionPosition), true);

		/* While is breakable and continuable. */
		closeBreakableSection();
		closeContinuableSection();
	}

	void parseDoWhileStatement() {
		advance();

		/* While is breakable and continuable. */
		openBreakableSection();
		openContinuableSection();

		uint blockPosition = cast(uint)currentFunction.instructions.length;

		parseBlock();
		if(get().type != LexemeType.While)
			logError("Missing while", "A do-while statement expects the keyword while after \'}\'");
		advance();

		/* Continue jump. */
		setContinuableSectionDestination();

		if(get().type != LexemeType.LeftParenthesis)
			logError("Missing symbol", "A condition should always start with \'(\'");

		advance();
		parseSubExpression();
		advance();

		addInstruction(Vm.Opcode.JumpNotEqual, cast(int)(blockPosition - currentFunction.instructions.length), true);

		/* While is breakable and continuable. */
		closeBreakableSection();
		closeContinuableSection();
	}

	void parseReturnStatement() {
		checkAdvance();
		VariableType returnedType = parseSubExpression(false);
		if(returnedType != currentFunction.returnType)
			logError("Invalid return type", "The returned type \'" ~ to!string(returnedType) ~ "\' does not match the function definition \'" ~ to!string(currentFunction.returnType) ~ "\'");

		addInstruction(Vm.Opcode.Return);
	}

	uint getOperatorPriority(LexemeType type) {
		switch(type) with(LexemeType) {
			case Assign: .. case PowerAssign:
				return 1;
			case Or:
				return 2;
			case Xor:
				return 3;
			case And:
				return 4;
			case Equal: .. case NotEqual:
				return 5;
			case GreaterOrEqual: .. case Lesser:
				return 6;
			case Add: .. case Substract:
				return 7;
			case Multiply: .. case Modulo:
				return 8;
			case Power:
				return 9;
			case Not:
			case Plus:
			case Minus:
			case Increment:
			case Decrement:
				return 10;
			default:
				logError("Unknown priority", "The operator is not listed in the operator priority table");
				return 0;
		}
	}

	void parseExpression(VariableType variableType = VariableType.VoidType) {
		Variable[] lvalues;
		LexemeType[] operatorsStack;
		VariableType lastVariableType = variableType;
		bool isReturningValue = false,
			hasValue = false, hadValue = false, hasLValue = false, hadLValue = false,
			isRightUnaryOperator = true, isEndOfExpression = false;

		if(variableType != VariableType.VoidType)
			isReturningValue = true;

		do {
			if(hasValue && variableType != lastVariableType && lastVariableType != VariableType.VoidType)
				logError("Incompatible types", "Cannot convert \'" ~ to!string(lastVariableType) ~ "\' to \'" ~ to!string(variableType) ~ "\'");
			lastVariableType = variableType;

			isRightUnaryOperator = false;
			hadValue = hasValue;
			hasValue = false;

			hadLValue = hasLValue;
			hasLValue = false;

			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case Comma:
			case Semicolon:
			case RightParenthesis:
				isEndOfExpression = true;
				break;
			case LeftParenthesis:
				variableType = parseSubExpression();
				hasValue = true;
				break;
			case Integer:
				variableType = VariableType.IntType;
				addIntConstant(lex.ivalue);
				hasValue = true;
				checkAdvance();
				break;
			case Float:
				variableType = VariableType.FloatType;
				addFloatConstant(lex.fvalue);
				hasValue = true;
				checkAdvance();
				break;
			case Boolean:
				variableType = VariableType.BoolType;
				addBoolConstant(lex.bvalue);
				hasValue = true;
				checkAdvance();
				break;
			case String:
				variableType = VariableType.StringType;
				addStringConstant(lex.svalue);
				hasValue = true;
				checkAdvance();
				break;
			case FunctionType:
				variableType = VariableType.FunctionType;
				parseAnonymousFunction(false);
				hasValue = true;
				break;
			case TaskType:
				variableType = VariableType.TaskType;
				parseAnonymousFunction(true);
				hasValue = true;
				break;
			case Assign: .. case PowerAssign:
				if(!hadLValue)
					logError("Expression invalid", "Missing lvalue in expression");
				hadLValue = false;
				goto case Multiply;
			case Add:
				if(!hadValue)
					lex.type = LexemeType.Plus;
				goto case Multiply;
			case Substract:
				if(!hadValue)
					lex.type = LexemeType.Minus;
				goto case Multiply;
			case Increment: .. case Decrement:
				isRightUnaryOperator = true;
				goto case Multiply;
			case Multiply: .. case Xor:
				if(!hadValue && lex.type != LexemeType.Plus && lex.type != LexemeType.Minus && lex.type != LexemeType.Not)
					logError("Expected value", "A value is missing");

				while(operatorsStack.length && getOperatorPriority(operatorsStack[$ - 1]) > getOperatorPriority(lex.type)) {
					LexemeType operator = operatorsStack[$ - 1];
	
					switch(operator) with(LexemeType) {
					case Assign:
						addSetInstruction(lvalues[$ - 1]);
						lvalues.length --;
						break;
					case AddAssign: .. case PowerAssign:
						addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), variableType);
						addSetInstruction(lvalues[$ - 1]);
						lvalues.length --;
						break;
					case Increment: .. case Decrement:
						addOperator(operator, variableType);
						addSetInstruction(lvalues[$ - 1]);
						lvalues.length --;
						break;
					default:
						addOperator(operator, variableType);
						break;
					}
					
					operatorsStack.length --;
				}

				operatorsStack ~= lex.type;
				if(hadValue && isRightUnaryOperator) {
					hasValue = true;
					hadValue = false;
				}
				else
					hasValue = false;
				checkAdvance();
				break;
			case Identifier:
				Variable lvalue;
				variableType = parseIdentifier(lvalue);
				if(lvalue !is null) {
					hasLValue = true;
					lvalues ~= lvalue;
				}

				if(variableType != VariableType.VoidType)
					hasValue = true;
				break;
			default:
				logError("Unexpected symbol", "Invalid \'" ~ to!string(lex.type) ~ "\' symbol in the expression");
			}

			if(hasValue && hadValue)
				logError("Missing symbol", "The expression is not terminated by a \';\'");
		}
		while(!isEndOfExpression);

		if(operatorsStack.length) {
			if(!hadValue) {
				if(!isRightUnaryOperator)
					logError("Expected value", "A value is missing");
				else
					logError("Expected value", "A value is missing");
			}
		}

		while(operatorsStack.length) {
			LexemeType operator = operatorsStack[$ - 1];
	
			switch(operator) with(LexemeType) {
			case Assign:
				addSetInstruction(lvalues[$ - 1]);
				lvalues.length --;
				break;
			case AddAssign: .. case PowerAssign:
				addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), variableType);
				addSetInstruction(lvalues[$ - 1]);
				lvalues.length --;
				break;
			case Increment: .. case Decrement:
				addOperator(operator, variableType);
				addSetInstruction(lvalues[$ - 1]);
				lvalues.length --;
				break;
			default:
				addOperator(operator, variableType);
				break;
			}

			operatorsStack.length --;
		}

		if(variableType != VariableType.VoidType && !isReturningValue) {
			switch(variableType) with(VariableType) {
			case IntType:
			case BoolType:
			case ObjectType:
			case FunctionType:
			case TaskType:
				addInstruction(Vm.Opcode.DecreaseIntStack, 1u);
				break;
			case FloatType:
				addInstruction(Vm.Opcode.DecreaseFloatStack, 1u);
				break;
			case StringType:
				addInstruction(Vm.Opcode.DecreaseStringStack, 1u);
				break;
			default:
				break;
			}
		}
	}

	VariableType parseSubExpression(bool useParenthesis = true) {
		Variable[] lvalues;
		LexemeType[] operatorsStack;
		VariableType variableType = VariableType.VoidType, lastVariableType = VariableType.VoidType;
		bool hasValue = false, hadValue = false, hasLValue = false, hadLValue = false,
		isRightUnaryOperator = true, isEndOfExpression = false;

		do {
			if(hasValue && variableType != lastVariableType && lastVariableType != VariableType.VoidType)
				logError("Incompatible types", "Cannot convert \'" ~ to!string(lastVariableType) ~ "\' to \'" ~ to!string(variableType) ~ "\'");
			lastVariableType = variableType;

			isRightUnaryOperator = false;
			hadValue = hasValue;
			hasValue = false;

			hadLValue = hasLValue;
			hasLValue = false;

			Lexeme lex = get();
			switch(lex.type) with(LexemeType) {
			case Semicolon:
				if(useParenthesis)
					logError("Unexpected symbol", "A \';\' cannot exist inside this expression");
				else
					isEndOfExpression = true;
				break;
			case Comma:
				if(useParenthesis)
					isEndOfExpression = true;
				else
					logError("Unexpected symbol", "A \',\' cannot exist inside this expression");
				break;
			case RightParenthesis:
				if(useParenthesis)
					isEndOfExpression = true;
				else
					logError("Unexpected symbol", "A \')\' cannot exist inside this expression");
				break;
			case LeftParenthesis:
				variableType = parseSubExpression();
				hasValue = true;
				break;
			case Integer:
				variableType = VariableType.IntType;
				addIntConstant(lex.ivalue);
				hasValue = true;
				checkAdvance();
				break;
			case Float:
				variableType = VariableType.FloatType;
				addFloatConstant(lex.fvalue);
				hasValue = true;
				checkAdvance();
				break;
			case Boolean:
				variableType = VariableType.BoolType;
				addBoolConstant(lex.bvalue);
				hasValue = true;
				checkAdvance();
				break;
			case String:
				variableType = VariableType.StringType;
				addStringConstant(lex.svalue);
				hasValue = true;
				checkAdvance();
				break;
			case FunctionType:
				variableType = VariableType.FunctionType;
				parseAnonymousFunction(false);
				hasValue = true;
				break;
			case TaskType:
				variableType = VariableType.TaskType;
				parseAnonymousFunction(true);
				hasValue = true;
				break;
			case Assign: .. case PowerAssign:
				if(!hadLValue)
					logError("Expression invalid", "Missing lvalue in expression");
				hadLValue = false;
				goto case Multiply;
			case Add:
				if(!hadValue)
					lex.type = LexemeType.Plus;
				goto case Multiply;
			case Substract:
				if(!hadValue)
					lex.type = LexemeType.Minus;
				goto case Multiply;
			case Increment: .. case Decrement:
				isRightUnaryOperator = true;
				goto case Multiply;
			case Multiply: .. case Xor:
				if(!hadValue && lex.type != LexemeType.Plus && lex.type != LexemeType.Minus && lex.type != LexemeType.Not)
					logError("Expected value", "A value is missing");

				while(operatorsStack.length && getOperatorPriority(operatorsStack[$ - 1]) > getOperatorPriority(lex.type)) {
					LexemeType operator = operatorsStack[$ - 1];
	
					switch(operator) with(LexemeType) {
					case Assign:
						addSetInstruction(lvalues[$ - 1]);
						lvalues.length --;
						break;
					case AddAssign: .. case PowerAssign:
						addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), variableType);
						addSetInstruction(lvalues[$ - 1]);
						lvalues.length --;
						break;
					case Increment: .. case Decrement:
						addOperator(operator, variableType);
						addSetInstruction(lvalues[$ - 1]);
						lvalues.length --;
						break;
					default:
						addOperator(operator, variableType);
						break;
					}

					operatorsStack.length --;
				}

				operatorsStack ~= lex.type;
				if(hadValue && isRightUnaryOperator) {
					hasValue = true;
					hadValue = false;
				}
				else
					hasValue = false;
				checkAdvance();
				break;
			case Identifier:
				Variable lvalue;
				variableType = parseIdentifier(lvalue);

				if(lvalue !is null) {
					hasLValue = true;
					lvalues ~= lvalue;
				}

				if(variableType != VariableType.VoidType)
					hasValue = true;
				break;
			default:
				logError("Unexpected symbol", "Invalid \'" ~ to!string(lex.type) ~ "\' symbol in the expression");
			}

			if(hasValue && hadValue)
				logError("Missing symbol", "The expression is not terminated by a \';\'");
		}
		while(!isEndOfExpression);

		if(operatorsStack.length) {
			if(!hadValue) {
				if(!isRightUnaryOperator)
					logError("Expected value", "A value is missing");
				else
					logError("Expected value", "A value is missing");
			}
		}

		while(operatorsStack.length) {
			LexemeType operator = operatorsStack[$ - 1];
	
			switch(operator) with(LexemeType) {
			case Assign:
				addSetInstruction(lvalues[$ - 1]);
				lvalues.length --;
				break;
			case AddAssign: .. case PowerAssign:
				addOperator(operator - (LexemeType.AddAssign - LexemeType.Add), variableType);
				addSetInstruction(lvalues[$ - 1]);
				lvalues.length --;
				break;
			case Increment: .. case Decrement:
				addOperator(operator, variableType);
				addSetInstruction(lvalues[$ - 1]);
				lvalues.length --;
				break;
			default:
				addOperator(operator, variableType);
				break;
			}

			operatorsStack.length --;
		}

		return variableType;
	}

	//Parse an identifier or function call and return the deduced return type and lvalue.
	VariableType parseIdentifier(ref Variable variable) {
		VariableType returnType = VariableType.VoidType;
		Lexeme identifier = get();		
		bool isFunctionCall = false;

		advance();

		if(get().type == LexemeType.LeftParenthesis)
			isFunctionCall = true;

		if(isFunctionCall) {
			VariableType[] signature;
			advance();

			if(get().type != LexemeType.RightParenthesis) {
				for(;;) {
					signature ~= parseSubExpression();
					if(get().type == LexemeType.RightParenthesis)
						break;
					advance();
				}
			}
			checkAdvance();

			auto var = (identifier.svalue in currentFunction.localVariables);
			if(var !is null) {
				//Anonymous call.
				bool hasAnonFunc = false;
				addGetInstruction(*var);
				returnType = VariableType.VoidType; //TODO: Infere the right return type.

				if(var.type == VariableType.FunctionType)
					addInstruction(Vm.Opcode.AnonymousCall, 0u);
				else if(var.type == VariableType.TaskType)
					addInstruction(Vm.Opcode.AnonymousTask, 0u);
				else
					logError("Invalid anonymous type", "debug");

				/*foreach(anonFunc; anonymousFunctions) {
					if(anonFunc.name == currentFunction.name) {

						hasAnonFunc = true;
						break;
					}
				}*/
			}
			else {
				dstring mangledName = mangleName(identifier.svalue, signature);
				
				//Primitive call.
				if(isPrimitiveDeclared(mangledName)) {
					Primitive primitive = getPrimitive(mangledName);
					addInstruction(Vm.Opcode.PrimitiveCall, primitive.index);
					returnType = primitive.returnType;
				}
				else //Function/Task call.
					returnType = addFunctionCall(mangledName);
			}
		}
		else {
			//Declared variable.
			variable = getVariable(identifier.svalue);
			addGetInstruction(variable);
			returnType = variable.type;
		}
		
		return returnType;
	}

	//Error handling
	struct Error {
		dstring msg, info;
		Lexeme lex;
		bool mustHalt;
	}

	Error[] errors;

	void logWarning(string msg, string info = "") {
		Error error;
		error.msg = to!dstring(msg);
		error.info = to!dstring(info);
		error.lex = get();
		error.mustHalt = false;
		errors ~= error;
	}

	void logError(string msg, string info = "") {
		Error error;
		error.msg = to!dstring(msg);
		error.info = to!dstring(info);
		error.mustHalt = true;
		if(isEnd()) {
			error.lex = get(-1);
		}
		else
			error.lex = get();

		errors ~= error;
		raiseError();
	}

	void raiseError() {
		foreach(error; errors) {
			dstring report;

			//Separator
			if(error.mustHalt)
				report ~= "\n\033[0;36m--\033[0;91m Error \033[0;36m-------------------- " ~ error.lex.lexer.file ~ "\033[0m\n";
			else
				report ~= "\n\033[0;36m--\033[0;93m Warning \033[0;36m-------------------- " ~ error.lex.lexer.file ~ "\033[0m\n";

			//Error report
			report ~= error.msg ~ ":\033[1;34m\n";

			//Script snippet
			dstring lineNumber = to!dstring(error.lex.line + 1u) ~ "| ";
			report ~= lineNumber;
			report ~= error.lex.getLine().replace("\t", " ") ~ "\n";

			//Red underline
			foreach(x; 1 .. lineNumber.length + error.lex.column)
				report ~= " ";

			if(error.mustHalt)
				report ~= "\033[1;31m"; //Red color
			else
				report ~= "\033[1;93m"; //Red color

			foreach(x; 0 .. error.lex.textLength)
				report ~= "^";
			report ~= "\033[0m\n"; //White color

			//Error description
			if(error.info.length)
				report ~= error.info ~ ".\n";
			writeln(report);
		}
		throw new Exception("\033[0mCompilation aborted...");
	}
}