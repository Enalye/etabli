/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.util;

import bindbc.sdl;

/// Blending algorithm \
/// none: Paste everything without transparency \
/// modular: Multiply color value with the destination \
/// additive: Add color value with the destination \
/// alpha: Paste everything with transparency (Default one)
enum Blend {
    none,
    alpha,
    additive,
    modular,
    multiply,
    canvas,
    mask
}

/// Returns the SDL blend flag.
package SDL_BlendMode getSDLBlend(Blend blend) {
    final switch (blend) with (Blend) {
    case none:
        return SDL_BLENDMODE_NONE;
    case alpha:
        return SDL_BLENDMODE_BLEND;
    case additive:
        return SDL_BLENDMODE_ADD;
    case modular:
        return SDL_BLENDMODE_MOD;
    case multiply:
        return SDL_BLENDMODE_MUL;
    case canvas:
        return SDL_ComposeCustomBlendMode(SDL_BLENDFACTOR_ONE,
            SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, SDL_BLENDOPERATION_ADD,
            SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, SDL_BLENDOPERATION_ADD);
    case mask:
        return SDL_ComposeCustomBlendMode(SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ZERO, SDL_BLENDOPERATION_ADD,
            SDL_BLENDFACTOR_DST_ALPHA, SDL_BLENDFACTOR_ZERO, SDL_BLENDOPERATION_ADD);
    }
}
