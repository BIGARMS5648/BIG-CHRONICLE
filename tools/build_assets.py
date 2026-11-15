"""BIG CHRONICLE :: 수첩 디자인 에셋 만들기

무료 에셋을 받아 WoW에서 쓸 수 있는 TGA(2의 거듭제곱 크기)로 바꾼다.

  - 종이·가죽 질감: Subtle Patterns (CC BY-SA 3.0)  https://github.com/atlemo/SubtlePatterns
  - 아이콘·밀랍 인장 도안: game-icons.net (CC BY 3.0)  npm @iconify-json/game-icons
  - 손글씨 글꼴: 나눔손글씨 펜 (SIL OFL 1.1)  https://github.com/google/fonts/tree/main/ofl/nanumpenscript
  - 고리, 테이프, 메모지, 찢어진 종이, 밑줄, 체크, 잉크 방울은 이 스크립트가 직접 그린다.

사용법 (Python + Pillow + numpy, Node + Playwright 필요):
    NODE_PATH=$(npm root -g) python3 tools/build_assets.py <캐시_폴더>
"""
import json
import math
import os
import pathlib
import random
import shutil
import subprocess
import sys
import tarfile
import urllib.request

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
MEDIA = ROOT / "BigChronicle" / "Media"
CACHE = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/bigchronicle-assets").resolve()
CACHE.mkdir(parents=True, exist_ok=True)
(MEDIA / "Icons").mkdir(parents=True, exist_ok=True)
(MEDIA / "Fonts").mkdir(parents=True, exist_ok=True)
random.seed(7)
np.random.seed(7)

SUBTLE = "https://raw.githubusercontent.com/atlemo/SubtlePatterns/gh-pages/{}"
FONT = "https://raw.githubusercontent.com/google/fonts/main/ofl/nanumpenscript/{}"


def fetch(url, name):
    dest = CACHE / name
    if not dest.exists():
        print("download", url)
        with urllib.request.urlopen(url, timeout=60) as r, open(dest, "wb") as f:
            shutil.copyfileobj(r, f)
    return dest


def save_tga(img, rel):
    w, h = img.size
    assert w & (w - 1) == 0 and h & (h - 1) == 0, f"{rel}: {w}x{h} is not a power of two"
    out = MEDIA / rel
    img.convert("RGBA").save(out)
    print("wrote", out.relative_to(ROOT), img.size)


# ---------------------------------------------------------------- 원본 받기
def subtle(name):
    try:
        return fetch(SUBTLE.format(name), name)
    except Exception:
        # gh-pages 대신 master 브랜치에 있는 경우
        return fetch(SUBTLE.replace("gh-pages", "master").format(name), name)


def game_icons():
    pkg = CACHE / "game-icons" / "package" / "icons.json"
    if not pkg.exists():
        (CACHE / "game-icons").mkdir(exist_ok=True)
        subprocess.run(["npm", "pack", "@iconify-json/game-icons", "--silent"], cwd=CACHE / "game-icons", check=True)
        tgz = next((CACHE / "game-icons").glob("*.tgz"))
        with tarfile.open(tgz) as t:
            t.extractall(CACHE / "game-icons", filter="data")
    return json.loads(pkg.read_text())


# ---------------------------------------------------------------- 도우미
def seamless_resize(img, size):
    """반복 무늬를 이음매 없이 크기만 바꾼다 (3×3으로 이어 붙인 뒤 가운데를 잘라 낸다)."""
    w, h = img.size
    big = Image.new(img.mode, (w * 3, h * 3))
    for i in range(3):
        for j in range(3):
            big.paste(img, (i * w, j * h))
    sx, sy = size[0] / w, size[1] / h
    big = big.resize((round(w * 3 * sx), round(h * 3 * sy)), Image.LANCZOS)
    return big.crop((size[0], size[1], size[0] * 2, size[1] * 2))


def normalize_gray(img, target_mean=232, contrast=1.0):
    g = np.asarray(img.convert("L"), dtype=np.float32)
    g = (g - g.mean()) * contrast + target_mean
    g = np.clip(g, 0, 255).astype(np.uint8)
    return Image.fromarray(g).convert("RGB")


