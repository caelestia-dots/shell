.pragma library

/*
https://github.com/ajitid/fzf-for-js

BSD 3-Clause License

Copyright (c) 2021, Ajit
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

const normalized = {
  216: "O",
  223: "s",
  248: "o",
  273: "d",
  295: "h",
  305: "i",
  320: "l",
  322: "l",
  359: "t",
  383: "s",
  384: "b",
  385: "B",
  387: "b",
  390: "O",
  392: "c",
  393: "D",
  394: "D",
  396: "d",
  398: "E",
  400: "E",
  402: "f",
  403: "G",
  407: "I",
  409: "k",
  410: "l",
  412: "M",
  413: "N",
  414: "n",
  415: "O",
  421: "p",
  427: "t",
  429: "t",
  430: "T",
  434: "V",
  436: "y",
  438: "z",
  477: "e",
  485: "g",
  544: "N",
  545: "d",
  549: "z",
  564: "l",
  565: "n",
  566: "t",
  567: "j",
  570: "A",
  571: "C",
  572: "c",
  573: "L",
  574: "T",
  575: "s",
  576: "z",
  579: "B",
  580: "U",
  581: "V",
  582: "E",
  583: "e",
  584: "J",
  585: "j",
  586: "Q",
  587: "q",
  588: "R",
  589: "r",
  590: "Y",
  591: "y",
  592: "a",
  593: "a",
  595: "b",
  596: "o",
  597: "c",
  598: "d",
  599: "d",
  600: "e",
  603: "e",
  604: "e",
  605: "e",
  606: "e",
  607: "j",
  608: "g",
  609: "g",
  610: "G",
  613: "h",
  614: "h",
  616: "i",
  618: "I",
  619: "l",
  620: "l",
  621: "l",
  623: "m",
  624: "m",
  625: "m",
  626: "n",
  627: "n",
  628: "N",
  629: "o",
  633: "r",
  634: "r",
  635: "r",
  636: "r",
  637: "r",
  638: "r",
  639: "r",
  640: "R",
  641: "R",
  642: "s",
  647: "t",
  648: "t",
  649: "u",
  651: "v",
  652: "v",
  653: "w",
  654: "y",
  655: "Y",
  656: "z",
  657: "z",
  663: "c",
  665: "B",
  666: "e",
  667: "G",
  668: "H",
  669: "j",
  670: "k",
  671: "L",
  672: "q",
  686: "h",
  867: "a",
  868: "e",
  869: "i",
  870: "o",
  871: "u",
  872: "c",
  873: "d",
  874: "h",
  875: "m",
  876: "r",
  877: "t",
  878: "v",
  879: "x",
  7424: "A",
  7427: "B",
  7428: "C",
  7429: "D",
  7431: "E",
  7432: "e",
  7433: "i",
  7434: "J",
  7435: "K",
  7436: "L",
  7437: "M",
  7438: "N",
  7439: "O",
  7440: "O",
  7441: "o",
  7442: "o",
  7443: "o",
  7446: "o",
  7447: "o",
  7448: "P",
  7449: "R",
  7450: "R",
  7451: "T",
  7452: "U",
  7453: "u",
  7454: "u",
  7455: "m",
  7456: "V",
  7457: "W",
  7458: "Z",
  7522: "i",
  7523: "r",
  7524: "u",
  7525: "v",
  7834: "a",
  7835: "s",
  8305: "i",
  8341: "h",
  8342: "k",
  8343: "l",
  8344: "m",
  8345: "n",
  8346: "p",
  8347: "s",
  8348: "t",
  8580: "c"
};
for (let i = "\u0300".codePointAt(0); i <= "\u036F".codePointAt(0); ++i) {
  const diacritic = String.fromCodePoint(i);
  for (const asciiChar of "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz") {
    const withDiacritic = (asciiChar + diacritic).normalize();
    const withDiacriticCodePoint = withDiacritic.codePointAt(0);
    if (withDiacriticCodePoint > 126) {
      normalized[withDiacriticCodePoint] = asciiChar;
    }
  }
}
const ranges = {
  a: [7844, 7863],
  e: [7870, 7879],
  o: [7888, 7907],
  u: [7912, 7921]
};
for (const lowerChar of Object.keys(ranges)) {
  const upperChar = lowerChar.toUpperCase();
  for (let i = ranges[lowerChar][0]; i <= ranges[lowerChar][1]; ++i) {
    normalized[i] = i % 2 === 0 ? upperChar : lowerChar;
  }
}
function normalizeRune(rune) {
  if (rune < 192 || rune > 8580) {
    return rune;
  }
  const normalizedChar = normalized[rune];
  if (normalizedChar !== void 0)
    return normalizedChar.codePointAt(0);
  return rune;
}
function toShort(number) {
  return number;
}
function toInt(number) {
  return number;
}
function maxInt16(num1, num2) {
  return num1 > num2 ? num1 : num2;
}
const strToRunes = (str) => str.split("").map((s) => s.codePointAt(0));
const runesToStr = (runes) => runes.map((r) => String.fromCodePoint(r)).join("");
const whitespaceRunes = new Set(
  " \f\n\r	\v\xA0\u1680\u2028\u2029\u202F\u205F\u3000\uFEFF".split("").map((v) => v.codePointAt(0))
);
for (let codePoint = "\u2000".codePointAt(0); codePoint <= "\u200A".codePointAt(0); codePoint++) {
  whitespaceRunes.add(codePoint);
}
const isWhitespace = (rune) => whitespaceRunes.has(rune);
const whitespacesAtStart = (runes) => {
  let whitespaces = 0;
  for (const rune of runes) {
    if (isWhitespace(rune))
      whitespaces++;
    else
      break;
  }
  return whitespaces;
};
const whitespacesAtEnd = (runes) => {
  let whitespaces = 0;
  for (let i = runes.length - 1; i >= 0; i--) {
    if (isWhitespace(runes[i]))
      whitespaces++;
    else
      break;
  }
  return whitespaces;
};
const MAX_ASCII = "\x7F".codePointAt(0);
const CAPITAL_A_RUNE = "A".codePointAt(0);
const CAPITAL_Z_RUNE = "Z".codePointAt(0);
const SMALL_A_RUNE = "a".codePointAt(0);
const SMALL_Z_RUNE = "z".codePointAt(0);
const NUMERAL_ZERO_RUNE = "0".codePointAt(0);
const NUMERAL_NINE_RUNE = "9".codePointAt(0);
function indexAt(index, max, forward) {
  if (forward) {
    return index;
  }
  return max - index - 1;
}
const SCORE_MATCH = 16, SCORE_GAP_START = -3, SCORE_GAP_EXTENTION = -1, BONUS_BOUNDARY = SCORE_MATCH / 2, BONUS_NON_WORD = SCORE_MATCH / 2, BONUS_CAMEL_123 = BONUS_BOUNDARY + SCORE_GAP_EXTENTION, BONUS_CONSECUTIVE = -(SCORE_GAP_START + SCORE_GAP_EXTENTION), BONUS_FIRST_CHAR_MULTIPLIER = 2;
function createPosSet(withPos) {
  if (withPos) {
    return /* @__PURE__ */ new Set();
  }
  return null;
}
function alloc16(offset, slab2, size) {
  if (slab2 !== null && slab2.i16.length > offset + size) {
    const subarray = slab2.i16.subarray(offset, offset + size);
    return [offset + size, subarray];
  }
  return [offset, new Int16Array(size)];
}
function alloc32(offset, slab2, size) {
  if (slab2 !== null && slab2.i32.length > offset + size) {
    const subarray = slab2.i32.subarray(offset, offset + size);
    return [offset + size, subarray];
  }
  return [offset, new Int32Array(size)];
}
function charClassOfAscii(rune) {
  if (rune >= SMALL_A_RUNE && rune <= SMALL_Z_RUNE) {
    return 1;
  } else if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
    return 2;
  } else if (rune >= NUMERAL_ZERO_RUNE && rune <= NUMERAL_NINE_RUNE) {
    return 4;
  } else {
    return 0;
  }
}
function charClassOfNonAscii(rune) {
  const char = String.fromCodePoint(rune);
  if (char !== char.toUpperCase()) {
    return 1;
  } else if (char !== char.toLowerCase()) {
    return 2;
  } else if (char.match(/\p{Number}/gu) !== null) {
    return 4;
  } else if (char.match(/\p{Letter}/gu) !== null) {
    return 3;
  }
  return 0;
}
function charClassOf(rune) {
  if (rune <= MAX_ASCII) {
    return charClassOfAscii(rune);
  }
  return charClassOfNonAscii(rune);
}
function bonusFor(prevClass, currClass) {
  if (prevClass === 0 && currClass !== 0) {
    return BONUS_BOUNDARY;
  } else if (prevClass === 1 && currClass === 2 || prevClass !== 4 && currClass === 4) {
    return BONUS_CAMEL_123;
  } else if (currClass === 0) {
    return BONUS_NON_WORD;
  }
  return 0;
}
function bonusAt(input, idx) {
  if (idx === 0) {
    return BONUS_BOUNDARY;
  }
  return bonusFor(charClassOf(input[idx - 1]), charClassOf(input[idx]));
}
function trySkip(input, caseSensitive, char, from) {
  let rest = input.slice(from);
  let idx = rest.indexOf(char);
  if (idx === 0) {
    return from;
  }
  if (!caseSensitive && char >= SMALL_A_RUNE && char <= SMALL_Z_RUNE) {
    if (idx > 0) {
      rest = rest.slice(0, idx);
    }
    const uidx = rest.indexOf(char - 32);
    if (uidx >= 0) {
      idx = uidx;
    }
  }
  if (idx < 0) {
    return -1;
  }
  return from + idx;
}
function isAscii(runes) {
  for (const rune of runes) {
    if (rune >= 128) {
      return false;
    }
  }
  return true;
}
function asciiFuzzyIndex(input, pattern, caseSensitive) {
  if (!isAscii(input)) {
    return 0;
  }
  if (!isAscii(pattern)) {
    return -1;
  }
  let firstIdx = 0, idx = 0;
  for (let pidx = 0; pidx < pattern.length; pidx++) {
    idx = trySkip(input, caseSensitive, pattern[pidx], idx);
    if (idx < 0) {
      return -1;
    }
    if (pidx === 0 && idx > 0) {
      firstIdx = idx - 1;
    }
    idx++;
  }
  return firstIdx;
}
const fuzzyMatchV2 = (caseSensitive, normalize, forward, input, pattern, withPos, slab2) => {
  const M = pattern.length;
  if (M === 0) {
    return [{ start: 0, end: 0, score: 0 }, createPosSet(withPos)];
  }
  const N = input.length;
  if (slab2 !== null && N * M > slab2.i16.length) {
    return fuzzyMatchV1(caseSensitive, normalize, forward, input, pattern, withPos);
  }
  const idx = asciiFuzzyIndex(input, pattern, caseSensitive);
  if (idx < 0) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  let offset16 = 0, offset32 = 0, H0 = null, C0 = null, B = null, F = null;
  [offset16, H0] = alloc16(offset16, slab2, N);
  [offset16, C0] = alloc16(offset16, slab2, N);
  [offset16, B] = alloc16(offset16, slab2, N);
  [offset32, F] = alloc32(offset32, slab2, M);
  const [, T] = alloc32(offset32, slab2, N);
  for (let i = 0; i < T.length; i++) {
    T[i] = input[i];
  }
  let maxScore = toShort(0), maxScorePos = 0;
  let pidx = 0, lastIdx = 0;
  const pchar0 = pattern[0];
  let pchar = pattern[0], prevH0 = toShort(0), prevCharClass = 0, inGap = false;
  let Tsub = T.subarray(idx);
  let H0sub = H0.subarray(idx).subarray(0, Tsub.length), C0sub = C0.subarray(idx).subarray(0, Tsub.length), Bsub = B.subarray(idx).subarray(0, Tsub.length);
  for (let [off, char] of Tsub.entries()) {
    let charClass = null;
    if (char <= MAX_ASCII) {
      charClass = charClassOfAscii(char);
      if (!caseSensitive && charClass === 2) {
        char += 32;
      }
    } else {
      charClass = charClassOfNonAscii(char);
      if (!caseSensitive && charClass === 2) {
        char = String.fromCodePoint(char).toLowerCase().codePointAt(0);
      }
      if (normalize) {
        char = normalizeRune(char);
      }
    }
    Tsub[off] = char;
    const bonus = bonusFor(prevCharClass, charClass);
    Bsub[off] = bonus;
    prevCharClass = charClass;
    if (char === pchar) {
      if (pidx < M) {
        F[pidx] = toInt(idx + off);
        pidx++;
        pchar = pattern[Math.min(pidx, M - 1)];
      }
      lastIdx = idx + off;
    }
    if (char === pchar0) {
      const score = SCORE_MATCH + bonus * BONUS_FIRST_CHAR_MULTIPLIER;
      H0sub[off] = score;
      C0sub[off] = 1;
      if (M === 1 && (forward && score > maxScore || !forward && score >= maxScore)) {
        maxScore = score;
        maxScorePos = idx + off;
        if (forward && bonus === BONUS_BOUNDARY) {
          break;
        }
      }
      inGap = false;
    } else {
      if (inGap) {
        H0sub[off] = maxInt16(prevH0 + SCORE_GAP_EXTENTION, 0);
      } else {
        H0sub[off] = maxInt16(prevH0 + SCORE_GAP_START, 0);
      }
      C0sub[off] = 0;
      inGap = true;
    }
    prevH0 = H0sub[off];
  }
  if (pidx !== M) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  if (M === 1) {
    const result = {
      start: maxScorePos,
      end: maxScorePos + 1,
      score: maxScore
    };
    if (!withPos) {
      return [result, null];
    }
    const pos2 = /* @__PURE__ */ new Set();
    pos2.add(maxScorePos);
    return [result, pos2];
  }
  const f0 = F[0];
  const width = lastIdx - f0 + 1;
  let H = null;
  [offset16, H] = alloc16(offset16, slab2, width * M);
  {
    const toCopy = H0.subarray(f0, lastIdx + 1);
    for (const [i, v] of toCopy.entries()) {
      H[i] = v;
    }
  }
  let [, C] = alloc16(offset16, slab2, width * M);
  {
    const toCopy = C0.subarray(f0, lastIdx + 1);
    for (const [i, v] of toCopy.entries()) {
      C[i] = v;
    }
  }
  const Fsub = F.subarray(1);
  const Psub = pattern.slice(1).slice(0, Fsub.length);
  for (const [off, f] of Fsub.entries()) {
    let inGap2 = false;
    const pchar2 = Psub[off], pidx2 = off + 1, row = pidx2 * width, Tsub2 = T.subarray(f, lastIdx + 1), Bsub2 = B.subarray(f).subarray(0, Tsub2.length), Csub = C.subarray(row + f - f0).subarray(0, Tsub2.length), Cdiag = C.subarray(row + f - f0 - 1 - width).subarray(0, Tsub2.length), Hsub = H.subarray(row + f - f0).subarray(0, Tsub2.length), Hdiag = H.subarray(row + f - f0 - 1 - width).subarray(0, Tsub2.length), Hleft = H.subarray(row + f - f0 - 1).subarray(0, Tsub2.length);
    Hleft[0] = 0;
    for (const [off2, char] of Tsub2.entries()) {
      const col = off2 + f;
      let s1 = 0, s2 = 0, consecutive = 0;
      if (inGap2) {
        s2 = Hleft[off2] + SCORE_GAP_EXTENTION;
      } else {
        s2 = Hleft[off2] + SCORE_GAP_START;
      }
      if (pchar2 === char) {
        s1 = Hdiag[off2] + SCORE_MATCH;
        let b = Bsub2[off2];
        consecutive = Cdiag[off2] + 1;
        if (b === BONUS_BOUNDARY) {
          consecutive = 1;
        } else if (consecutive > 1) {
          b = maxInt16(b, maxInt16(BONUS_CONSECUTIVE, B[col - consecutive + 1]));
        }
        if (s1 + b < s2) {
          s1 += Bsub2[off2];
          consecutive = 0;
        } else {
          s1 += b;
        }
      }
      Csub[off2] = consecutive;
      inGap2 = s1 < s2;
      const score = maxInt16(maxInt16(s1, s2), 0);
      if (pidx2 === M - 1 && (forward && score > maxScore || !forward && score >= maxScore)) {
        maxScore = score;
        maxScorePos = col;
      }
      Hsub[off2] = score;
    }
  }
  const pos = createPosSet(withPos);
  let j = f0;
  if (withPos && pos !== null) {
    let i = M - 1;
    j = maxScorePos;
    let preferMatch = true;
    while (true) {
      const I = i * width, j0 = j - f0, s = H[I + j0];
      let s1 = 0, s2 = 0;
      if (i > 0 && j >= F[i]) {
        s1 = H[I - width + j0 - 1];
      }
      if (j > F[i]) {
        s2 = H[I + j0 - 1];
      }
      if (s > s1 && (s > s2 || s === s2 && preferMatch)) {
        pos.add(j);
        if (i === 0) {
          break;
        }
        i--;
      }
      preferMatch = C[I + j0] > 1 || I + width + j0 + 1 < C.length && C[I + width + j0 + 1] > 0;
      j--;
    }
  }
  return [{ start: j, end: maxScorePos + 1, score: maxScore }, pos];
};
function calculateScore(caseSensitive, normalize, text, pattern, sidx, eidx, withPos) {
  let pidx = 0, score = 0, inGap = false, consecutive = 0, firstBonus = toShort(0);
  const pos = createPosSet(withPos);
  let prevCharClass = 0;
  if (sidx > 0) {
    prevCharClass = charClassOf(text[sidx - 1]);
  }
  for (let idx = sidx; idx < eidx; idx++) {
    let rune = text[idx];
    const charClass = charClassOf(rune);
    if (!caseSensitive) {
      if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
        rune += 32;
      } else if (rune > MAX_ASCII) {
        rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
      }
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    if (rune === pattern[pidx]) {
      if (withPos && pos !== null) {
        pos.add(idx);
      }
      score += SCORE_MATCH;
      let bonus = bonusFor(prevCharClass, charClass);
      if (consecutive === 0) {
        firstBonus = bonus;
      } else {
        if (bonus === BONUS_BOUNDARY) {
          firstBonus = bonus;
        }
        bonus = maxInt16(maxInt16(bonus, firstBonus), BONUS_CONSECUTIVE);
      }
      if (pidx === 0) {
        score += bonus * BONUS_FIRST_CHAR_MULTIPLIER;
      } else {
        score += bonus;
      }
      inGap = false;
      consecutive++;
      pidx++;
    } else {
      if (inGap) {
        score += SCORE_GAP_EXTENTION;
      } else {
        score += SCORE_GAP_START;
      }
      inGap = true;
      consecutive = 0;
      firstBonus = 0;
    }
    prevCharClass = charClass;
  }
  return [score, pos];
}
function fuzzyMatchV1(caseSensitive, normalize, forward, text, pattern, withPos, slab2) {
  if (pattern.length === 0) {
    return [{ start: 0, end: 0, score: 0 }, null];
  }
  if (asciiFuzzyIndex(text, pattern, caseSensitive) < 0) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  let pidx = 0, sidx = -1, eidx = -1;
  const lenRunes = text.length;
  const lenPattern = pattern.length;
  for (let index = 0; index < lenRunes; index++) {
    let rune = text[indexAt(index, lenRunes, forward)];
    if (!caseSensitive) {
      if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
        rune += 32;
      } else if (rune > MAX_ASCII) {
        rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
      }
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    const pchar = pattern[indexAt(pidx, lenPattern, forward)];
    if (rune === pchar) {
      if (sidx < 0) {
        sidx = index;
      }
      pidx++;
      if (pidx === lenPattern) {
        eidx = index + 1;
        break;
      }
    }
  }
  if (sidx >= 0 && eidx >= 0) {
    pidx--;
    for (let index = eidx - 1; index >= sidx; index--) {
      const tidx = indexAt(index, lenRunes, forward);
      let rune = text[tidx];
      if (!caseSensitive) {
        if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
          rune += 32;
        } else if (rune > MAX_ASCII) {
          rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
        }
      }
      const pidx_ = indexAt(pidx, lenPattern, forward);
      const pchar = pattern[pidx_];
      if (rune === pchar) {
        pidx--;
        if (pidx < 0) {
          sidx = index;
          break;
        }
      }
    }
    if (!forward) {
      const sidxTemp = sidx;
      sidx = lenRunes - eidx;
      eidx = lenRunes - sidxTemp;
    }
    const [score, pos] = calculateScore(
      caseSensitive,
      normalize,
      text,
      pattern,
      sidx,
      eidx,
      withPos
    );
    return [{ start: sidx, end: eidx, score }, pos];
  }
  return [{ start: -1, end: -1, score: 0 }, null];
};
const exactMatchNaive = (caseSensitive, normalize, forward, text, pattern, withPos, slab2) => {
  if (pattern.length === 0) {
    return [{ start: 0, end: 0, score: 0 }, null];
  }
  const lenRunes = text.length;
  const lenPattern = pattern.length;
  if (lenRunes < lenPattern) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  if (asciiFuzzyIndex(text, pattern, caseSensitive) < 0) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  let pidx = 0;
  let bestPos = -1, bonus = toShort(0), bestBonus = toShort(-1);
  for (let index = 0; index < lenRunes; index++) {
    const index_ = indexAt(index, lenRunes, forward);
    let rune = text[index_];
    if (!caseSensitive) {
      if (rune >= CAPITAL_A_RUNE && rune <= CAPITAL_Z_RUNE) {
        rune += 32;
      } else if (rune > MAX_ASCII) {
        rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
      }
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    const pidx_ = indexAt(pidx, lenPattern, forward);
    const pchar = pattern[pidx_];
    if (pchar === rune) {
      if (pidx_ === 0) {
        bonus = bonusAt(text, index_);
      }
      pidx++;
      if (pidx === lenPattern) {
        if (bonus > bestBonus) {
          bestPos = index;
          bestBonus = bonus;
        }
        if (bonus === BONUS_BOUNDARY) {
          break;
        }
        index -= pidx - 1;
        pidx = 0;
        bonus = 0;
      }
    } else {
      index -= pidx;
      pidx = 0;
      bonus = 0;
    }
  }
  if (bestPos >= 0) {
    let sidx = 0, eidx = 0;
    if (forward) {
      sidx = bestPos - lenPattern + 1;
      eidx = bestPos + 1;
    } else {
      sidx = lenRunes - (bestPos + 1);
      eidx = lenRunes - (bestPos - lenPattern + 1);
    }
    const [score] = calculateScore(caseSensitive, normalize, text, pattern, sidx, eidx, false);
    return [{ start: sidx, end: eidx, score }, null];
  }
  return [{ start: -1, end: -1, score: 0 }, null];
};
const prefixMatch = (caseSensitive, normalize, forward, text, pattern, withPos, slab2) => {
  if (pattern.length === 0) {
    return [{ start: 0, end: 0, score: 0 }, null];
  }
  let trimmedLen = 0;
  if (!isWhitespace(pattern[0])) {
    trimmedLen = whitespacesAtStart(text);
  }
  if (text.length - trimmedLen < pattern.length) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  for (const [index, r] of pattern.entries()) {
    let rune = text[trimmedLen + index];
    if (!caseSensitive) {
      rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    if (rune !== r) {
      return [{ start: -1, end: -1, score: 0 }, null];
    }
  }
  const lenPattern = pattern.length;
  const [score] = calculateScore(
    caseSensitive,
    normalize,
    text,
    pattern,
    trimmedLen,
    trimmedLen + lenPattern,
    false
  );
  return [{ start: trimmedLen, end: trimmedLen + lenPattern, score }, null];
};
const suffixMatch = (caseSensitive, normalize, forward, text, pattern, withPos, slab2) => {
  const lenRunes = text.length;
  let trimmedLen = lenRunes;
  if (pattern.length === 0 || !isWhitespace(pattern[pattern.length - 1])) {
    trimmedLen -= whitespacesAtEnd(text);
  }
  if (pattern.length === 0) {
    return [{ start: trimmedLen, end: trimmedLen, score: 0 }, null];
  }
  const diff = trimmedLen - pattern.length;
  if (diff < 0) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  for (const [index, r] of pattern.entries()) {
    let rune = text[index + diff];
    if (!caseSensitive) {
      rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
    }
    if (normalize) {
      rune = normalizeRune(rune);
    }
    if (rune !== r) {
      return [{ start: -1, end: -1, score: 0 }, null];
    }
  }
  const lenPattern = pattern.length;
  const sidx = trimmedLen - lenPattern;
  const eidx = trimmedLen;
  const [score] = calculateScore(caseSensitive, normalize, text, pattern, sidx, eidx, false);
  return [{ start: sidx, end: eidx, score }, null];
};
const equalMatch = (caseSensitive, normalize, forward, text, pattern, withPos, slab2) => {
  const lenPattern = pattern.length;
  if (lenPattern === 0) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  let trimmedLen = 0;
  if (!isWhitespace(pattern[0])) {
    trimmedLen = whitespacesAtStart(text);
  }
  let trimmedEndLen = 0;
  if (!isWhitespace(pattern[lenPattern - 1])) {
    trimmedEndLen = whitespacesAtEnd(text);
  }
  if (text.length - trimmedLen - trimmedEndLen != lenPattern) {
    return [{ start: -1, end: -1, score: 0 }, null];
  }
  let match = true;
  if (normalize) {
    const runes = text;
    for (const [idx, pchar] of pattern.entries()) {
      let rune = runes[trimmedLen + idx];
      if (!caseSensitive) {
        rune = String.fromCodePoint(rune).toLowerCase().codePointAt(0);
      }
      if (normalizeRune(pchar) !== normalizeRune(rune)) {
        match = false;
        break;
      }
    }
  } else {
    let runesStr = runesToStr(text).substring(trimmedLen, text.length - trimmedEndLen);
    if (!caseSensitive) {
      runesStr = runesStr.toLowerCase();
    }
    match = runesStr === runesToStr(pattern);
  }
  if (match) {
    return [
      {
        start: trimmedLen,
        end: trimmedLen + lenPattern,
        score: (SCORE_MATCH + BONUS_BOUNDARY) * lenPattern + (BONUS_FIRST_CHAR_MULTIPLIER - 1) * BONUS_BOUNDARY
      },
      null
    ];
  }
  return [{ start: -1, end: -1, score: 0 }, null];
};
const SLAB_16_SIZE = 100 * 1024;
const SLAB_32_SIZE = 2048;
function makeSlab(size16, size32) {
  return {
    i16: new Int16Array(size16),
    i32: new Int32Array(size32)
  };
}
const slab = makeSlab(SLAB_16_SIZE, SLAB_32_SIZE);
var TermType = /* @__PURE__ */ ((TermType2) => {
  TermType2[TermType2["Fuzzy"] = 0] = "Fuzzy";
  TermType2[TermType2["Exact"] = 1] = "Exact";
  TermType2[TermType2["Prefix"] = 2] = "Prefix";
  TermType2[TermType2["Suffix"] = 3] = "Suffix";
  TermType2[TermType2["Equal"] = 4] = "Equal";
  return TermType2;
})(TermType || {});
const termTypeMap = {
  [0]: fuzzyMatchV2,
  [1]: exactMatchNaive,
  [2]: prefixMatch,
  [3]: suffixMatch,
  [4]: equalMatch
};
function buildPatternForExtendedMatch(fuzzy, caseMode, normalize, str) {
  let cacheable = true;
  str = str.trimLeft();
  {
    const trimmedAtRightStr = str.trimRight();
    if (trimmedAtRightStr.endsWith("\\") && str[trimmedAtRightStr.length] === " ") {
      str = trimmedAtRightStr + " ";
    } else {
      str = trimmedAtRightStr;
    }
  }
  let sortable = false;
  let termSets = [];
  termSets = parseTerms(fuzzy, caseMode, normalize, str);
  Loop:
    for (const termSet of termSets) {
      for (const [idx, term] of termSet.entries()) {
        if (!term.inv) {
          sortable = true;
        }
        if (!cacheable || idx > 0 || term.inv || fuzzy && term.typ !== 0 || !fuzzy && term.typ !== 1) {
          cacheable = false;
          if (sortable) {
            break Loop;
          }
        }
      }
    }
  return {
    str,
    termSets,
    sortable,
    cacheable,
    fuzzy
  };
}
function parseTerms(fuzzy, caseMode, normalize, str) {
  str = str.replace(/\\ /g, "	");
  const tokens = str.split(/ +/);
  const sets = [];
  let set = [];
  let switchSet = false;
  let afterBar = false;
  for (const token of tokens) {
    let typ = 0, inv = false, text = token.replace(/\t/g, " ");
    const lowerText = text.toLowerCase();
    const caseSensitive = caseMode === "case-sensitive" || caseMode === "smart-case" && text !== lowerText;
    const normalizeTerm = normalize && lowerText === runesToStr(strToRunes(lowerText).map(normalizeRune));
    if (!caseSensitive) {
      text = lowerText;
    }
    if (!fuzzy) {
      typ = 1;
    }
    if (set.length > 0 && !afterBar && text === "|") {
      switchSet = false;
      afterBar = true;
      continue;
    }
    afterBar = false;
    if (text.startsWith("!")) {
      inv = true;
      typ = 1;
      text = text.substring(1);
    }
    if (text !== "$" && text.endsWith("$")) {
      typ = 3;
      text = text.substring(0, text.length - 1);
    }
    if (text.startsWith("'")) {
      if (fuzzy && !inv) {
        typ = 1;
      } else {
        typ = 0;
      }
      text = text.substring(1);
    } else if (text.startsWith("^")) {
      if (typ === 3) {
        typ = 4;
      } else {
        typ = 2;
      }
      text = text.substring(1);
    }
    if (text.length > 0) {
      if (switchSet) {
        sets.push(set);
        set = [];
      }
      let textRunes = strToRunes(text);
      if (normalizeTerm) {
        textRunes = textRunes.map(normalizeRune);
      }
      set.push({
        typ,
        inv,
        text: textRunes,
        caseSensitive,
        normalize: normalizeTerm
      });
      switchSet = true;
    }
  }
  if (set.length > 0) {
    sets.push(set);
  }
  return sets;
}
const buildPatternForBasicMatch = (query, casing, normalize) => {
  let caseSensitive = false;
  switch (casing) {
    case "smart-case":
      if (query.toLowerCase() !== query) {
        caseSensitive = true;
      }
      break;
    case "case-sensitive":
      caseSensitive = true;
      break;
    case "case-insensitive":
      query = query.toLowerCase();
      caseSensitive = false;
      break;
  }
  let queryRunes = strToRunes(query);
  if (normalize) {
    queryRunes = queryRunes.map(normalizeRune);
  }
  return {
    queryRunes,
    caseSensitive
  };
};
function iter(algoFn, tokens, caseSensitive, normalize, forward, pattern, slab2) {
  for (const part of tokens) {
    const [res, pos] = algoFn(caseSensitive, normalize, forward, part.text, pattern, true, slab2);
    if (res.start >= 0) {
      const sidx = res.start + part.prefixLength;
      const eidx = res.end + part.prefixLength;
      if (pos !== null) {
        const newPos = /* @__PURE__ */ new Set();
        pos.forEach((v) => newPos.add(part.prefixLength + v));
        return [[sidx, eidx], res.score, newPos];
      }
      return [[sidx, eidx], res.score, pos];
    }
  }
  return [[-1, -1], 0, null];
}
function computeExtendedMatch(text, pattern, fuzzyAlgo, forward) {
  const input = [
    {
      text,
      prefixLength: 0
    }
  ];
  const offsets = [];
  let totalScore = 0;
  const allPos = /* @__PURE__ */ new Set();
  for (const termSet of pattern.termSets) {
    let offset = [0, 0];
    let currentScore = 0;
    let matched = false;
    for (const term of termSet) {
      let algoFn = termTypeMap[term.typ];
      if (term.typ === TermType.Fuzzy) {
        algoFn = fuzzyAlgo;
      }
      const [off, score, pos] = iter(
        algoFn,
        input,
        term.caseSensitive,
        term.normalize,
        forward,
        term.text,
        slab
      );
      const sidx = off[0];
      if (sidx >= 0) {
        if (term.inv) {
          continue;
        }
        offset = off;
        currentScore = score;
        matched = true;
        if (pos !== null) {
          pos.forEach((v) => allPos.add(v));
        } else {
          for (let idx = off[0]; idx < off[1]; ++idx) {
            allPos.add(idx);
          }
        }
        break;
      } else if (term.inv) {
        offset = [0, 0];
        currentScore = 0;
        matched = true;
        continue;
      }
    }
    if (matched) {
      offsets.push(offset);
      totalScore += currentScore;
    }
  }
  return { offsets, totalScore, allPos };
}
function getResultFromScoreMap(scoreMap, limit) {
  const scoresInDesc = Object.keys(scoreMap).map((v) => parseInt(v, 10)).sort((a, b) => b - a);
  let result = [];
  for (const score of scoresInDesc) {
    result = result.concat(scoreMap[score]);
    if (result.length >= limit) {
      break;
    }
  }
  return result;
}
function getBasicMatchIter(scoreMap, queryRunes, caseSensitive) {
  return (idx) => {
    const itemRunes = this.runesList[idx];
    if (queryRunes.length > itemRunes.length)
      return;
    let [match, positions] = this.algoFn(
      caseSensitive,
      this.opts.normalize,
      this.opts.forward,
      itemRunes,
      queryRunes,
      true,
      slab
    );
    if (match.start === -1)
      return;
    if (this.opts.fuzzy === false) {
      positions = /* @__PURE__ */ new Set();
      for (let position = match.start; position < match.end; ++position) {
        positions.add(position);
      }
    }
    const scoreKey = this.opts.sort ? match.score : 0;
    if (scoreMap[scoreKey] === void 0) {
      scoreMap[scoreKey] = [];
    }
    scoreMap[scoreKey].push(Object.assign({
      item: this.items[idx],
      positions: positions != null ? positions : /* @__PURE__ */ new Set()
    }, match));
  };
}
function getExtendedMatchIter(scoreMap, pattern) {
  return (idx) => {
    const runes = this.runesList[idx];
    const match = computeExtendedMatch(runes, pattern, this.algoFn, this.opts.forward);
    if (match.offsets.length !== pattern.termSets.length)
      return;
    let sidx = -1, eidx = -1;
    if (match.allPos.size > 0) {
      sidx = Math.min(...match.allPos);
      eidx = Math.max(...match.allPos) + 1;
    }
    const scoreKey = this.opts.sort ? match.totalScore : 0;
    if (scoreMap[scoreKey] === void 0) {
      scoreMap[scoreKey] = [];
    }
    scoreMap[scoreKey].push({
      score: match.totalScore,
      item: this.items[idx],
      positions: match.allPos,
      start: sidx,
      end: eidx
    });
  };
}
function basicMatch(query) {
  const { queryRunes, caseSensitive } = buildPatternForBasicMatch(
    query,
    this.opts.casing,
    this.opts.normalize
  );
  const scoreMap = {};
  const iter2 = getBasicMatchIter.bind(this)(
    scoreMap,
    queryRunes,
    caseSensitive
  );
  for (let i = 0, len = this.runesList.length; i < len; ++i) {
    iter2(i);
  }
  return getResultFromScoreMap(scoreMap, this.opts.limit);
}
function extendedMatch(query) {
  const pattern = buildPatternForExtendedMatch(
    Boolean(this.opts.fuzzy),
    this.opts.casing,
    this.opts.normalize,
    query
  );
  const scoreMap = {};
  const iter2 = getExtendedMatchIter.bind(this)(scoreMap, pattern);
  for (let i = 0, len = this.runesList.length; i < len; ++i) {
    iter2(i);
  }
  return getResultFromScoreMap(scoreMap, this.opts.limit);
}
const defaultOpts = {
  limit: Infinity,
  selector: (v) => v,
  casing: "smart-case",
  normalize: true,
  fuzzy: "v2",
  tiebreakers: [],
  sort: true,
  forward: true,
  match: basicMatch
};
class Finder {
  constructor(list, ...optionsTuple) {
    this.opts = Object.assign(defaultOpts, optionsTuple[0]);
    this.items = list;
    this.runesList = list.map((item) => strToRunes(this.opts.selector(item).normalize()));
    this.algoFn = exactMatchNaive;
    switch (this.opts.fuzzy) {
      case "v2":
        this.algoFn = fuzzyMatchV2;
        break;
      case "v1":
        this.algoFn = fuzzyMatchV1;
        break;
    }
  }
  find(query) {
    if (query.length === 0 || this.items.length === 0)
      return this.items.slice(0, this.opts.limit).map(createResultItemWithEmptyPos);
    query = query.normalize();
    let result = this.opts.match.bind(this)(query);
    return postProcessResultItems(result, this.opts);
  }
}
function createResultItemWithEmptyPos(item) {
  return ({
    item,
    start: -1,
    end: -1,
    score: 0,
    positions: /* @__PURE__ */ new Set()
  })
};
function postProcessResultItems(result, opts) {
  if (opts.sort) {
    const { selector } = opts;
    result.sort((a, b) => {
      if (a.score === b.score) {
        for (const tiebreaker of opts.tiebreakers) {
          const diff = tiebreaker(a, b, selector);
          if (diff !== 0) {
            return diff;
          }
        }
      }
      return 0;
    });
  }
  if (Number.isFinite(opts.limit)) {
    result.splice(opts.limit);
  }
  return result;
}
function byLengthAsc(a, b, selector) {
  return selector(a.item).length - selector(b.item).length;
}
function byStartAsc(a, b) {
  return a.start - b.start;
}
