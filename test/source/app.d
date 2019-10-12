
/**
    Test application

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

import std.stdio: writeln;
import std.file, std.path;

import atelier;

void main() {
	try {
		createApplication(Vec2u(800u, 600u));

        auto fontCache = new ResourceCache!TrueTypeFont;
        setResourceCache!TrueTypeFont(fontCache);

        auto files = dirEntries("../data/font/", "{*.ttf}", SpanMode.depth);
        foreach(file; files) {
            fontCache.set(new TrueTypeFont(file), baseName(file, ".ttf"));
        }
        setDefaultFont(fetch!TrueTypeFont("font"));

        auto a = new HList(Vec2f(400f, 300f));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello1"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello2"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello3"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4dazdazdazdazda"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4adazdaz"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        a.addChildGui(new TextButton(getDefaultFont(), "Hello4"));
        addRootGui(a);

        setDebugGui(true);

		runApplication();
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}
