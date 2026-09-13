/** Bounded ISO-BMFF inspection. Only actual sample descriptions count as codecs;
 * arbitrary strings in a payload cannot satisfy this check. */
export function inspectMp4(bytes: Buffer): { durationSeconds: number } {
  const fail = () => { throw new Error("MP4 H.264 avec audio AAC requis."); };
  let video = false, audio = false, ftyp = false, media = false, duration = 0;
  function boxes(start: number, end: number, depth: number, visit: (type: string, from: number, to: number) => void) {
    if (depth > 10) fail();
    for (let p = start; p < end;) {
      if (p + 8 > end) fail();
      let size = bytes.readUInt32BE(p), header = 8;
      if (size === 1) {
        if (p + 16 > end) fail();
        const large = bytes.readBigUInt64BE(p + 8);
        if (large > BigInt(Number.MAX_SAFE_INTEGER)) fail();
        size = Number(large); header = 16;
      } else if (size === 0) size = end - p;
      if (size < header || p + size > end) fail();
      visit(bytes.toString("ascii", p + 4, p + 8), p + header, p + size);
      p += size;
    }
  }
  function walk(start: number, end: number, depth: number) {
    boxes(start, end, depth, (type, from, to) => {
      if (depth === 0 && type === "mdat" && to > from) media = true;
      if (depth === 0 && type === "ftyp" && to - from >= 8) ftyp = true;
      if (["moov", "trak", "mdia", "minf", "stbl"].includes(type)) walk(from, to, depth + 1);
      if (type === "mvhd") {
        const version = bytes[from];
        if (version !== 0 && version !== 1) fail();
        const offset = from + (version === 1 ? 20 : 12);
        if (offset + (version === 1 ? 12 : 8) > to) fail();
        const scale = bytes.readUInt32BE(offset);
        const ticks = version === 1 ? Number(bytes.readBigUInt64BE(offset + 4)) : bytes.readUInt32BE(offset + 4);
        duration = scale > 0 ? ticks / scale : 0;
      }
      if (type === "stsd") {
        if (from + 8 > to) fail();
        let entries = 0;
        boxes(from + 8, to, depth + 1, (codec, sample, sampleEnd) => {
          entries++;
          if (["avc1", "avc3"].includes(codec)) {
            if (sample + 78 > sampleEnd) fail();
            let config = false;
            boxes(sample + 78, sampleEnd, depth + 2, (child, a, b) => {
              if (child === "avcC" && b - a >= 7 && bytes[a] === 1) config = true;
            });
            if (!config) fail();
            video = true;
          } else if (codec === "mp4a") {
            if (sample + 28 > sampleEnd) fail();
            // MPEG-4 audio sample entry; AAC AudioSpecificConfig is carried by esds.
            let aac = false;
            boxes(sample + 28, sampleEnd, depth + 2, (child, a, b) => {
              if (child !== "esds" || b - a < 8) return;
              // Decode descriptor TLVs, including variable-length sizes.
              function descriptors(x: number, limit: number, nesting: number) {
                if (nesting > 8) fail();
                while (x < limit) {
                  const tag = bytes[x++]; let length = 0, count = 0, v: number;
                  do { if (x >= limit || count++ === 4) fail(); v = bytes[x++]; length = length * 128 + (v & 127); } while (v & 128);
                  const finish = x + length;
                  if (finish > limit) fail();
                  if (tag === 3) {
                    if (x + 3 > finish) fail();
                    const flags = bytes[x + 2]; let nested = x + 3;
                    if (flags & 128) nested += 2;
                    if (flags & 64) nested += 1 + bytes[nested];
                    if (flags & 32) nested += 2;
                    if (nested > finish) fail();
                    descriptors(nested, finish, nesting + 1);
                  } else if (tag === 4) {
                    if (x + 13 > finish || bytes[x] !== 0x40) fail();
                    descriptors(x + 13, finish, nesting + 1);
                  } else if (tag === 5 && length >= 2) {
                    const objectType = bytes[x] >> 3;
                    aac = [1, 2, 3, 4, 5, 6, 17, 23, 29, 39].includes(objectType);
                  }
                  x = finish;
                }
              }
              descriptors(a + 4, b, 0);
            });
            if (!aac) fail();
            audio = true;
          } else fail();
        });
        if (entries !== bytes.readUInt32BE(from + 4)) fail();
      }
    });
  }
  if (bytes.length < 32 || bytes.length > 150 * 1024 * 1024) fail();
  walk(0, bytes.length, 0);
  if (!ftyp || !media || !video || !audio || !Number.isFinite(duration) || duration <= 0) fail();
  return { durationSeconds: Math.ceil(duration) };
}
