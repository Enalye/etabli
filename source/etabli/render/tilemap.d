/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.tilemap;

import std.conv : to;
import std.math : floor, ceil;
import std.algorithm.comparison : min, max;

import etabli.common;
import etabli.render.image;
import etabli.render.tileset;

final class Tilemap : Image {
    private {
        Tileset _tileset;
        uint _currentTick;
        short[] _tiles;
        int _width, _height;
    }

    Vec2f size = Vec2f.zero;

    this(Tileset tileset, int width, int height) {
        _tileset = tileset;
        _width = width;
        _height = height;
        clip = _tileset.clip;
        size = cast(Vec2f) clip.zw;

        _tiles.length = _width * _height;
        foreach (ref short tile; _tiles) {
            tile = 5;
        }
    }

    this(Tilemap tilemap) {
        super(tilemap);
        _tileset = tilemap._tileset;
        _width = tilemap._width;
        _height = tilemap._height;
        _tiles = tilemap._tiles;
        size = tilemap.size;
    }

    void setTile(int x, int y, int tile) {
        if (x < 0 || y < 0 || x >= _width || y >= _height)
            return;

        _tiles[x + y * _width] = cast(short) tile;
    }

    /// Redimensionne l’image pour qu’elle puisse tenir dans une taille donnée
    override void fit(Vec2f size_) {
        size = to!Vec2f(clip.zw).fit(size_);
    }

    /// Redimensionne l’image pour qu’elle puisse contenir une taille donnée
    override void contain(Vec2f size_) {
        size = to!Vec2f(clip.zw).contain(size_);
    }

    override void update() {
        _currentTick++;
        if (_currentTick >= _tileset.frameTime) {
            _currentTick = 0;
            foreach (ref tile; _tiles) {
                tile = _tileset.getTileFrame(tile);
            }
        }
    }

    override void draw(Vec2f origin = Vec2f.zero) {
        _tileset.color = color;
        _tileset.alpha = alpha;
        _tileset.blend = blend;

        Vec2f startPos = origin + position - (size * anchor);

        int minX = 0;
        int minY = 0;
        int maxX = _width;
        int maxY = _height;

        Vec2f tilePos;
        int renderedTiles;
        for (int y = minY; y < maxY; y++) {
            for (int x = minX; x < maxX; x++) {
                tilePos = startPos;
                tilePos.x += x * size.x;
                tilePos.y += y * size.y;

                int tileId = _tiles[x * _width + y];
                renderedTiles++;

                if (tileId >= 0)
                    _tileset.draw(tileId, tilePos, size, angle);
            }
        }
    }
}
