/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.render.drawable;

import bindbc.sdl;
import etabli.core;

/// Indicate if something is mirrored.
enum Flip {
    none,
    horizontal,
    vertical,
    both
}

package SDL_RendererFlip getSDLFlip(Flip flip) {
    final switch (flip) with (Flip) {
    case both:
        return cast(SDL_RendererFlip)(SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL);
    case horizontal:
        return SDL_FLIP_HORIZONTAL;
    case vertical:
        return SDL_FLIP_VERTICAL;
    case none:
        return SDL_FLIP_NONE;
    }
}

/// Blending algorithm \
/// none: Paste everything without transparency \
/// modular: Multiply color value with the destination \
/// additive: Add color value with the destination \
/// alpha: Paste everything with transparency (Default one)
enum Blend {
    none,
    modular,
    additive,
    alpha
}

/// Everything that can be rendered.
interface Drawable {
    @property {
        /// loaded ?
        bool isLoaded() const;
        /// Width in texels.
        uint width() const;
        /// Height in texels.
        uint height() const;

        /// Color added to the renderable.
        Color color() const;
        /// Ditto
        Color color(Color);

        /// Alpha
        float alpha() const;
        /// Ditto
        float alpha(float);

        /// Blending algorithm.
        Blend blend() const;
        /// Ditto
        Blend blend(Blend);
    }

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f anchor) const;

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec4i srcRect, Vec2f anchor) const;

    /// Render the whole texture here
    void draw(Vec2f pos, Vec2f size, Vec2f anchor) const;

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec2f size, Vec4i srcRect, Vec2f anchor) const;

    /// Render a section of the texture here
    void draw(Vec2f pos, Vec2f size, Vec4i srcRect, float angle, Flip flip,
            Vec2f anchor = Vec2f.half) const;
}
