/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module etabli.core.data;

import etabli.common;
import etabli.core.data.logo32;
import etabli.core.data.logo64;
import etabli.core.data.logo128;
import etabli.core.data.vera;

package(etabli.core) void loadInternalData(ResourceManager res) {
    res.write("etabli:logo32", logo32Data);
    res.write("etabli:logo64", logo64Data);
    res.write("etabli:logo128", logo128Data);
    res.write("etabli:vera", veraFontData);
    res.write("etabli:veramono", veraMonoFontData);
}
