# Third-party notices

## Madinah Mushaf page artwork and metadata

The Quran reading view displays the 604-page Hafs/KFQC SVG edition published
by the `quran-ws/quran-svg` project. All 604 canonical page SVGs and the
bundled `surah.json` and `markers.json` metadata files are copied verbatim
from upstream commit `9fc0c87aebd7e528ceb90706707d6e5e9d2d698b`:
<https://github.com/quran-ws/quran-svg/tree/9fc0c87aebd7e528ceb90706707d6e5e9d2d698b/mushafs/hafs/kfqc>

Each SVG is stored as a losslessly compressed BZip2 asset under
`assets/quran/mushaf/hafs_kfqc/pages_bz2/`; no network request is required to
open any Mushaf page. Decompression restores the exact pinned SVG bytes before
rendering. Per-page SHA-256 values for those restored originals are recorded
in `assets/data/quran/mushaf_hafs_kfqc_pages.sha256`.

Bundled metadata SHA-256 values:

- `mushaf_hafs_kfqc_markers.json`:
  `7444562F81A9844463B4178A6E014972834FC2DF9C3A9A8E5C45CB1776AB93C8`
- `mushaf_hafs_kfqc_surahs.json`:
  `B939433E9AD3EBD93925F1A7721CE572570E353A8B7A3685FBA9E1A4C2345F63`

The page artwork is derived from the King Fahd Glorious Qur'an Printing
Complex (KFQC) digital Madinah Mushaf. KFQC's published usage terms permit
free use in digital publishing, media, websites, software, and similar
intermediaries. The upstream notice, including the separate restriction on
commercial physical printing in or import into Saudi Arabia, is available at:
<https://github.com/quran-ws/quran-svg/blob/9fc0c87aebd7e528ceb90706707d6e5e9d2d698b/NOTICE.md>

At that pinned revision, the `quran-ws` metadata and ayah hit-layer are
dedicated to the public domain under CC0 1.0. This notice is retained for
provenance and correction tracking. Sakinah does not alter or reconstruct the
page artwork.

## flutter_svg

`flutter_svg` is distributed under the MIT License. It is used to render the
unmodified SVG page artwork with aspect-preserving scaling.

## archive

`archive` is distributed under the BSD 3-Clause License. It is used only to
losslessly decompress the bundled Mushaf pages before rendering.

## Noto Naskh Arabic font

`assets/fonts/NotoNaskhArabic-Variable.ttf` is distributed by the Noto
Project under the SIL Open Font License 1.1. The complete license is included
at `assets/fonts/OFL-NotoNaskhArabic.txt`.

## Takbeer notification sound

`android/app/src/main/res/raw/takbeer_notification.mp3` is an MP3 transcode of
“Allahuakbar.opus” by Wikimedia Commons user Bod lnga klang:
<https://commons.wikimedia.org/wiki/File:Allahuakbar.opus>

The source recording is dedicated to the public domain under CC0 1.0.

## Azkar data

The files under `assets/data/azkar/` are bundled verbatim from these sources:

- `morning_evening.json`: Seen Arabic, Morning-And-Evening-Adhkar-DB,
  <https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB>
- `after_salah.json` and `daily_dua.json`: Fitrahive, Dua & Dhikr,
  <https://github.com/fitrahive/dua-dhikr>

Both datasets are derived from *Hisn al-Muslim* (Fortress of the Muslim) by
Sa'id ibn Ali ibn Wahf al-Qahtani. Both upstream repositories distribute their
data under the MIT License.

### Seen Arabic license

MIT License

Copyright (c) 2024 Seen Arabic

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### Fitrahive license

MIT License

Copyright (c) 2023 Fitrahive

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
