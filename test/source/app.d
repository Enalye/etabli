
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

        addRootGui(new TextButton(getDefaultFont(), "Top Left !"));

        auto o = new VContainer;
        auto t = new TextButton(getDefaultFont(), "Hello World!");
        o.setAlign(GuiAlignX.right, GuiAlignY.bottom);
        auto h = new HContainer;
        h.addChildGui(t);
        o.addChildGui(h);
        addRootGui(o);

        setDebugGui(true);

        setWindowMinSize(Vec2u(100, 100));
        setWindowMaxSize(Vec2u(600, 600));

		runApplication();
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}