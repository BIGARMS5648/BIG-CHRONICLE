"""BIG CHRONICLE :: 고서(古書) 디자인 에셋 만들기

무료 에셋을 받아 WoW에서 쓸 수 있는 TGA(2의 거듭제곱 크기)로 바꾼다.

  - 양피지·가죽 질감: Subtle Patterns (CC BY-SA 3.0)  https://github.com/atlemo/SubtlePatterns
  - 문장·아이콘·밀랍 인장 도안: game-icons.net (CC BY 3.0)  npm @iconify-json/game-icons
  - 글꼴: 나눔명조 ExtraBold·Bold, Cinzel (SIL OFL 1.1)  https://github.com/google/fonts
  - 금테, 모서리 장식, 명판, 깃발, 가죽끈과 버클, 탭, 버튼, 찢어진 양피지, 잉크 삽화는
    tools/ornate.py 가 높이 지도에 빛을 계산해서 직접 그린다.

사용법 (Python + Pillow + numpy + fontTools, Node + Playwright 필요):
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
random.seed(7)
np.random.seed(7)

SUBTLE = "https://raw.githubusercontent.com/atlemo/SubtlePatterns/gh-pages/{}"
FONT = "https://raw.githubusercontent.com/google/fonts/main/ofl/nanummyeongjo/{}"


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
def periodic_noise(size, blob, seed):
    """이음매 없이 반복되는 부드러운 얼룩 (-1 ~ 1). blob: 얼룩 크기(픽셀)."""
    rng = np.random.default_rng(seed)
    white = rng.standard_normal((size, size))
    f = np.fft.fft2(white)
    ky = np.fft.fftfreq(size)[:, None]
    kx = np.fft.fftfreq(size)[None, :]
    k2 = kx * kx + ky * ky
    sigma = 1.0 / blob
    out = np.real(np.fft.ifft2(f * np.exp(-k2 / (2 * sigma * sigma))))
    out -= out.mean()
    return out / (np.abs(out).max() + 1e-6)


def parchment_tex(src):
    """오래된 양피지: 종이 결 + 큰 얼룩 + 잔 얼룩 + 군데군데 갈색 반점 (회색조, 게임에서 색을 입힌다)."""
    S = 512
    g = np.asarray(seamless_resize(src, (S, S)).convert("L"), dtype=np.float32)
    g = (g - g.mean()) * 1.5
    big = periodic_noise(S, 90, 1) * 13
    mid = periodic_noise(S, 22, 2) * 6
    fine = periodic_noise(S, 5, 3) * 3
    # 반점 (foxing): 가장자리를 넘어가면 반대편에서 이어지게 그린다
    spots = np.zeros((S, S), dtype=np.float32)
    rng = np.random.default_rng(4)
    yy, xx = np.mgrid[0:S, 0:S]
    for _ in range(14):
        cx, cy = rng.uniform(0, S, 2)
        r = rng.uniform(3, 11)
        dx = np.minimum(np.abs(xx - cx), S - np.abs(xx - cx))
        dy = np.minimum(np.abs(yy - cy), S - np.abs(yy - cy))
        spots += np.exp(-(dx * dx + dy * dy) / (2 * r * r)) * rng.uniform(8, 16)
    v = 226 + g + big + mid + fine - spots
    return Image.fromarray(np.clip(v, 0, 255).astype(np.uint8)).convert("RGB")


def vignette_tex():
    """페이지 가장자리가 그을리고 바랜 느낌 (흰색 + 알파, 게임에서 짙은 갈색을 입힌다)."""
    S = 256
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32) / (S - 1)
    d = np.minimum(np.minimum(xx, 1 - xx), np.minimum(yy, 1 - yy))
    rough = periodic_noise(S, 12, 8) * 0.012 + periodic_noise(S, 40, 9) * 0.02
    d = np.clip(d + rough, 0, 1)
    edge = np.clip(1 - d / 0.11, 0, 1) ** 1.8
    # 모서리는 조금 더 짙게, 가운데로 갈수록 아주 옅게 바랜다
    r = np.sqrt((xx - 0.5) ** 2 + (yy - 0.5) ** 2) / 0.7071
    broad = np.clip((r - 0.45) / 0.55, 0, 1) ** 2 * 0.45
    a = np.clip(edge * 0.95 + broad, 0, 1)
    img = np.dstack([np.full((S, S), 255, np.uint8)] * 3 + [(a * 255).astype(np.uint8)])
    return Image.fromarray(img, "RGBA")


def orn_corner_tex():
    """액자 모서리 장식: 이중선 + 작은 마름모 (흰색 마스크, 왼쪽 위 기준)."""
    K, S = 8, 32
    N = S * K
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    w1, w2 = int(1.6 * K), int(1.0 * K)
    d.line((1 * K, 1 * K, 30 * K, 1 * K), fill=255, width=w1)
    d.line((1 * K, 1 * K, 1 * K, 30 * K), fill=255, width=w1)
    d.line((5 * K, 5 * K, 20 * K, 5 * K), fill=255, width=w2)
    d.line((5 * K, 5 * K, 5 * K, 20 * K), fill=255, width=w2)
    c = 10 * K
    r = 3 * K
    d.polygon([(c, c - r), (c + r, c), (c, c + r), (c - r, c)], fill=255)
    m = m.resize((S, S), Image.LANCZOS)
    out = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    out.putalpha(m)
    return out


def dust_tex():
    S = 32
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.sqrt((xx - S / 2 + 0.5) ** 2 + (yy - S / 2 + 0.5) ** 2) / (S / 2)
    a = np.clip(np.exp(-r * r * 5) * 1.15 - 0.03, 0, 1)
    img = np.dstack([np.full((S, S), 255, np.uint8)] * 3 + [(a * 255).astype(np.uint8)])
    return Image.fromarray(img, "RGBA")


def ghost_page_tex():
    """넘어가는 책장 앞면에 비치는 희미한 글씨 자국 (흰색 마스크).
    일지 양피지 칸 비율(약 640×470)로 그린 뒤 512×512로 줄인다 — 게임에서 다시 늘어나며 비율이 맞는다."""
    W, H = 1024, 752
    rng = random.Random(21)
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)

    def words(x0, x1, y, h, gap=10):
        x = x0
        while x < x1:
            w = rng.randint(18, 70)
            if x + w > x1:
                w = x1 - x
            if w > 6:
                d.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=rng.randint(150, 230))
            x += w + gap

    d.rounded_rectangle((40, 40, 330, 66), radius=8, fill=235)
    words(42, 640, 84, 8, 12)
    d.line((36, 116, W - 40, 116), fill=150, width=2)
    d.line((300, 146, 420, 146), fill=170, width=2)
    d.rounded_rectangle((440, 136, 600, 156), radius=6, fill=210)
    d.line((620, 146, 740, 146), fill=170, width=2)
    y = 182
    while y < H - 150:
        words(60, rng.randint(W - 300, W - 60), y, 9)
        y += rng.choice((32, 32, 32, 46))
    d.line((36, H - 128, W - 40, H - 128), fill=140, width=2)
    for x0, x1 in ((40, 200), (W - 200, W - 40)):
        d.rounded_rectangle((x0, H - 112, x1, H - 84), radius=8, outline=170, width=3)
    d.rounded_rectangle((40, H - 66, W - 360, H - 34), radius=8, outline=160, width=3)
    m = m.filter(ImageFilter.GaussianBlur(1.6)).resize((512, 512), Image.LANCZOS)
    out = Image.new("RGBA", (512, 512), (255, 255, 255, 0))
    out.putalpha(m)
    return out


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


def check_tex():
    """깃펜으로 그은 체크 표시"""
    def pts(W, H):
        a = [(W * 0.14, H * 0.54), (W * 0.26, H * 0.66), (W * 0.40, H * 0.84)]
        b = [(W * 0.40, H * 0.84), (W * 0.55, H * 0.56), (W * 0.72, H * 0.32), (W * 0.90, H * 0.12)]
        return a + b
    return pen_stroke(32, 32, pts, 3.4)


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


def mask_icon(mask, size):
    m = mask.resize((size, size), Image.LANCZOS)
    icon = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    icon.putalpha(m)
    return icon


# ---------------------------------------------------------------- 실행
ICONS = ["quill-ink", "dragon-head", "laurel-crown", "hourglass", "cog"]
KEEP = {"Leather", "Paper", "Seal", "SealDex", "SealAch", "Icon"}
POLYHAVEN = "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/brown_leather/brown_leather_albedo_1k.jpg"
AMBIENTCG = "https://ambientcg.com/get?file=Paper005_1K-JPG.zip"


def main():
    """표지와 속지는 실제 사진 텍스처(CC0)를 크기만 줄여 그대로 쓴다."""
    import zipfile
    leather = Image.open(fetch(POLYHAVEN, "brown_leather_albedo_1k.jpg")).convert("RGB")
    save_tga(leather.resize((512, 512), Image.LANCZOS), "Leather.tga")
    z = zipfile.ZipFile(fetch(AMBIENTCG, "Paper005_1K-JPG.zip"))
    name = next(n for n in z.namelist() if "Color" in n)
    paper = Image.open(z.open(name)).convert("RGB")
    save_tga(paper.resize((512, 512), Image.LANCZOS), "Paper.tga")

    icons = game_icons()
    masks = render_masks(icons, ["wax-seal", "dragon-head", "laurel-crown"] + ICONS)
    save_tga(wax_seal(masks["wax-seal"], None), "Seal.tga")
    save_tga(wax_seal(masks["wax-seal"], masks["dragon-head"]), "SealDex.tga")
    save_tga(wax_seal(masks["wax-seal"], masks["laurel-crown"], color=(140, 24, 22)), "SealAch.tga")

    # 예전 디자인에서 쓰던 파일 정리
    for p in MEDIA.glob("*.tga"):
        if p.stem not in KEEP:
            p.unlink()
    for p in (MEDIA / "Icons").glob("*.tga"):
        p.unlink()
    for n in ICONS:
        save_tga(mask_icon(masks[n], 64), f"Icons/{n}.tga")
    if (MEDIA / "Fonts").exists():
        shutil.rmtree(MEDIA / "Fonts")   # 글꼴은 게임 기본 글꼴을 쓴다
    print("done")


if __name__ == "__main__":
    main()