def render_masks(icons, names, size=1024):
    """game-icons 도안을 흰색 마스크 PNG로 그린다 (Chromium)."""
    out = {}
    todo = [n for n in names if not (CACHE / f"mask-{n}-{size}.png").exists()]
    if todo:
        html = CACHE / "masks.html"
        parts = ['<html><body style="margin:0;background:transparent">']
        for n in todo:
            ic = icons["icons"][n]
            w, h = ic.get("width", icons.get("width", 512)), ic.get("height", icons.get("height", 512))
            parts.append(f'<svg id="m-{n}" width="{size}" height="{size}" viewBox="0 0 {w} {h}" style="display:block;color:#fff">{ic["body"]}</svg>')
        parts.append("</body></html>")
        html.write_text("".join(parts))
        js = CACHE / "masks.js"
        js.write_text("""
const { chromium } = require('playwright');
(async () => {
  const [,, file, outDir, size, ...names] = process.argv;
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: +size, height: +size } });
  await p.goto('file://' + file);
  for (const n of names) await p.locator('#m-' + n).screenshot({ path: outDir + '/mask-' + n + '-' + size + '.png', omitBackground: true });
  await b.close();
})();""")
        subprocess.run(["node", str(js), str(html), str(CACHE), str(size), *todo], check=True)
    for n in names:
        out[n] = Image.open(CACHE / f"mask-{n}-{size}.png").getchannel("A")
    return out


def fill_holes(mask):
    """마스크 안쪽 구멍(문양)까지 채운 바깥 윤곽을 얻는다."""
    m = np.asarray(mask) > 127
    h, w = m.shape
    outside = np.zeros_like(m)
    stack = [(0, 0), (0, w - 1), (h - 1, 0), (h - 1, w - 1)]
    seen = np.zeros_like(m)
    while stack:
        y, x = stack.pop()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or m[y, x]:
            continue
        seen[y, x] = True
        outside[y, x] = True
        stack.extend(((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)))
    return Image.fromarray(((~outside) * 255).astype(np.uint8))


def shade(height, light=(-0.55, -0.6, 0.6), strength=6.0):
    """높이 지도로 빛과 그림자를 계산한다."""
    gy, gx = np.gradient(height)
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    n = np.sqrt(nx * nx + ny * ny + nz * nz)
    lx, ly, lz = light
    ln = math.sqrt(lx * lx + ly * ly + lz * lz)
    diffuse = (nx * lx + ny * ly + nz * lz) / (n * ln)
    hx, hy, hz = lx, ly, lz + 1
    hn = math.sqrt(hx * hx + hy * hy + hz * hz)
    spec = np.clip((nx * hx + ny * hy + nz * hz) / (n * hn), 0, 1) ** 40
    return diffuse, spec


