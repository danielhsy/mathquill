/**
 * Unicode Mathematical Alphanumeric Symbols conversion.
 * Offset tables derived from the Unicode standard (U+1D400-U+1D7FF).
 */

// [upperAlphaBase, lowerAlphaBase, upperGreekBase, lowerGreekBase, digitsBase]
// undefined means the variant has no mapping for that character range
/* eslint-disable no-sparse-arrays */
var VARIANT_SMP: { [variant: string]: (number | undefined)[] } = {
  italic:                   [0x1D434, 0x1D44E, 0x1D6E2, 0x1D6FC],
  bold:                     [0x1D400, 0x1D41A, 0x1D6A8, 0x1D6C2, 0x1D7CE],
  'bold-italic':            [0x1D468, 0x1D482, 0x1D71C, 0x1D736],
  script:                   [0x1D49C, 0x1D4B6],
  'bold-script':            [0x1D4D0, 0x1D4EA],
  fraktur:                  [0x1D504, 0x1D51E],
  'double-struck':          [0x1D538, 0x1D552, undefined, undefined, 0x1D7D8],
  'bold-fraktur':           [0x1D56C, 0x1D586],
  'sans-serif':             [0x1D5A0, 0x1D5BA, undefined, undefined, 0x1D7E2],
  'bold-sans-serif':        [0x1D5D4, 0x1D5EE, 0x1D756, 0x1D770, 0x1D7EC],
  'sans-serif-italic':      [0x1D608, 0x1D622],
  'sans-serif-bold-italic': [0x1D63C, 0x1D656, 0x1D790, 0x1D7AA],
  monospace:                [0x1D670, 0x1D68A, undefined, undefined, 0x1D7F6],
};

// [offsetIndex, rangeStart, rangeEnd]
var SMP_RANGES: [number, number, number][] = [
  [0, 0x41, 0x5A],   // A-Z
  [1, 0x61, 0x7A],   // a-z
  [2, 0x391, 0x3A9], // uppercase Greek
  [3, 0x3B1, 0x3C9], // lowercase Greek
  [4, 0x30,  0x39],  // 0-9
];

// Variant Greek forms (ε-symbol, ϑ, ϰ, ϕ, ϱ, ϖ) lie at lower-Greek-base + 26..31
// in every SMP block that has Greek (i.e. bases[3] is defined).
var GREEK_VARIANT_CHARS = [0x3F5, 0x3D1, 0x3F0, 0x3D5, 0x3F1, 0x3D6]; // ϵ ϑ ϰ ϕ ϱ ϖ

// Holes in the Math Alphanumeric block that remap to other Unicode positions
var SMP_REMAP: { [smp: number]: number } = {
  0x1D455: 0x210E,  // italic h -> Planck constant
  0x1D49D: 0x212C,  // script B
  0x1D4A0: 0x2130,  // script E
  0x1D4A1: 0x2131,  // script F
  0x1D4A3: 0x210B,  // script H
  0x1D4A4: 0x2110,  // script I
  0x1D4A7: 0x2112,  // script L
  0x1D4A8: 0x2133,  // script M
  0x1D4AD: 0x211B,  // script R
  0x1D4BA: 0x212F,  // script e
  0x1D4BC: 0x210A,  // script g
  0x1D4C4: 0x2134,  // script o
  0x1D506: 0x212D,  // fraktur C
  0x1D50B: 0x210C,  // fraktur H
  0x1D50C: 0x2111,  // fraktur I
  0x1D515: 0x211C,  // fraktur R
  0x1D51D: 0x2128,  // fraktur Z
  0x1D53A: 0x2102,  // double-struck C
  0x1D53F: 0x210D,  // double-struck H
  0x1D545: 0x2115,  // double-struck N
  0x1D547: 0x2119,  // double-struck P
  0x1D548: 0x211A,  // double-struck Q
  0x1D549: 0x211D,  // double-struck R
  0x1D551: 0x2124,  // double-struck Z
};

/**
 * Encode a Unicode code point as a JS string.
 * Handles supplementary plane characters (> U+FFFF) via surrogate pairs.
 */
function codePointToString(cp: number): string {
  if (cp < 0x10000) return String.fromCharCode(cp);
  var offset = cp - 0x10000;
  return String.fromCharCode(
    0xD800 + (offset >> 10),
    0xDC00 + (offset & 0x3FF)
  );
}

/**
 * Convert a BMP character (or its code point) to its Unicode math variant
 * code point. Returns the original code point unchanged if no mapping exists.
 *
 * Supported variants: 'italic', 'bold', 'bold-italic', 'script',
 *   'bold-script', 'fraktur', 'double-struck', 'bold-fraktur',
 *   'sans-serif', 'bold-sans-serif', 'sans-serif-italic',
 *   'sans-serif-bold-italic', 'monospace'
 */
function toMathVariant(charOrCode: string | number, variant: string): number {
  var code = typeof charOrCode === 'string' ? charOrCode.charCodeAt(0) : charOrCode;
  var bases = VARIANT_SMP[variant];
  if (!bases) return code;
  for (var i = 0; i < SMP_RANGES.length; i++) {
    var range = SMP_RANGES[i];
    var idx = range[0], lo = range[1], hi = range[2];
    if (code >= lo && code <= hi) {
      var base = bases[idx];
      if (base == null) return code;
      var smp = base + (code - lo);
      return SMP_REMAP[smp] != null ? SMP_REMAP[smp] : smp;
    }
  }
  // Variant Greek forms (ϵ ϑ ϰ ϕ ϱ ϖ) at lower-Greek-base + 26..31
  var gvIdx = GREEK_VARIANT_CHARS.indexOf(code);
  if (gvIdx >= 0 && bases[3] != null) {
    return (bases[3] as number) + 26 + gvIdx;
  }
  return code;
}

/**
 * Convert a BMP character to its Unicode math variant string.
 * Returns the original character if no mapping exists.
 */
function toMathVariantStr(charOrCode: string | number, variant: string): string {
  return codePointToString(toMathVariant(charOrCode, variant));
}
