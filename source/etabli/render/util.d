/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.render.util;

import bindbc.sdl;

/** Algorithme de composition
none:
    dC = sC \
    dA = sA
alpha:
    dC = sC * sA + dC * (1 - sA) \
    dA = sA + dA * (1 - sA)
additive:
    dC = sC * sA + dC \
    dA = dA
modular:
    dC = sC * dC \
    dA = dA
multiply:
    dC = sC * dC + dC * (1 - sA) \
    dA = sA * dA + dA * (1 - sA)
canvas:
    dC = sC + dC * (1 - sA) \
    dA = sA + dA * (1 - sA)
mask:
    dC = sC \
    dA = dA
*/
enum Blend {
    none,
    alpha,
    additive,
    modular,
    multiply,
    canvas,
    mask
}

/// Récupère l’option SDL de composition
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
