using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;

// Turns Codex's large painted images into game-ready pixel sprites:
// key out the magenta background, find each item on a sheet, box-filter down to game size,
// snap alpha to on/off for crisp edges and reduce the colours to a small palette.
public static class ArtTool
{
    static int[] Load(string path, out int w, out int h)
    {
        using (var src = new Bitmap(path))
        {
            w = src.Width; h = src.Height; lastW = w;
            var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, w, h);
            var d = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            var px = new int[w * h]; Marshal.Copy(d.Scan0, px, 0, px.Length); bmp.UnlockBits(d); bmp.Dispose();
            return px;
        }
    }
    static void Save(int[] px, int w, int h, string path)
    {
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        {
            var d = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(px, 0, d.Scan0, px.Length); bmp.UnlockBits(d); bmp.Save(path, ImageFormat.Png);
        }
    }
    // magenta and its anti-aliased fringe become transparent
    static bool Magenta(int c) { int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255; return Math.Min(r, b) - g > 90 && r > 120 && b > 120; }
    // FloodKey: only magenta reachable from the image border is keyed (plus near-pure magenta anywhere), so violet
    // glows enclosed by an outline survive
    public static bool FloodKey = false;
    static void Key(int[] px)
    {
        if (!FloodKey) { for (int i = 0; i < px.Length; i++) if (Magenta(px[i])) px[i] = 0; return; }
        int n = px.Length, w = lastW, h = n / w; var seen = new bool[n]; var st = new Stack<int>();
        for (int x = 0; x < w; x++) { st.Push(x); st.Push((h - 1) * w + x); }
        for (int y = 0; y < h; y++) { st.Push(y * w); st.Push(y * w + w - 1); }
        while (st.Count > 0)
        {
            int i = st.Pop(); if (seen[i]) continue; seen[i] = true; if (!Magenta(px[i])) continue;
            int x = i % w, y = i / w; px[i] = 0;
            if (x > 0) st.Push(i - 1); if (x < w - 1) st.Push(i + 1); if (y > 0) st.Push(i - w); if (y < h - 1) st.Push(i + w);
        }
        for (int i = 0; i < n; i++) { int c = px[i], r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255; if (r > 225 && b > 225 && g < 40) px[i] = 0; }
    }
    static int lastW = 1;
    // box-filter a region down to (tw, th), alpha-weighted, then snap alpha
    static int[] Shrink(int[] px, int w, int x0, int y0, int rw, int rh, int tw, int th)
    {
        var o = new int[tw * th];
        for (int ty = 0; ty < th; ty++) for (int tx = 0; tx < tw; tx++)
        {
            int sx0 = x0 + tx * rw / tw, sx1 = Math.Max(sx0 + 1, x0 + (tx + 1) * rw / tw), sy0 = y0 + ty * rh / th, sy1 = Math.Max(sy0 + 1, y0 + (ty + 1) * rh / th);
            double ar = 0, ag = 0, ab = 0, aa = 0; int n = 0;
            for (int y = sy0; y < sy1; y++) for (int x = sx0; x < sx1; x++)
            {
                int c = px[y * w + x], a = (c >> 24) & 255; n++;
                if (a == 0) continue; aa += a; ar += ((c >> 16) & 255) * a; ag += ((c >> 8) & 255) * a; ab += (c & 255) * a;
            }
            if (n == 0 || aa / n < 110) { o[ty * tw + tx] = 0; continue; }
            // dominant colour of the block (bucketed), which keeps outlines and highlights crisp instead of averaging them away;
            // the plain average is only used when no colour dominates
            var votes = new Dictionary<int, int>(); var sums = new Dictionary<int, long[]>();
            for (int y = sy0; y < sy1; y++) for (int x = sx0; x < sx1; x++)
            {
                int c = px[y * w + x]; if (((c >> 24) & 255) == 0) continue;
                int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255, key = (r >> 4) << 8 | (g >> 4) << 4 | (b >> 4);
                int v; votes.TryGetValue(key, out v); votes[key] = v + 1;
                long[] s; if (!sums.TryGetValue(key, out s)) sums[key] = s = new long[3]; s[0] += r; s[1] += g; s[2] += b;
            }
            var top = votes.OrderByDescending(kv => kv.Value).First();
            if (top.Value * 4 >= votes.Values.Sum()) { var s = sums[top.Key]; o[ty * tw + tx] = unchecked((int)0xFF000000) | ((int)(s[0] / top.Value) << 16) | ((int)(s[1] / top.Value) << 8) | (int)(s[2] / top.Value); }
            else o[ty * tw + tx] = unchecked((int)0xFF000000) | ((int)(ar / aa) << 16) | ((int)(ag / aa) << 8) | (int)(ab / aa);
        }
        return o;
    }
    // remove pinkish pixels on the sprite's edge, left over from the magenta background blending in
    static void Defringe(int[] px, int w, int h)
    {
        for (int pass = 0; pass < 2; pass++)
        {
            var kill = new List<int>();
            for (int y = 0; y < h; y++) for (int x = 0; x < w; x++)
            {
                int i = y * w + x, c = px[i]; if (((c >> 24) & 255) == 0) continue;
                bool edge = x == 0 || y == 0 || x == w - 1 || y == h - 1 || px[i - 1] == 0 || px[i + 1] == 0 || px[i - w] == 0 || px[i + w] == 0;
                if (!edge) continue;
                int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
                if (Math.Min(r, b) - g > 40 && Math.Abs(r - b) < 70 && r > 120) kill.Add(i);
            }
            foreach (var i in kill) px[i] = 0;
        }
    }
    // k-means colour reduction on opaque pixels
    static void Quantize(int[] px, int k)
    {
        var cols = px.Where(c => ((c >> 24) & 255) != 0).ToArray(); if (cols.Length == 0) return;
        var rnd = new Random(7); k = Math.Min(k, cols.Length);
        var cen = new double[k, 3];
        for (int i = 0; i < k; i++) { int c = cols[rnd.Next(cols.Length)]; cen[i, 0] = (c >> 16) & 255; cen[i, 1] = (c >> 8) & 255; cen[i, 2] = c & 255; }
        Func<int, int> nearest = c => { int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255, best = 0; double bd = 1e18; for (int i = 0; i < k; i++) { double d = (r - cen[i, 0]) * (r - cen[i, 0]) * .3 + (g - cen[i, 1]) * (g - cen[i, 1]) * .59 + (b - cen[i, 2]) * (b - cen[i, 2]) * .11; if (d < bd) { bd = d; best = i; } } return best; };
        for (int it = 0; it < 12; it++)
        {
            var sum = new double[k, 4];
            foreach (var c in cols) { int j = nearest(c); sum[j, 0] += (c >> 16) & 255; sum[j, 1] += (c >> 8) & 255; sum[j, 2] += c & 255; sum[j, 3]++; }
            for (int i = 0; i < k; i++) if (sum[i, 3] > 0) { cen[i, 0] = sum[i, 0] / sum[i, 3]; cen[i, 1] = sum[i, 1] / sum[i, 3]; cen[i, 2] = sum[i, 2] / sum[i, 3]; }
        }
        for (int i = 0; i < px.Length; i++) if (((px[i] >> 24) & 255) != 0) { int j = nearest(px[i]); px[i] = unchecked((int)0xFF000000) | ((int)cen[j, 0] << 16) | ((int)cen[j, 1] << 8) | (int)cen[j, 2]; }
    }
    static int[] BBox(int[] px, int w, int h, int x0, int y0, int x1, int y1)
    {
        int minx = int.MaxValue, miny = int.MaxValue, maxx = -1, maxy = -1;
        for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) if (((px[y * w + x] >> 24) & 255) != 0) { if (x < minx) minx = x; if (y < miny) miny = y; if (x > maxx) maxx = x; if (y > maxy) maxy = y; }
        return maxx < 0 ? null : new[] { minx, miny, maxx + 1, maxy + 1 };
    }
    // one sprite: key, crop to content, shrink so the longer side is `size`
    public static string Sprite(string src, string dst, int size, int colors)
    {
        int w, h; var px = Load(src, out w, out h); Key(px);
        var bb = BBox(px, w, h, 0, 0, w, h); int bw = bb[2] - bb[0], bh = bb[3] - bb[1];
        int tw = bw >= bh ? size : Math.Max(1, size * bw / bh), th = bh >= bw ? size : Math.Max(1, size * bh / bw);
        var o = Shrink(px, w, bb[0], bb[1], bw, bh, tw, th); Defringe(o, tw, th); Quantize(o, colors); Save(o, tw, th, dst);
        return tw + "x" + th;
    }
    // one sprite squeezed to an exact tw x th (for pieces that must fit a set footprint, like a bridge over n tiles);
    // returns the natural crop size so the distortion can be checked
    public static string Fit(string src, string dst, int tw, int th, int colors)
    {
        int w, h; var px = Load(src, out w, out h); Key(px);
        var bb = BBox(px, w, h, 0, 0, w, h); int bw = bb[2] - bb[0], bh = bb[3] - bb[1];
        var o = Shrink(px, w, bb[0], bb[1], bw, bh, tw, th); Defringe(o, tw, th); Quantize(o, colors); Save(o, tw, th, dst);
        return bw + "x" + bh + " -> " + tw + "x" + th;
    }
    // clear the dark opening of a processed sprite (flood fill of near-black pixels from a seed), returns its bbox
    public static string ClearDark(string path, int sx, int sy)
    {
        int w, h; var px = Load(path, out w, out h); var seen = new bool[w * h]; var st = new Stack<int>(); st.Push(sy * w + sx);
        int mnx = w, mny = h, mxx = -1, mxy = -1;
        while (st.Count > 0)
        {
            int i = st.Pop(); if (seen[i]) continue; seen[i] = true; int c = px[i];
            if (((c >> 24) & 255) == 0) continue; int r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255; if (r + g + b > 90) continue;
            px[i] = 0; int x = i % w, y = i / w; mnx = Math.Min(mnx, x); mny = Math.Min(mny, y); mxx = Math.Max(mxx, x); mxy = Math.Max(mxy, y);
            if (x > 0) st.Push(i - 1); if (x < w - 1) st.Push(i + 1); if (y > 0) st.Push(i - w); if (y < h - 1) st.Push(i + w);
        }
        Save(px, w, h, path); return mnx + "," + mny + "," + (mxx + 1) + "," + (mxy + 1);
    }
    // a texture that fills the image: shrink to size x size
    public static string Texture(string src, string dst, int size, int colors)
    {
        int w, h; var px = Load(src, out w, out h);
        var o = Shrink(px, w, 0, 0, w, h, size, size); Quantize(o, colors); Save(o, size, size, dst);
        return size + "x" + size;
    }
    // an animation strip: n evenly spaced frames in one row. Each column is cropped to its content and every frame
    // is shrunk by the same factor, chosen so frame 0's longer side becomes `size`, so poses keep their true scale.
    public static string Strips(string src, string dstPrefix, int n, int size, int colors)
    {
        int w, h; var px = Load(src, out w, out h); Key(px);
        // in each column keep only the biggest connected shape, dropping slivers of the neighbouring frames
        for (int i = 0; i < n; i++)
        {
            int x0 = i * w / n, x1 = (i + 1) * w / n; var lab = new int[w * h]; int best = -1, bestN = 0, next = 0;
            var sizes = new List<int>();
            for (int y = 0; y < h; y++) for (int x = x0; x < x1; x++)
            {
                int s = y * w + x; if (lab[s] != 0 || ((px[s] >> 24) & 255) == 0) continue;
                next++; int cnt = 0; var st = new Stack<int>(); st.Push(s); lab[s] = next;
                while (st.Count > 0)
                {
                    int j = st.Pop(), jx = j % w, jy = j / w; cnt++;
                    for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
                    { int nx = jx + dx, ny = jy + dy; if (nx < x0 || ny < 0 || nx >= x1 || ny >= h) continue; int q = ny * w + nx; if (lab[q] == 0 && ((px[q] >> 24) & 255) != 0) { lab[q] = next; st.Push(q); } }
                }
                if (cnt > bestN) { bestN = cnt; best = next; }
            }
            for (int y = 0; y < h; y++) for (int x = x0; x < x1; x++) { int s = y * w + x; if (lab[s] != best) px[s] = 0; }
        }
        var boxes = new List<int[]>();
        for (int i = 0; i < n; i++) boxes.Add(BBox(px, w, h, i * w / n, 0, (i + 1) * w / n, h));
        var b0 = boxes[0]; double scale = (double)size / Math.Max(b0[2] - b0[0], b0[3] - b0[1]);
        var outp = new List<string>();
        for (int i = 0; i < n; i++)
        {
            var bb = boxes[i]; if (bb == null) { outp.Add(i + ":empty"); continue; }
            int bw = bb[2] - bb[0], bh = bb[3] - bb[1], tw = Math.Max(1, (int)Math.Round(bw * scale)), th = Math.Max(1, (int)Math.Round(bh * scale));
            var o = Shrink(px, w, bb[0], bb[1], bw, bh, tw, th); Defringe(o, tw, th); Quantize(o, colors); Save(o, tw, th, dstPrefix + i + ".png");
            outp.Add(i + ":" + tw + "x" + th);
        }
        return string.Join(" ", outp);
    }
    // An animation row cut by shape rather than by fixed columns: the n biggest connected figures are the frames
    // (left to right); every smaller piece (spores, sparkles, loose feathers) joins the frame it sits closest to.
    // Nothing is clipped at a column line, so wide wings stay whole. Scale comes from frame 0, as in Strips.
    public static string Frames(string src, string dstPrefix, int n, int size, int colors)
    {
        int w, h; var px = Load(src, out w, out h); Key(px);
        var lab = new int[w * h]; var cnt = new List<int> { 0 }; var bx = new List<int[]> { null }; var sx = new List<long> { 0 };
        for (int s = 0; s < px.Length; s++)
        {
            if (lab[s] != 0 || ((px[s] >> 24) & 255) == 0) continue;
            int id = cnt.Count, c = 0; long sumx = 0; int mnx = w, mny = h, mxx = 0, mxy = 0;
            var st = new Stack<int>(); st.Push(s); lab[s] = id;
            while (st.Count > 0)
            {
                int j = st.Pop(), jx = j % w, jy = j / w; c++; sumx += jx;
                if (jx < mnx) mnx = jx; if (jy < mny) mny = jy; if (jx > mxx) mxx = jx; if (jy > mxy) mxy = jy;
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
                { int nx = jx + dx, ny = jy + dy; if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue; int q = ny * w + nx; if (lab[q] == 0 && ((px[q] >> 24) & 255) != 0) { lab[q] = id; st.Push(q); } }
            }
            cnt.Add(c); bx.Add(new[] { mnx, mny, mxx + 1, mxy + 1 }); sx.Add(sumx);
        }
        // the n biggest figures are the frames, ordered left to right
        var ids = Enumerable.Range(1, cnt.Count - 1).OrderByDescending(i => cnt[i]).Take(n).OrderBy(i => sx[i] / (double)cnt[i]).ToList();
        if (ids.Count < n) return "only " + ids.Count + " figures";
        var owner = new int[cnt.Count];
        for (int k = 0; k < ids.Count; k++) owner[ids[k]] = k + 1;
        for (int i = 1; i < cnt.Count; i++)
        {
            if (owner[i] != 0) continue;
            if (cnt[i] < 25) continue;                                   // specks: dropped
            double cx = sx[i] / (double)cnt[i], best = 1e18; int bk = 0;
            for (int k = 0; k < ids.Count; k++) { var b = bx[ids[k]]; double dd = cx < b[0] ? b[0] - cx : cx > b[2] ? cx - b[2] : 0; if (dd < best) { best = dd; bk = k; } }
            owner[i] = bk + 1;
        }
        var boxes = new int[n][];
        for (int k = 0; k < n; k++) boxes[k] = new[] { w, h, -1, -1 };
        for (int i = 1; i < cnt.Count; i++) { int o = owner[i]; if (o == 0) continue; var b = bx[i]; var B = boxes[o - 1]; B[0] = Math.Min(B[0], b[0]); B[1] = Math.Min(B[1], b[1]); B[2] = Math.Max(B[2], b[2]); B[3] = Math.Max(B[3], b[3]); }
        double scale = (double)size / Math.Max(boxes[0][2] - boxes[0][0], boxes[0][3] - boxes[0][1]);
        var outp = new List<string>();
        for (int k = 0; k < n; k++)
        {
            // a copy of the sheet holding only this frame's pieces
            var fp = new int[px.Length];
            for (int s = 0; s < px.Length; s++) { int l = lab[s]; if (l != 0 && owner[l] == k + 1) fp[s] = px[s]; }
            var B = boxes[k]; int bw = B[2] - B[0], bh = B[3] - B[1], tw = Math.Max(1, (int)Math.Round(bw * scale)), th = Math.Max(1, (int)Math.Round(bh * scale));
            var o = Shrink(fp, w, B[0], B[1], bw, bh, tw, th); Defringe(o, tw, th); Quantize(o, colors); Save(o, tw, th, dstPrefix + k + ".png");
            outp.Add(k + ":" + tw + "x" + th);
        }
        return string.Join(" ", outp);
    }
    // a sheet: find items as clusters of opaque pixels (on a coarse grid), order them row by row,
    // and save each as its own sprite scaled by the same factor so relative sizes stay true
    public static string Sheet(string src, string dstPrefix, double scale, int colors)
    {
        int w, h; var px = Load(src, out w, out h); Key(px);
        int cs = 8, gw = w / cs, gh = h / cs; var occ = new bool[gw * gh];
        for (int gy = 0; gy < gh; gy++) for (int gx = 0; gx < gw; gx++)
        { int cnt = 0; for (int y = gy * cs; y < gy * cs + cs; y++) for (int x = gx * cs; x < gx * cs + cs; x++) if (((px[y * w + x] >> 24) & 255) != 0) cnt++; occ[gy * gw + gx] = cnt > 6; }
        var lab = new int[gw * gh]; var boxes = new List<int[]>(); int next = 0;
        for (int i = 0; i < occ.Length; i++)
        {
            if (!occ[i] || lab[i] != 0) continue; next++; var st = new Stack<int>(); st.Push(i); lab[i] = next;
            int mnx = gw, mny = gh, mxx = 0, mxy = 0, area = 0;
            while (st.Count > 0)
            {
                int j = st.Pop(), x = j % gw, y = j / gw; area++; mnx = Math.Min(mnx, x); mny = Math.Min(mny, y); mxx = Math.Max(mxx, x); mxy = Math.Max(mxy, y);
                for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) { int nx = x + dx, ny = y + dy; if (nx < 0 || ny < 0 || nx >= gw || ny >= gh) continue; int q = ny * gw + nx; if (occ[q] && lab[q] == 0) { lab[q] = next; st.Push(q); } }
            }
            if (area >= 12) boxes.Add(new[] { mnx * cs, mny * cs, (mxx + 1) * cs, (mxy + 1) * cs });
        }
        // rows: cluster by vertical centre
        boxes = boxes.OrderBy(b => (b[1] + b[3]) / 2).ToList();
        var rows = new List<List<int[]>>();
        foreach (var b in boxes) { int cy = (b[1] + b[3]) / 2; var row = rows.LastOrDefault(); if (row != null && Math.Abs(cy - row.Average(r => (r[1] + r[3]) / 2.0)) < h / 10.0) row.Add(b); else rows.Add(new List<int[]> { b }); }
        var outp = new List<string>(); int n = 0;
        foreach (var row in rows) foreach (var b in row.OrderBy(b => b[0]))
        {
            var bb = BBox(px, w, h, b[0], b[1], Math.Min(w, b[2]), Math.Min(h, b[3])); if (bb == null) continue;
            int bw = bb[2] - bb[0], bh = bb[3] - bb[1], tw = Math.Max(1, (int)Math.Round(bw * scale)), th = Math.Max(1, (int)Math.Round(bh * scale));
            var o = Shrink(px, w, bb[0], bb[1], bw, bh, tw, th); Defringe(o, tw, th); Quantize(o, colors); Save(o, tw, th, dstPrefix + n + ".png");
            outp.Add(n + ":" + tw + "x" + th + "@r" + rows.IndexOf(row)); n++;
        }
        return string.Join(" ", outp);
    }
}

