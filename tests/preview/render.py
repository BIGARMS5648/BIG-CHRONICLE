"""BIG CHRONICLE :: 미리보기 렌더러

tests/mockwow.lua 의 M.Dump() 가 남긴 장면(JSON)을 그림으로 그린다.
게임 화면과 똑같지는 않지만, 배치·겹침·색·글꼴을 게임 없이 확인하는 데 쓴다.

사용법:
    python3 tests/preview/render.py <scene.json> <out.png> <본문용 한국어 TTF> [확대 배율]
"""
import json
import math
import pathlib
import re
import sys

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = pathlib.Path(__file__).resolve().parents[2]
MEDIA = ROOT / "BigChronicle" / "Media"

scene = json.loads(pathlib.Path(sys.argv[1]).read_text())
OUT = sys.argv[2]
BODY_FONT = sys.argv[3]
CROP = sys.argv[4] if len(sys.argv) > 4 else None  # "x,y,w,h" (화면 좌표, 위가 0)
SW, SH = [int(round(v)) for v in scene["screen"]]
NODES = {n["id"]: n for n in scene["nodes"]}

LAYERS = {"BACKGROUND": 0, "BORDER": 1, "ARTWORK": 2, "OVERLAY": 3, "HIGHLIGHT": 9}
STRATA = {"": 2, "BACKGROUND": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "DIALOG": 4, "FULLSCREEN": 5, "FULLSCREEN_DIALOG": 6, "TOOLTIP": 7}

_tex_cache = {}
_font_cache = {}


def load_tex(path):
    if path in _tex_cache:
        return _tex_cache[path]
    img = None
    p = path.replace("\\", "/")
    m = re.search(r"AddOns/BigChronicle/Media/(.+)$", p)
    if m:
        f = MEDIA / (m.group(1) + ".tga")
        if f.exists():
            img = Image.open(f).convert("RGBA")
    elif p.endswith("WHITE8X8"):
        img = Image.new("RGBA", (8, 8), (255, 255, 255, 255))
    elif "/Icons/" in p:
        # 게임 아이콘은 없으므로 차분한 색의 자리 표시만 그린다
        name = p.split("/")[-1]
        h = abs(hash(name)) % 360
        base = tuple(int(70 + 30 * math.sin(math.radians(h + k * 120))) for k in range(3))
        img = Image.new("RGBA", (64, 64), base + (255,))
        d = ImageDraw.Draw(img)
        for i in range(32):
            k = i / 32
            c = tuple(int(v * (0.55 + 0.45 * k)) for v in base)
            d.rectangle((i, i, 63 - i, 63 - i), outline=c + (255,))
        d.ellipse((20, 18, 44, 42), fill=tuple(min(255, v + 70) for v in base) + (255,))
    _tex_cache[path] = img
    return img


def font(path, size):
    key = (path, size)
    if key not in _font_cache:
        f = BODY_FONT
        m = re.search(r"AddOns/BigChronicle/Media/(Fonts/.+)$", (path or "").replace("\\", "/"))
        if m and (MEDIA / m.group(1)).exists():
            f = str(MEDIA / m.group(1))
        _font_cache[key] = ImageFont.truetype(f, max(6, int(round(size))))
    return _font_cache[key]


def screen_box(n):
    x0 = n["l"]
    y0 = SH - (n["b"] + n["h"])
    return x0, y0, x0 + n["w"], y0 + n["h"]


def tint(img, vc, alpha):
    r, g, b, a = img.split()
    if vc:
        r = r.point(lambda v: int(v * vc[0]))
        g = g.point(lambda v: int(v * vc[1]))
        b = b.point(lambda v: int(v * vc[2]))
        a = a.point(lambda v: int(v * (vc[3] if len(vc) > 3 else 1) * alpha))
    elif alpha < 1:
        a = a.point(lambda v: int(v * alpha))
    return Image.merge("RGBA", (r, g, b, a))