# ---------------------------------------------------------------- 밀랍 인장
def wax_seal(base_mask, emblem_mask, out_size=128, color=(150, 22, 18)):
    S = base_mask.size[0]
    blob = fill_holes(base_mask)  # 밀랍 덩어리 전체
    if emblem_mask is None:
        engraved = ImageChops.subtract(blob, base_mask)  # 원래 도안의 문양 부분
    else:
        # 다른 문양을 가운데에 눌러 찍는다
        em = emblem_mask.resize((int(S * 0.46), int(S * 0.46)), Image.LANCZOS)
        layer = Image.new("L", (S, S), 0)
        layer.paste(em, ((S - em.size[0]) // 2 - int(S * 0.02), (S - em.size[1]) // 2 + int(S * 0.01)))
        ring = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(ring)
        r1, r2 = S * 0.33, S * 0.305
        c = (S * 0.48, S * 0.51)
        d.ellipse((c[0] - r1, c[1] - r1, c[0] + r1, c[1] + r1), fill=255)
        d.ellipse((c[0] - r2, c[1] - r2, c[0] + r2, c[1] + r2), fill=0)
        engraved = ImageChops.lighter(layer, ring)
        engraved = ImageChops.multiply(engraved, blob)

    b = np.asarray(blob.filter(ImageFilter.GaussianBlur(S / 60)), dtype=np.float32) / 255
    e = np.asarray(engraved.filter(ImageFilter.GaussianBlur(S / 300)), dtype=np.float32) / 255
    # 가장자리는 둥글게 부풀고, 문양은 눌려 들어간다
    dome = np.asarray(blob.filter(ImageFilter.GaussianBlur(S / 14)), dtype=np.float32) / 255
    height = b * 0.6 + dome * 0.6 - e * 0.35
    diffuse, spec = shade(height, strength=S / 9)

    base = np.array(color, dtype=np.float32)
    lit = base[None, None, :] * (0.55 + 0.75 * diffuse[..., None]) + 255 * 0.55 * spec[..., None]
    # 오목한 문양 안쪽은 조금 더 어둡고 탁하게
    lit = lit * (1 - 0.22 * e[..., None])
    rgb = np.clip(lit, 0, 255).astype(np.uint8)
    alpha = np.asarray(blob, dtype=np.uint8)
    seal = Image.fromarray(np.dstack([rgb, alpha]), "RGBA")

    # 바닥 그림자
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sh = blob.filter(ImageFilter.GaussianBlur(S / 40)).point(lambda v: int(v * 0.55))
    shadow.putalpha(sh)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    canvas.alpha_composite(shadow, (int(S * 0.015), int(S * 0.03)))
    canvas.alpha_composite(seal)
    # 여백을 조금 두고 줄인다
    pad = Image.new("RGBA", (int(S * 1.08), int(S * 1.08)), (0, 0, 0, 0))
    pad.alpha_composite(canvas, (int(S * 0.04), int(S * 0.04)))
    return pad.resize((out_size, out_size), Image.LANCZOS)


# ---------------------------------------------------------------- 직접 그리는 소품
def ring_tex():
    W, H, K = 48, 96, 4
    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 그림자
    d.rounded_rectangle((10 * K, 12 * K, 42 * K, 88 * K), radius=16 * K, outline=(0, 0, 0, 90), width=9 * K)
    img = img.filter(ImageFilter.GaussianBlur(3 * K))
    d = ImageDraw.Draw(img)
    # 금속 고리 (바깥 → 안쪽으로 밝기를 바꿔 원통처럼)
    for i, c in enumerate([(70, 66, 60), (120, 116, 108), (185, 180, 170), (230, 226, 216), (165, 160, 150), (95, 90, 84)]):
        inset = (i * 1.2) * K
        d.rounded_rectangle((6 * K + inset, 6 * K + inset, 38 * K - inset, 84 * K - inset), radius=14 * K,
                            outline=c + (255,), width=max(1, int(8 * K - inset * 2)))
    return img.resize((W, H), Image.LANCZOS).resize((32, 64), Image.LANCZOS)


def hole_tex():
    K = 4
    img = Image.new("RGBA", (32 * K, 32 * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((6 * K, 6 * K, 26 * K, 26 * K), fill=(40, 28, 18, 230))
    d.ellipse((8 * K, 7 * K, 25 * K, 24 * K), fill=(20, 14, 9, 255))
    img = img.filter(ImageFilter.GaussianBlur(K))
    return img.resize((32, 32), Image.LANCZOS)


def torn_edge_mask(w, h, top=True, bottom=True, left=False, right=False, amp=5, step=3):
    m = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(m)
    def jag(n):
        return [random.uniform(0, amp) for _ in range(n)]
    if top:
        pts = [(x, y) for x, y in zip(range(0, w + step, step), jag(w // step + 2))]
        d.polygon([(0, 0)] + pts + [(w, 0)], fill=0)
    if bottom:
        pts = [(x, h - 1 - y) for x, y in zip(range(0, w + step, step), jag(w // step + 2))]
        d.polygon([(0, h)] + pts + [(w, h)], fill=0)
    if left:
        pts = [(x, y) for y, x in zip(range(0, h + step, step), jag(h // step + 2))]
        d.polygon([(0, 0)] + pts + [(0, h)], fill=0)
    if right:
        pts = [(w - 1 - x, y) for y, x in zip(range(0, h + step, step), jag(h // step + 2))]
        d.polygon([(w, 0)] + pts + [(w, h)], fill=0)
    return m


def tape_tex(paper):
    w, h = 128, 32
    base = seamless_resize(paper, (w, h)).convert("RGB")
    tint = Image.new("RGB", (w, h), (236, 222, 180))
    body = ImageChops.multiply(base, tint)
    alpha = torn_edge_mask(w, h, top=False, bottom=False, left=True, right=True, amp=6, step=4).point(lambda v: int(v * 0.78))
    body.putalpha(alpha)
    return body


def sticky_tex(paper):
    S = 256
    base = seamless_resize(paper, (S, S)).convert("RGB")
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # 그림자
    sh = Image.new("L", (S, S), 0)
    ImageDraw.Draw(sh).rectangle((14, 16, S - 10, S - 8), fill=110)
    sh = sh.filter(ImageFilter.GaussianBlur(7))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.putalpha(sh)
    img.alpha_composite(shadow)
    note = base.crop((0, 0, S - 22, S - 22)).convert("RGBA")
    # 오른쪽 아래가 살짝 말려 올라간 느낌
    a = np.asarray(note, dtype=np.float32)
    yy, xx = np.mgrid[0:note.size[1], 0:note.size[0]]
    curl = np.clip(((xx + yy) - (note.size[0] + note.size[1]) * 0.82) / 60, 0, 1)
    a[..., :3] *= (1 - 0.18 * curl[..., None])
    note = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    img.alpha_composite(note, (8, 6))
    return img


def torn_strip(paper):
    w, h = 512, 128
    base = seamless_resize(paper, (w, h)).convert("RGB")
    tint = Image.new("RGB", (w, h), (244, 234, 210))
    body = ImageChops.multiply(base, tint)
    m = torn_edge_mask(w, h - 20, amp=8, step=5)
    alpha = Image.new("L", (w, h), 0)
    alpha.paste(m, (0, 10))
    body.putalpha(alpha)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sh = alpha.filter(ImageFilter.GaussianBlur(5)).point(lambda v: int(v * 0.5))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow.putalpha(sh)
    canvas.alpha_composite(shadow, (3, 5))
    canvas.alpha_composite(body)
    return canvas


def pen_stroke(w, h, pts_fn, width, K=4):
    img = Image.new("L", (w * K, h * K), 0)
    d = ImageDraw.Draw(img)
    pts = pts_fn(w * K, h * K)
    n = len(pts)
    for i in range(n - 1):
        t = i / (n - 1)
        wid = max(1, int(width * K * (0.45 + 0.55 * math.sin(math.pi * t))))
        d.line([pts[i], pts[i + 1]], fill=255, width=wid)
        d.ellipse((pts[i][0] - wid / 2, pts[i][1] - wid / 2, pts[i][0] + wid / 2, pts[i][1] + wid / 2), fill=255)
    img = img.resize((w, h), Image.LANCZOS)
    out = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    out.putalpha(img)
    return out


def underline_tex():
    def pts(W, H):
        return [(x, H * 0.55 + math.sin(x / W * math.pi * 2.2 + 0.4) * H * 0.18 + (x / W) * H * -0.12)
                for x in np.linspace(W * 0.02, W * 0.98, 80)]
    return pen_stroke(256, 16, pts, 3.2)


def check_tex():
    def pts(W, H):
        a = [(W * 0.12, H * 0.52), (W * 0.24, H * 0.64), (W * 0.40, H * 0.82)]
        b = [(W * 0.40, H * 0.82), (W * 0.55, H * 0.55), (W * 0.72, H * 0.32), (W * 0.92, H * 0.10)]
        return a + b
    return pen_stroke(32, 32, pts, 3.6)


def circle_tex():
    def pts(W, H):
        cx, cy = W / 2, H / 2
        out = []
        for i in range(140):
            t = i / 139 * (2 * math.pi + 0.5) - 0.25
            r = 1 + 0.04 * math.sin(t * 3)
            out.append((cx + math.cos(t) * W * 0.46 * r, cy + math.sin(t) * H * 0.40 * r))
        return out
    return pen_stroke(128, 64, pts, 2.4)


def ink_tex():
    K = 4
    S = 32
    img = Image.new("L", (S * K, S * K), 0)
    d = ImageDraw.Draw(img)
    c = S * K / 2
    for _ in range(9):
        r = random.uniform(3, 7) * K
        ox, oy = random.uniform(-5, 5) * K, random.uniform(-5, 5) * K
        d.ellipse((c + ox - r, c + oy - r, c + ox + r, c + oy + r), fill=255)
    d.ellipse((c - 8 * K, c - 8 * K, c + 8 * K, c + 8 * K), fill=255)
    img = img.filter(ImageFilter.GaussianBlur(K * 0.8)).point(lambda v: 255 if v > 120 else int(v * 1.5))
    img = img.resize((S, S), Image.LANCZOS)
    out = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    out.putalpha(img)
    return out


def paperclip_tex():
    K = 4
    W, H = 32, 96
    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    def clip(color, off, width):
        x0, x1 = 6 * K + off, 26 * K + off
        d.rounded_rectangle((x0, 4 * K + off, x1, 92 * K + off), radius=10 * K, outline=color, width=width)
        d.rounded_rectangle((x0 + 5 * K, 12 * K + off, x1 - 5 * K, 74 * K + off), radius=6 * K, outline=color, width=width)
    clip((0, 0, 0, 90), 3 * K, 3 * K)
    img = img.filter(ImageFilter.GaussianBlur(2 * K))
    d = ImageDraw.Draw(img)
    clip((150, 150, 158, 255), 0, int(3.2 * K))
    clip((225, 225, 232, 255), -K // 2, int(1.2 * K))
    small = img.resize((W, H), Image.LANCZOS)
    out = Image.new("RGBA", (32, 128), (0, 0, 0, 0))  # WoW 텍스처는 2의 거듭제곱 크기
    out.alpha_composite(small, (0, 16))
    return out


def stitch_tex():
    """가죽 표지 바느질선 (가로로 반복)"""
    K = 4
    img = Image.new("RGBA", (32 * K, 8 * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((4 * K, 3 * K + K // 2, 22 * K, 5 * K + K // 2), radius=K, fill=(0, 0, 0, 120))
    d.rounded_rectangle((4 * K, 2 * K, 22 * K, 4 * K + K // 2), radius=K, fill=(255, 255, 255, 255))
    return img.resize((32, 8), Image.LANCZOS)


def ribbon_tex():
    """책갈피 리본 (끝이 V자로 갈라진 공단 끈)"""
    W, H, K = 16, 128, 4
    img = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    a = np.zeros((H * K, W * K, 4), dtype=np.float32)
    xx = np.linspace(-1, 1, W * K)
    shine = 0.78 + 0.22 * np.cos(xx * math.pi / 2) ** 2 + 0.12 * np.exp(-((xx + 0.35) ** 2) / 0.02)
    a[..., 0] = 255 * shine[None, :]
    a[..., 1] = 255 * shine[None, :]
    a[..., 2] = 255 * shine[None, :]
    a[..., 3] = 255
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    m = Image.new("L", (W * K, H * K), 255)
    ImageDraw.Draw(m).polygon([(0, H * K), (W * K / 2, H * K - 12 * K), (W * K, H * K)], fill=0)
    img.putalpha(m)
    return img.resize((W, H), Image.LANCZOS)


def grid_tex():
    img = Image.new("RGBA", (32, 32), (255, 255, 255, 0))
    d = ImageDraw.Draw(img)
    d.line((0, 0, 31, 0), fill=(255, 255, 255, 120))
    d.line((0, 0, 0, 31), fill=(255, 255, 255, 120))
    return img


# ---------------------------------------------------------------- 실행
def main():
    paper_src = Image.open(subtle("exclusive_paper.png")).convert("RGB")
    leather_src = Image.open(subtle("leather_1.png")).convert("RGB")

    paper = normalize_gray(seamless_resize(paper_src, (512, 512)), target_mean=236, contrast=1.25)
    save_tga(paper, "Paper.tga")
    leather = normalize_gray(seamless_resize(leather_src, (256, 256)), target_mean=200, contrast=1.6)
    save_tga(leather, "Leather.tga")

    icons = game_icons()
    names = ["wax-seal", "flat-paw-print", "laurels-trophy", "scroll-quill", "paw-print", "histogram", "cog",
             "magnifying-glass", "quill-ink", "footprint", "star-medal", "compass", "sparkles"]
    masks = render_masks(icons, names)

    save_tga(wax_seal(masks["wax-seal"], None), "Seal.tga")
    save_tga(wax_seal(masks["wax-seal"], masks["flat-paw-print"]), "SealDex.tga")
    save_tga(wax_seal(masks["wax-seal"], masks["laurels-trophy"], color=(140, 24, 22)), "SealAch.tga")

    for n in ["scroll-quill", "paw-print", "laurels-trophy", "histogram", "cog", "magnifying-glass", "quill-ink",
              "footprint", "star-medal", "compass", "sparkles"]:
        m = masks[n].resize((64, 64), Image.LANCZOS)
        icon = Image.new("RGBA", (64, 64), (255, 255, 255, 0))
        icon.putalpha(m)
        save_tga(icon, f"Icons/{n}.tga")

    save_tga(ring_tex(), "Ring.tga")
    save_tga(hole_tex(), "Hole.tga")
    save_tga(tape_tex(paper), "Tape.tga")
    save_tga(sticky_tex(paper), "Sticky.tga")
    save_tga(torn_strip(paper), "Torn.tga")
    save_tga(underline_tex(), "Underline.tga")
    save_tga(check_tex(), "Check.tga")
    save_tga(circle_tex(), "PenCircle.tga")
    save_tga(ink_tex(), "Ink.tga")
    save_tga(paperclip_tex(), "Paperclip.tga")
    save_tga(grid_tex(), "Grid.tga")
    save_tga(stitch_tex(), "Stitch.tga")
    save_tga(ribbon_tex(), "Ribbon.tga")

    font = fetch(FONT.format("NanumPenScript-Regular.ttf"), "NanumPenScript-Regular.ttf")
    shutil.copy(font, MEDIA / "Fonts" / "NanumPenScript.ttf")
    ofl = fetch(FONT.format("OFL.txt"), "NanumPenScript-OFL.txt")
    shutil.copy(ofl, MEDIA / "Fonts" / "NanumPenScript-OFL.txt")
    print("done")


if __name__ == "__main__":
    main()
