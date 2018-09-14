import std.stdio: writeln;

import atelier;

void main() {
	try {
		loadPrimitives();
		auto bytecode = compileFile("../script.txt");
		Vm vm = new Vm;
		vm.load(bytecode);


		//createApplication(Vec2u(800u, 600u));
		//runApplication();
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}
