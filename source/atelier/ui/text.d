/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module atelier.ui.text;

import std.utf, std.random;
import std.conv: to;
import std.string;
import atelier.core, atelier.render, atelier.common;
import atelier.ui.gui_element;

/// Dynamic text rendering
final class Text: GuiElement {
	private {
		PixelFont _font;
		Timer _timer, _effectTimer;
		dstring _text;
		size_t _currentIndex;
		Token[] _tokens;
		Color _defaultCharColor = Color.white;
		float _defaultCharDelay = 0f;
		int _defaultCharScale = 1;
		int _defaultCharSpacing = 0;
	}

	@property {
		/// Text
		string text() const {
			return to!string(_text);
		}
		/// Ditto
		string text(string text_) {
			_text = to!dstring(text_);
			restart();
			tokenize();
			return text_;
		}

		/// Is the text still being displayed ?
		bool isPlaying() const { return _timer.isRunning() || (_currentIndex < _tokens.length); }

		/// Default change color
		Color defaultColor() const { return _defaultCharColor; }
		/// Ditto
		Color defaultColor(Color defaultCharColor_) { return _defaultCharColor = defaultCharColor_; }

		/// Default delay between each character
		float defaultDelay() const { return _defaultCharDelay; }
		/// Ditto
		float defaultDelay(float defaultCharDelay_) { return _defaultCharDelay = defaultCharDelay_; }

		/// Default character scaling
		int defaultScale() const { return _defaultCharScale; }
		/// Ditto
		int defaultScale(int defaultCharScale_) { return _defaultCharScale = defaultCharScale_; }
		
		/// Default additionnal spacing between each character
		int defaultSpacing() const { return _defaultCharSpacing; }
		/// Ditto
		int defaultSpacing(int defaultCharSpacing_) { return _defaultCharSpacing = defaultCharSpacing_; }
	}

	/// Ctor
	this(PixelFont font_, string text_) {
		_font = font_;
		_text = to!dstring(text_);
		tokenize();
		_effectTimer.mode = Timer.Mode.loop;
		_effectTimer.start(1f);
	}

	/// Restart the reading from the beginning
	void restart() {
		_currentIndex = 0;
		_timer.reset();
	}

	private struct Token {
		enum Type {
			character, line, scale, spacing, color, delay, pause, effect
		}

		Type type;

		union {
			CharToken character;
			ScaleToken scale;
			SpacingToken spacing;
			ColorToken color;
			DelayToken delay;
			PauseToken pause;
			EffectToken effect;
		}

		struct CharToken {
			dchar character;
		}

		struct ScaleToken {
			int scale;
		}

		struct SpacingToken {
			int spacing;
		}

		struct ColorToken {
			Color color;
		}

		struct DelayToken {
			float duration;
		}

		struct PauseToken {
			float duration;
		}

		struct EffectToken {
			enum Type {
				none, wave, bounce, shake, rainbow
			}
			Type type;
		}
	}

	private void tokenize() {
		size_t current = 0;
		_tokens.length = 0;
		while(current < _text.length) {
			if(_text[current] == '{') {
				current ++;
				size_t endOfBrackets = indexOf(_text, "}", current);
				if(endOfBrackets == -1)
					break;
				dstring brackets = _text[current.. endOfBrackets];
				current = endOfBrackets + 1;

				foreach(modifier; brackets.split(",")) {
					if(!modifier.length)
						continue;
					auto parameters = modifier.split(":");
					if(!parameters.length)
						continue;
					switch(parameters[0]) {
					case "c":
					case "color":
						Token token;
						token.type = Token.Type.color;
						if(parameters.length > 1) {
							if(!parameters[1].length)
								continue;
							if(parameters[1][0] == '#') {
								continue;
								// TODO: #FFFFFF RGB color format
							}
							else {
								switch(parameters[1]) {
								case "clear":
									token.color.color = Color.clear;
									break;
								case "red":
									token.color.color = Color.red;
									break;
								case "blue":
									token.color.color = Color.blue;
									break;
								case "white":
									token.color.color = Color.white;
									break;
								case "black":
									token.color.color = Color.black;
									break;
								case "yellow":
									token.color.color = Color.yellow;
									break;
								case "cyan":
									token.color.color = Color.cyan;
									break;
								case "magenta":
									token.color.color = Color.magenta;
									break;
								case "silver":
									token.color.color = Color.silver;
									break;
								case "gray":
								case "grey":
									token.color.color = Color.gray;
									break;
								case "maroon":
									token.color.color = Color.maroon;
									break;
								case "olive":
									token.color.color = Color.olive;
									break;
								case "green":
									token.color.color = Color.green;
									break;
								case "purple":
									token.color.color = Color.purple;
									break;
								case "teal":
									token.color.color = Color.teal;
									break;
								case "navy":
									token.color.color = Color.navy;
									break;
								case "pink":
									token.color.color = Color.pink;
									break;
								case "orange":
									token.color.color = Color.orange;
									break;
								default:
									continue;
								}
							}
						}
						else continue;
						_tokens ~= token;
						break;
					case "s":
					case "scale":
					case "size":
					case "sz":
						Token token;
						token.type = Token.Type.scale;
						if(parameters.length > 1)
							token.scale.scale = parameters[1].to!int;
						else continue;
						_tokens ~= token;
						break;
					case "l":
					case "ln":
					case "line":
					case "br":
						Token token;
						token.type = Token.Type.line;
						_tokens ~= token;
						break;
					case "w":
					case "wait":
					case "p":
					case "pause":
						Token token;
						token.type = Token.Type.pause;
						if(parameters.length > 1)
							token.pause.duration = parameters[1].to!float;
						else continue;
						_tokens ~= token;
						break;
					case "fx":
					case "effect":
						Token token;
						token.type = Token.Type.effect;
						token.effect.type = Token.EffectToken.Type.none;
						if(parameters.length > 1) {
							switch(parameters[1]) {
							case "wave":
								token.effect.type = Token.EffectToken.Type.wave;
								break;
							case "bounce":
								token.effect.type = Token.EffectToken.Type.bounce;
								break;
							case "shake":
								token.effect.type = Token.EffectToken.Type.shake;
								break;
							case "rainbow":
								token.effect.type = Token.EffectToken.Type.rainbow;
								break;
							default:
								token.effect.type = Token.EffectToken.Type.none;
								break;
							}
						}
						else continue;
						_tokens ~= token;
						break;
					case "d":
					case "dl":
					case "delay":
						Token token;
						token.type = Token.Type.delay;
						if(parameters.length > 1)
							token.delay.duration = parameters[1].to!float;
						else continue;
						_tokens ~= token;
						break;
					default:
						continue;
					}
				}
			}
			else {
				Token token;
				token.type = Token.Type.character;
				token.character.character = _text[current];
				_tokens ~= token;
				current ++;
			}
		}
	}