def draw_texture(canvas, n, alpha):
    x0, y0, x1, y1 = screen_box(n)
    # 끝점을 각각 반올림해야 이웃한 조각 사이에 1px 틈이 생기지 않는다
    w, h = int(round(x1)) - int(round(x0)), int(round(y1)) - int(round(y0))
    if w <= 0 or h <= 0:
        return
    if n["color"]:
        c = n["color"]
        img = Image.new("RGBA", (w, h), tuple(int(v * 255) for v in c[:3]) + (int(c[3] * 255 * alpha),))
    elif n["grad"]:
        orient, c1, c2 = n["grad"]
        img = Image.new("RGBA", (w, h))
        px = img.load()
        for i in range(w if orient == "HORIZONTAL" else h):
            t = i / max(1, (w if orient == "HORIZONTAL" else h) - 1)
            if orient != "HORIZONTAL":
                t = 1 - t  # WoW: 세로 그라데이션은 아래가 시작색
            col = tuple(int((c1[k] + (c2[k] - c1[k]) * t) * 255) for k in range(3)) + (int((c1[3] + (c2[3] - c1[3]) * t) * 255 * alpha),)
            if orient == "HORIZONTAL":
                for y in range(h):
                    px[i, y] = col
            else:
                for x in range(w):
                    px[x, i] = col
    elif n["tex"]:
        src = load_tex(n["tex"])
        if src is None:
            return
        tc = n["tc"]
        sw, sh = src.size
        if len(tc) == 8:
            # 90도 돌린 띠 (세로 금테): 화면 아래로 갈수록 u 가 늘고, 화면 가로가 v 다
            ulx, uly, llx, lly, urx, ury, lrx, lry = tc
            L = max(1e-3, abs(llx - ulx))
            strip = Image.new("RGBA", (max(1, int(sw * L)), sh))
            for i in range(int(math.ceil(L))):
                strip.paste(src, (i * sw, 0))
            if uly > ury:
                strip = ImageOps.flip(strip)
            img = strip.transpose(Image.TRANSPOSE).resize((w, h))
        elif len(tc) == 4 and (abs(tc[1] - tc[0]) > 1.001 or abs(tc[3] - tc[2]) > 1.001):
            l, r, t, b = tc
            tw, th = max(1, int(sw * abs(r - l))), max(1, int(sh * abs(b - t)))
            tiled = Image.new("RGBA", (tw, th))
            for x in range(0, tw, sw):
                for y in range(0, th, sh):
                    tiled.paste(src, (x, y))
            if l > r:
                tiled = ImageOps.mirror(tiled)
            if t > b:
                tiled = ImageOps.flip(tiled)
            img = tiled.resize((w, h))
        elif len(tc) == 4:
            # 좌표가 거꾸로면 뒤집어서 쓴다 (모서리 장식)
            l, r, t, b = tc
            img = src
            if l > r:
                img, l, r = ImageOps.mirror(img), 1 - l, 1 - r
            if t > b:
                img, t, b = ImageOps.flip(img), 1 - t, 1 - b
            box = (int(l * sw), int(t * sh), max(int(l * sw) + 1, int(r * sw)), max(int(t * sh) + 1, int(b * sh)))
            img = img.crop(box).resize((w, h))
        else:
            img = src.resize((w, h))
        if n["desat"]:
            g = ImageOps.grayscale(img.convert("RGB"))
            img = Image.merge("RGBA", (g, g, g, img.getchannel("A")))
        img = tint(img, n["vc"], alpha)
    else:
        return
    if n["rot"]:
        img = img.rotate(math.degrees(n["rot"]), resample=Image.BICUBIC, expand=True)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        x0, y0 = cx - img.size[0] / 2, cy - img.size[1] / 2
    canvas.alpha_composite(img, (int(round(x0)), int(round(y0))))


COLOR_RE = re.compile(r"(\|c[fF][fF][0-9a-fA-F]{6}|\|r|\|T[^|]*\|t|\|\|)")


