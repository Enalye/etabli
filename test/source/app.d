
/**
    Test application

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

import std.stdio: writeln;

import atelier;

void main() {
	try {
        //Set data location
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
