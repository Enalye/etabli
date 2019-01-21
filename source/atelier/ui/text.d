/**
    Text

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.text;

import std.utf;
import std.conv: to;
import derelict.sdl2.sdl, derelict.sdl2.ttf;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element;

private {
	ITextCache _standardCache, _italicCache, _boldCache, _italicBoldCache;
}

interface ITextCache {
	Sprite get(dchar c);
}

class FontCache: ITextCache {
	private {
		Font _font;
		Sprite[dchar] _cache;
	}

	this(Font newFont) {
		_font = newFont;
	}

	Sprite get(dchar c) {
		Sprite* cachedSprite = (c in _cache);
		if(cachedSprite is null) {
			auto texture = new Texture;
			texture.loadFromSurface(TTF_RenderUTF8_Blended(_font.font, toUTFz!(const char*)([c].toUTF8), Color.white.toSDL()));
			Sprite sprite = new Sprite(texture);
			_cache[c] = sprite;
			return sprite;
		}
		else {
			return *cachedSprite;
		}
	}
}

void setTextStandardFont(ITextCache cache) {
	_standardCache = cache;
}

void setTextItalicFont(ITextCache cache) {
	_italicCache = cache;
}

void setTextBoldFont(ITextCache cache) {
	_boldCache = cache;
}

void setTextItalicBoldFont(ITextCache cache) {
	_italicBoldCache = cache;
}

private {
	enum TextTokenType {
		CharacterType,
		NewLineType,
		ColorType,
		StandardType,
		ItalicType,
		BoldType,
		ItalicBoldType
	}
	
	struct TextToken {
		TextTokenType type;

		Sprite charSprite;
		Color color;

		this(TextTokenType newType) {
			type = newType;
		}
	}
}

class Text: GuiElement {
	private {
		dstring _text;
		TextToken[] _tokens;
		int[] _lineLengths;
		int _rowLength, _maxLineLength, _lineLimit;
		Vec2f charSize = Vec2f.zero;
		ITextCache _currentCache;
	}

	@property {
		string text() const { return to!string(_text); }
		string text(string newText) {
			_text = to!dstring(newText);
			reload();
			return newText;
		}
	}

	this(int newLineLimit = 0) {
		_lineLimit = newLineLimit;
	}

	this(string newText, int newLineLimit = 0) {
		_lineLimit = newLineLimit;
		text(newText);
	}

	private uint parseTag(uint i) {
		dstring tag;
		if(_text[i] != '{')
			throw new Exception("Text: A tag must start with a \'{\'");
		//'{'
		i ++;
		while(_text[i] != '}') {
			tag ~= _text[i];
			i ++;
			if(i >= _text.length)
				throw new Exception("Text: An opened tag must be closed with \'}\'");
		}
		TextToken token;
		switch(tag) {
		case "n"d:
			token.type = TextTokenType.NewLineType;
			_lineLengths.length ++;
			_rowLength ++;
			_lineLengths[_rowLength] = 0;
			break;
		case "s"d:
			token.type = TextTokenType.StandardType;
			_currentCache = _standardCache;
			break;
		case "b"d:
			token.type = TextTokenType.BoldType;
			_currentCache = _boldCache;
			break;
		case "i"d:
			token.type = TextTokenType.ItalicType;
			_currentCache = _italicCache;
			break;
		case "bi"d:
			token.type = TextTokenType.ItalicBoldType;
			_currentCache = _italicBoldCache;
			break;
		case "white"d:
			token.type = TextTokenType.ColorType;
			token.color = Color.white;
			break;
		case "red"d:
			token.type = TextTokenType.ColorType;
			token.color = Color.red;
			break;
		case "blue"d:
			token.type = TextTokenType.ColorType;
			token.color = Color.blue;
			break;
		case "green"d:
			token.type = TextTokenType.ColorType;
			token.color = Color.green;
			break;
		default:
			throw new Exception("Text: The tag \'" ~ to!string(tag) ~ "\' does not exist");
		}
		_tokens ~= token;
		//'}'
		i ++;
		return i;
	}

	private void reload() {
		if(!_text.length)
			return;
		_tokens.length = 0L;
		_lineLengths.length = 1;
		_lineLengths[0] = 0;
		_rowLength = 0;
		_maxLineLength = 0;
		_currentCache = _standardCache;
		uint i = 0U;
		while(i < _text.length) {
			if(_text[i] == '{')
				i = parseTag(i);
			else {
				if(_lineLimit > 0) {
					//Auto carriage return.
					if(_lineLengths[_rowLength] > _lineLimit) {
						TextToken token;
						token.type = TextTokenType.NewLineType;
						_lineLengths.length ++;
						_rowLength ++;
						_lineLengths[_rowLength] = 0;
						_tokens ~= token;
					}
				}
				auto token = TextToken(TextTokenType.CharacterType);
				token.charSprite = _currentCache.get(_text[i]);
				_tokens ~= token;
				_lineLengths[_rowLength] ++;
				if(_lineLengths[_rowLength] > _maxLineLength)
					_maxLineLength = _lineLengths[_rowLength];
				i ++;
			}
		}
		if(!_maxLineLength)
			throw new Exception("Error while fetching cached characters");
		charSize = _standardCache.get('a').size;

		size = Vec2f(charSize.x * _maxLineLength, charSize.y * (_rowLength + 1));
	}

	override void draw() {
		Color currentColor = Color.white;
		Vec2i currentPos = Vec2i.zero;
		foreach(uint i, token; _tokens) {
			switch(token.type) with(TextTokenType) {
			case CharacterType:
				token.charSprite.color = currentColor;
				token.charSprite.draw(center + charSize * Vec2f(
					to!float(currentPos.x) - _maxLineLength / 2f,
					to!float(currentPos.y) - _rowLength / 2f));
				token.charSprite.color = Color.white;
				currentPos.x ++;
				break;
			case NewLineType:
				currentPos.x = 0;
				currentPos.y ++;
				break;
			case StandardType:
				break;
			case BoldType:
				break;
			case ItalicType:
				break;
			case ItalicBoldType:
				break;
			case ColorType:
				currentColor = token.color;
				break;
			default:
				throw new Exception("Text: Invalid token");
			}
		}
	}
}