import std.stdio: writeln;

import grimoire;

void main(string[] args) {
	try {
		setResourceFolder("../data/");
		setResourceSubFolder!Texture("graphic");
		setResourceSubFolder!Font("font");
		setResourceSubFolder!Sprite("graphic");
		
		createApplication(Vec2u(800u, 600u));
		runApplication();
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}
