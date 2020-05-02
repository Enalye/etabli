
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
		createApplication(Vec2u(1280u, 300u));

        auto fontCache = new ResourceCache!TrueTypeFont;
        setResourceCache!TrueTypeFont(fontCache);

        setWindowClearColor(Color.gray);

        auto files = dirEntries("../data/font/", "{*.ttf}", SpanMode.depth);
        foreach(file; files) {
            fontCache.set(new TrueTypeFont(file), baseName(file, ".ttf"));
        }
        setDefaultFont(fetch!TrueTypeFont("font01"));


        addRootGui(new Label(getDefaultFont(), "J'aime les licornes, 窓がどうして開いた？"));
        auto b = new Text(fetch!TrueTypeFont("VeraMono"), 
"« Portez ce vieux whisky au juge blond qui fume sur son île intérieure,
à côté de l'alcôve ovoïde, où les bûches se consument dans l'âtre,
ce qui lui permet de penser à la cænogénèse de l'être dont il est question dans la cause ambiguë entendue à Moÿ,
dans un capharnaüm qui, pense-t-il, diminue çà et là la qualité de son œuvre. »");
        b.position = Vec2f(0f, 100f);
        b.defaultDelay = 0.02f;
        addRootGui(b);

        setDebugGui(true);

		runApplication();
	}
	catch(Exception e) {
		writeln(e.msg);
	}
}