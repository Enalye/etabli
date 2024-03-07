/**
    Test application

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

import std.stdio : writeln;
import std.file, std.path;

import etabli;

void main() {
    try {
        Etabli et = new Etabli(800, 600);
        initThemes();

        auto vbox = new VBox;
        vbox.setAlign(UIAlignX.left, UIAlignY.top);
        vbox.setSpacing(8f);
        vbox.setPosition(Vec2f(10f, 10f));
        et.ui.add(vbox);

        {
            auto btn = new PrimaryButton("Primary");
            vbox.addUI(btn);
        }
        {
            auto btn = new OutlinedButton("Outlined");
            vbox.addUI(btn);
        }
        {
            auto btn = new GhostButton("Text");
            vbox.addUI(btn);
        }
        {
            auto slider = new HSlider();
            slider.minValue = 0;
            slider.maxValue = 200;
            slider.steps = 2;
            slider.ivalue = 100;
            slider.setPosition(Vec2f(0f, 200f));
            et.ui.add(slider);

            auto slider2 = new VSlider();
            slider2.minValue = 0;
            slider2.maxValue = 200;
            slider2.steps = 200;
            slider2.ivalue = 100;
            slider2.setPosition(Vec2f(200f, 0f));
            et.ui.add(slider2);

            slider.addEventListener("value", { writeln(slider.value01); });
        }

        et.run();

        /*createApplication(Vec2i(1280, 300));

        auto fontCache = new ResourceCache!TrueTypeFont;
        setResourceCache!TrueTypeFont(fontCache);

        setWindowClearColor(Color.gray);*/

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
        /*
        {
            a = new Label("élément 1\nsaucisse");
            b = new Label("élément 2");
            c = new Label("élément 3");

            //auto l = new VContainer;
            l = new VList(Vec2f(150f, 200f));
            l.appendNode(a);
            l.appendNode(b);
            l.appendNode(c);
            l.appendNode(new Label("Yo1"));
            l.appendNode(new Label("Yo2"));
            l.appendNode(new Label("Yo3"));
            l.appendNode(new Label("Yo4"));
            l.appendNode(new Label("Yo5"));
            l.appendNode(new Label("Yo6"));
            l.appendNode(new Label("Yo7"));
            l.appendNode(new Label("Yo8"));
            l.appendNode(new Label("Yo9"));
            l.appendNode(new Label("Yo10"));
            l.appendNode(new Label("Yo11"));
            appendRoot(l);
        }
        appendRoot(new TestUi);

        runApplication();*/
    }
    catch (Exception e) {
        writeln(e.msg);
    }
}
/*
UIElement a, b, c;
VList l;

class TestUi : UIElement {
    override void update(float) {
        import std.stdio;
        //writeln(l.size, ", ", l._container.size, ", ", l._container.container.size);
    }
}*/