def segments(text, base):
    out, cur = [], base
    for part in COLOR_RE.split(text):
        if not part:
            continue
        if part.startswith("|c") or part.startswith("|C"):
            h = part[4:10]
            cur = tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
        elif part == "|r":
            cur = base
        elif part.startswith("|T"):
            out.append(("■", (120, 110, 90, 255)))
        elif part == "||":
            out.append(("|", cur))
        else:
            out.append((part, cur))
    return out


def draw_text(canvas, n, alpha):
    text = n["text"]
    if not text:
        return
    x0, y0, x1, y1 = screen_box(n)
    size = n["fsize"] or 12
    f = font(n["fpath"], size * 1.05)
    col = n["tcolor"] or n["fcolor"] or [1, 1, 1, 1]
    base = tuple(int(v * 255) for v in col[:3]) + (int((col[3] if len(col) > 3 else 1) * 255 * alpha),)
    segs = segments(text, base)
    if not n.get("fixw"):
        # 폭이 정해지지 않은 글자는 줄을 바꾸지 않고, 기준점 쪽으로 붙인다
        natural = max(f.getlength(ln) for ln in "".join(s for s, _ in segs).split("\n")) if text else 0
        pt = n.get("pt1") or ""
        if "RIGHT" in pt:
            x0 = x1 - natural
        elif "LEFT" not in pt:
            cx = (x0 + x1) / 2
            x0 = cx - natural / 2
        x1 = x0 + natural + 1
    width = max(10, x1 - x0)
    wrap_width = width if n.get("fixw") else width * 1.2 + 8  # 폭이 정해지지 않은 글자는 줄을 바꾸지 않는다
    # 줄 나누기 (글자 단위)
    lines, line, lw = [], [], 0
    for s, c in segs:
        for ch in s:
            if ch == "\n":
                lines.append(line); line, lw = [], 0
                continue
            cw = f.getlength(ch)
            if lw + cw > wrap_width + 0.5 and line:
                lines.append(line); line, lw = [], 0
            line.append((ch, c)); lw += cw
    lines.append(line)
    d = ImageDraw.Draw(canvas)
    lh = size * 1.2 + (n.get("spacing") or 0)
    y = y0
    for ln in lines:
        total = sum(f.getlength(ch) for ch, _ in ln)
        if n["jh"] == "CENTER":
            x = x0 + (width - total) / 2
        elif n["jh"] == "RIGHT":
            x = x1 - total
        else:
            x = x0
        for ch, c in ln:
            try:
                d.text((x, y), ch, font=f, fill=c)
            except ValueError:
                pass  # 글꼴에 없는 글자(크기 0)는 건너뛴다
            x += f.getlength(ch)
        y += lh


def visible_alpha(n, inherited):
    return inherited * (n["alpha"] if n["alpha"] is not None else 1)


