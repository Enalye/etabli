/**
    Test application

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

import std.stdio : writeln;
import std.file, std.path;

import atelier;

void main() {
    try {
        createApplication(Vec2i(1280, 300));

        auto fontCache = new ResourceCache!TrueTypeFont;
        setResourceCache!TrueTypeFont(fontCache);

        setWindowClearColor(Color.gray);

        /*auto files = dirEntries("../data/font/", "{*.ttf}", SpanMode.depth);
        foreach (file; files) {
            fontCache.set(new TrueTypeFont(file), baseName(file, ".ttf"));
        }*/
        //setDefaultFont(fetch!TrueTypeFont("VeraMono"));

        /*appendRoot(new Label("J'aime les licornes, 窓がどうして開いた？"));
        auto b = new Text("« Portez ce vieux whisky au juge blond qui fume sur son île intérieure,
à côté de l'alcôve ovoïde, où les bûches se consument dans l'âtre,
ce qui lui permet de penser à la cænogénèse de l'être dont il est{fx:shake} question dans la cause ambiguë entendue à Moÿ,
dans un capharnaüm qui, pense-t-il, diminue çà et là la qualité de son œuvre. »");
        b.position = Vec2f(0f, 100f);
        b.cps = 60;
        appendRoot(b);*/

        //setDebugGui(true);

        {
            a = new Label("élément 1\nsaucisse");
            b = new Label("élément 2");
            c = new Label("élément 3");

            //auto l = new VContainer;
            l = new VList(Vec2f(150f, 200f));
            l.appendChild(a);
            l.appendChild(b);
            l.appendChild(c);
            l.appendChild(new Label("Yo1"));
            l.appendChild(new Label("Yo2"));
            l.appendChild(new Label("Yo3"));
            l.appendChild(new Label("Yo4"));
            l.appendChild(new Label("Yo5"));
            l.appendChild(new Label("Yo6"));
            l.appendChild(new Label("Yo7"));
            l.appendChild(new Label("Yo8"));
            l.appendChild(new Label("Yo9"));
            l.appendChild(new Label("Yo10"));
            l.appendChild(new Label("Yo11"));
            appendRoot(l);
        }
        appendRoot(new TestUi);

        runApplication();
    }
    catch (Exception e) {
        writeln(e.msg);
    }
}

GuiElement a, b, c;
VList l;

class TestUi : GuiElement {
    override void update(float) {
        import std.stdio;
        //writeln(l.size, ", ", l._container.size, ", ", l._container.container.size);
    }
}