	override void update(float deltaTime) {
		_timer.update(deltaTime);
		_effectTimer.update(deltaTime);
	}

	override void draw() {
		Vec2f pos = origin + Vec2f(0f, _font.ascent * _defaultCharScale);
		dchar prevChar;
		Color charColor_ = _defaultCharColor;
		float charDelay_ = _defaultCharDelay;
		int charScale_ = _defaultCharScale;
		int charSpacing_ = _defaultCharSpacing;
		Token.EffectToken.Type charEffect_ = Token.EffectToken.Type.none;
		Vec2f totalSize_ = Vec2f.zero;
		Timer waveTimer = _effectTimer;
		foreach(size_t index, Token token; _tokens) {
			final switch(token.type) with(Token.Type) {
			case character:
				if(_currentIndex == index) {
					if(_timer.isRunning)
						break;
					if(charDelay_ > 0f)
						_timer.start(charDelay_);
					_currentIndex ++;
				}
				GlyphMetrics metrics = _font.getMetrics(token.character.character);
				pos.x += _font.getKerning(prevChar, token.character.character) * charScale_;
				Vec2f drawPos = Vec2f(pos.x + metrics.offsetX * charScale_, pos.y + metrics.offsetY * charScale_);

				final switch(charEffect_) with(Token.EffectToken.Type) {
				case none:
					break;
				case wave:
					waveTimer.update(1f);
					waveTimer.update(1f);
					waveTimer.update(1f);
					waveTimer.update(1f);
					waveTimer.update(1f);
					waveTimer.update(1f);
					if(waveTimer.value01 < .5f)
						drawPos.y -= lerp!float(_font.descent, _font.ascent, easeInOutSine(waveTimer.value01 * 2f));
					else
						drawPos.y -= lerp!float(_font.ascent, _font.descent, easeInOutSine((waveTimer.value01 - .5f) * 2f));
					break;
				case bounce:
					if(_effectTimer.value01 < .5f)
						drawPos.y -= lerp!float(_font.descent, _font.ascent, easeOutSine(_effectTimer.value01 * 2f));
					else
						drawPos.y -= lerp!float(_font.ascent, _font.descent, easeInSine((_effectTimer.value01 - .5f) * 2f));
					break;
				case shake:
					drawPos += Vec2f(uniform01(), uniform01()) * charScale_;
					break;
				case rainbow:
					break;
				}

				metrics.draw(drawPos, charScale_, charColor_);
				pos.x += (metrics.advance + charSpacing_) * charScale_;
				prevChar = token.character.character;
				if((pos.x - origin.x) > totalSize_.x) {
					totalSize_.x = (pos.x - origin.x);
				}
				if(((_font.ascent - _font.descent) * charScale_) > totalSize_.y) {
					totalSize_.y = (_font.ascent - _font.descent) * charScale_;
				}
				break;
			case line:
				if(_currentIndex == index)
					_currentIndex ++;
				pos.x = origin.x;
				pos.y += ((_font.ascent - _font.descent) + 1f) * charScale_;
				if((pos.y - origin.y) > totalSize_.y) {
					totalSize_.y = (pos.y - origin.y);
				}
				break;
			case scale:
				if(_currentIndex == index)
					_currentIndex ++;
				charScale_ = token.scale.scale;
				break;
			case spacing:
				if(_currentIndex == index)
					_currentIndex ++;
				charSpacing_ = token.spacing.spacing;
				break;
			case color:
				if(_currentIndex == index)
					_currentIndex ++;
				charColor_ = token.color.color;
				break;
			case delay:
				if(_currentIndex == index)
					_currentIndex ++;
				charDelay_ = token.delay.duration;
				break;
			case pause:
				if(_currentIndex == index) {
					if(_timer.isRunning)
						break;
					if(token.pause.duration > 0f)
						_timer.start(token.pause.duration);
					_currentIndex ++;
				}
				break;
			case effect:
				if(_currentIndex == index)
					_currentIndex ++;
				charEffect_ = token.effect.type;
				break;
			}
			if(index == _currentIndex)
				break;
		}
		size = totalSize_;
	}
}