def draw_node(canvas, n, alpha):
    if not n["shown"]:
        return
    a = visible_alpha(n, alpha)
    if a <= 0.01:
        return
    kind = n["kind"]
    if kind == "Texture":
        if n["anchored"] and n["layer"] != "HIGHLIGHT":
            draw_texture(canvas, n, a)
        return
    if kind == "FontString":
        if n["anchored"]:
            draw_text(canvas, n, a)
        return
    if kind in ("Font", "AnimGroup"):
        return
    regions = [NODES[k] for k in n["kids"] if NODES[k]["kind"] in ("Texture", "FontString")]
    frames = [NODES[k] for k in n["kids"] if NODES[k]["kind"] not in ("Texture", "FontString", "Font", "AnimGroup")]
    regions.sort(key=lambda r: (LAYERS.get(r["layer"], 2), r["sub"], r["id"]))
    target = canvas
    clip = n["clip"] or kind == "ScrollFrame"
    if clip:
        target = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    for r in regions:
        draw_node(target, r, a)
    if kind == "Slider":
        # 손잡이는 값에 맞춰 놓는다 (게임에서는 슬라이더가 직접 옮긴다)
        x0, y0, x1, y1 = screen_box(n)
        span = n["smax"] - n["smin"]
        frac = 0 if span <= 0 else max(0, min(1, (n["sval"] - n["smin"]) / span))
        for r in regions:
            if not r["anchored"] and r["tex"].endswith("Thumb"):
                r = dict(r)
                r["l"] = (x0 + x1) / 2 - r["w"] / 2
                top = y0 + (y1 - y0 - r["h"]) * frac
                r["b"] = SH - top - r["h"]
                r["anchored"] = True
                draw_texture(target, r, a)
    if kind == "StatusBar" and n["smax"] > n["smin"]:
        frac = max(0, min(1, (n["sval"] - n["smin"]) / (n["smax"] - n["smin"])))
        x0, y0, x1, y1 = screen_box(n)
        bw, bh = max(1, int(x1 - x0)), max(1, int(y1 - y0))
        src = load_tex(n["sbt"]) if n.get("sbt") else None
        fw = max(1, int(bw * frac))
        if src is not None:
            # 게임처럼 막대 그림의 왼쪽 부분만 보여 준다
            fill = src.resize((bw, bh), Image.LANCZOS).crop((0, 0, fw, bh))
            fill = tint(fill, n["sbc"], a)
        else:
            c = n["sbc"] or [0.5, 0.5, 0.5, 1]
            fill = Image.new("RGBA", (fw, bh), tuple(int(v * 255) for v in c[:3]) + (int((c[3] if len(c) > 3 else 1) * 200 * a),))
        target.alpha_composite(fill, (int(x0), int(y0)))
        # 막대 위 글자
        for r in regions:
            if r["kind"] == "FontString":
                draw_node(target, r, a)
    frames.sort(key=lambda f: (STRATA.get(f["strata"], 2), f["level"], f["id"]))
    # 스크롤 프레임은 스크롤 자식만 잘라 보이고, 바깥에 붙은 스크롤바 같은 다른 자식은 그대로 보인다
    outside = []
    for fr in frames:
        if kind == "ScrollFrame" and fr["id"] != n["scrollChild"]:
            outside.append(fr)
            continue
        if kind == "ScrollFrame" and fr["id"] == n["scrollChild"]:
            # 스크롤 자식은 스크롤 프레임 왼쪽 위에 붙고, 스크롤한 만큼 올라간다
            x0, y0, _, _ = screen_box(n)
            fr = dict(fr)
            dx, dy = x0 - fr["l"], (SH - (fr["b"] + fr["h"])) - y0
            shift_subtree(fr["id"], dx, dy + n["vs"])
            draw_node(target, NODES[fr["id"]], a)
            shift_subtree(fr["id"], -dx, -dy - n["vs"])
        else:
            draw_node(target, fr, a)
    if clip:
        x0, y0, x1, y1 = [int(round(v)) for v in screen_box(n)]
        box = (max(0, x0), max(0, y0), min(canvas.size[0], x1), min(canvas.size[1], y1))
        if box[2] > box[0] and box[3] > box[1]:
            canvas.alpha_composite(target.crop(box), (box[0], box[1]))
    for fr in outside:
        draw_node(canvas, fr, a)


def shift_subtree(nid, dx, dy):
    n = NODES[nid]
    n["l"] += dx
    n["b"] += dy
    for k in n["kids"]:
        shift_subtree(k, dx, dy)


def main():
    canvas = Image.new("RGBA", (SW, SH), (58, 62, 54, 255))
    # 게임 화면 대신 흐릿한 배경
    d = ImageDraw.Draw(canvas)
    for i in range(0, SW, 40):
        d.line((i, 0, i - 300, SH), fill=(66, 70, 60, 255), width=12)
    root = NODES[scene["root"]]
    top = [NODES[k] for k in root["kids"]]
    top.sort(key=lambda f: (STRATA.get(f["strata"], 2), f["level"], f["id"]))
    for fr in top:
        draw_node(canvas, fr, 1)
    out = canvas
    if CROP:
        x, y, w, h = [int(v) for v in CROP.split(",")]
        out = canvas.crop((x, y, x + w, y + h))
    out.convert("RGB").save(OUT)
    print("wrote", OUT, out.size)


if __name__ == "__main__":
    main()
