import std.stdio: writeln;

import grimoire;

void main() {
	try {
		createApplication(Vec2u(800u, 600u));
		runApplication();
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}
