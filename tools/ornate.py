"""BIG CHRONICLE :: 장식 에셋 (금테 장정 스타일)

금속 질감은 높이 지도에 빛을 계산해서 그리고, 장식 모양은 game-icons.net 도안(CC BY 3.0)과
직접 그린 도형을 섞어 만든다. build_assets.py 에서 불러 쓴다.
"""
import math
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

GOLD = (204, 156, 66)
GOLD_DARK = (120, 80, 30)
LEATHER_RED = (96, 40, 26)


# ---------------------------------------------------------------- 공용
def blur(a, r):
    img = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    return np.asarray(img.filter(ImageFilter.GaussianBlur(r)), dtype=np.float32) / 255


def to_arr(img):
    return np.asarray(img.convert("L"), dtype=np.float32) / 255


def lighting(height, strength, light=(-0.5, -0.75, 0.55), wrap_x=False):
    h = np.pad(height, ((2, 2), (2, 2)), mode="wrap" if wrap_x else "edge")
    if wrap_x:
        h[:2, :] = h[2:3, :]
        h[-2:, :] = h[-3:-2, :]
    gy, gx = np.gradient(h)
    gy, gx = gy[2:-2, 2:-2], gx[2:-2, 2:-2]
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    n = np.sqrt(nx * nx + ny * ny + nz * nz)
    lx, ly, lz = light
    ln = math.sqrt(lx * lx + ly * ly + lz * lz)
    diffuse = (nx * lx + ny * ly + nz * lz) / (n * ln)
    hx, hy, hz = lx, ly, lz + 1
    hn = math.sqrt(hx * hx + hy * hy + hz * hz)
    spec = np.clip((nx * hx + ny * hy + nz * hz) / (n * hn), 0, 1)
    return diffuse, spec


def metal(height, mask, strength, base=GOLD, ao_r=None, wrap_x=False, shine=0.75, rough=None):
    """높이 지도 → 금속(금) RGBA"""
    diffuse, spec = lighting(height, strength, wrap_x=wrap_x)
    H, W = height.shape
    ao_r = ao_r or max(2, W / 60)
    ao = np.clip(1 - (blur(height, ao_r) - height) * 2.2, 0.45, 1)
    b = np.array(base, np.float32)
    col = b[None, None, :] * (0.30 + 1.0 * np.clip(diffuse, 0, 1)[..., None]) * ao[..., None]
    col += 255 * shine * (spec ** 30)[..., None] + 90 * (spec ** 6)[..., None] * np.array([1, 0.85, 0.5])[None, None, :]
    if rough is not None:
        col *= (0.9 + 0.1 * rough)[..., None]
    rgb = np.clip(col, 0, 255).astype(np.uint8)
    a = np.clip(mask * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([rgb, a]), "RGBA")


def soft_shadow(mask, r, alpha=0.6, offset=(0, 0)):
    m = Image.fromarray(np.clip(mask * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
    sh = Image.new("RGBA", m.size, (0, 0, 0, 0))
    sh.putalpha(m.point(lambda v: int(v * alpha)))
    out = Image.new("RGBA", m.size, (0, 0, 0, 0))
    out.alpha_composite(sh, offset)
    return out


def noise(shape, blob, seed):
    rng = np.random.default_rng(seed)
    white = rng.standard_normal(shape)
    f = np.fft.fft2(white)
    ky = np.fft.fftfreq(shape[0])[:, None]
    kx = np.fft.fftfreq(shape[1])[None, :]
    out = np.real(np.fft.ifft2(f * np.exp(-(kx * kx + ky * ky) / (2 * (1.0 / blob) ** 2))))
    out -= out.mean()
    return out / (np.abs(out).max() + 1e-6)


def shrink(img, size):
    return img.resize(size, Image.LANCZOS)


def mask_resize(mask_img, size):
    return to_arr(mask_img.resize(size, Image.LANCZOS))


def place(dst, src, x, y):
    """src(float 배열)를 dst 위에 최댓값으로 얹는다 (잘리는 부분은 버린다)"""
    H, W = dst.shape
    h, w = src.shape
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(W, x + w), min(H, y + h)
    if x1 <= x0 or y1 <= y0:
        return
    dst[y0:y1, x0:x1] = np.maximum(dst[y0:y1, x0:x1], src[y0 - y:y1 - y, x0 - x:x1 - x])


def rounded_mask(W, H, box, r):
    m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=r, fill=255)
    return to_arr(m)


# ---------------------------------------------------------------- 가죽
def worn_leather(src_gray, size=512):
    """닳은 가죽: 원본 결 + 큰 얼룩 + 잔금 (회색조, 게임에서 색을 입힌다)"""
    g = np.asarray(src_gray.resize((size, size), Image.LANCZOS).convert("L"), dtype=np.float32)
    g = (g - g.mean()) * 1.2
    wear = noise((size, size), 60, 31) * 22 + noise((size, size), 14, 32) * 8
    # 잔금: 얇은 날카로운 골짜기
    cr = np.abs(noise((size, size), 18, 33))
    cracks = np.clip(1 - cr / 0.035, 0, 1) * 26
    cr2 = np.abs(noise((size, size), 40, 34))
    cracks += np.clip(1 - cr2 / 0.03, 0, 1) * 18
    v = 196 + g + wear - cracks
    return Image.fromarray(np.clip(v, 0, 255).astype(np.uint8)).convert("RGB")


# ---------------------------------------------------------------- 금테
def gold_bar(W=256, H=32, K=4):
    """창 둘레의 금테 (가로로 반복). 양쪽 둥근 테 + 가운데 홈 + 잎 무늬."""
    w, h = W * K, H * K
    y = np.linspace(0, 1, h)[:, None]
    x = np.arange(w)[None, :]
    rim = lambda c, s: np.exp(-((y - c) ** 2) / (2 * s * s))
    height = 0.55 * rim(0.13, 0.07) + 0.55 * rim(0.87, 0.07) + 0.25 * (np.abs(y - 0.5) < 0.30)
    # 가운데 홈 안의 잎·구슬 무늬 (주기 64*K/4)
    period = 32 * K
    ph = (x % period) / period
    bead = np.exp(-(((ph - 0.5) * 3.2) ** 2 + ((y - 0.5) / 0.12) ** 2) * 2.2)
    leafL = np.exp(-((((ph - 0.18) * 4.5) ** 2) + ((y - 0.5) / 0.08) ** 2) * 1.6)
    leafR = np.exp(-((((ph - 0.82) * 4.5) ** 2) + ((y - 0.5) / 0.08) ** 2) * 1.6)
    height = height + 0.35 * bead + 0.22 * (leafL + leafR)
    height = height * np.ones((h, w))
    mask = np.ones((h, w), np.float32)
    rough = noise((h, w), 6, 41) * 0.5 + 0.5
    img = metal(height.astype(np.float32), mask, strength=w / 9, wrap_x=True, rough=rough)
    # 가장자리는 짙게
    a = np.asarray(img, np.float32).copy()
    edge = np.clip(np.minimum(y, 1 - y) / 0.04, 0.35, 1)  # (h, 1)
    a[..., :3] *= edge[:, :, None]
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    return shrink(img, (W, H))


def ornate_corner(masks, S=128, K=8, T=(0.115, 0.27)):
    """창 모서리 금장식 (왼쪽 위 기준). T: 금테가 지나는 위치(모서리 크기 대비)."""
    N = S * K
    t0, t1 = int(N * T[0]), int(N * T[1])
    height = np.zeros((N, N), np.float32)
    # ① 금테 L자 (금테와 이어지도록 같은 위치)
    bar = np.zeros((N, N), np.float32)
    bar[t0:t1, t0:] = 1
    bar[t0:, t0:t1] = 1
    height = np.maximum(height, blur(bar, K * 3) * 0.7)
    # ② 덩굴 장식: 두 팔을 따라 바깥쪽으로 감기는 덩굴
    vines = masks["curling-vines"]
    v = mask_resize(vines, (int(N * 0.62), int(N * 0.62)))
    place(height, blur(v, K * 1.5) * 0.85, int(N * 0.20), int(N * 0.20))
    leaf = masks["curled-leaf"]
    l1 = mask_resize(leaf, (int(N * 0.42), int(N * 0.42)))
    place(height, blur(l1, K * 1.5) * 0.8, int(N * 0.52), int(N * 0.02))
    # 모서리 대각선을 기준으로 좌우가 똑같게
    height = np.maximum(height, height.T)
    # ③ 모서리의 둥근 장식판과 보석
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    cx = cy = (t0 + t1) / 2
    r = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    disc = np.clip((N * 0.19 - r) / (K * 3), 0, 1)
    ring = np.exp(-((r - N * 0.15) / (K * 2.2)) ** 2)
    height = np.maximum(height, disc * 0.75 + ring * 0.2)
    gem_r = N * 0.085
    gem = np.clip(1 - (r / gem_r) ** 2, 0, 1)
    height = np.maximum(height, disc * 0.75 + np.sqrt(gem) * 0.35)
    # ④ 백합 문장이 안쪽 대각선으로
    fl = masks["fleur-de-lys"].rotate(45, resample=Image.BICUBIC, expand=False)
    f = mask_resize(fl, (int(N * 0.30), int(N * 0.30)))
    f = np.flipud(np.fliplr(f))
    place(height, blur(f, K * 1.2) * 0.8, int(N * 0.30), int(N * 0.30))

    mask = np.clip(height * 6, 0, 1)
    rough = noise((N, N), 8, 42) * 0.5 + 0.5
    img = metal(height, mask, strength=N / 7, rough=rough)
    # 보석: 짙은 붉은 빛
    a = np.asarray(img, np.float32).copy()
    gm = (r < gem_r)[..., None]
    diffuse, spec = lighting(np.sqrt(gem), N / 7)
    gemcol = np.array([150, 18, 22], np.float32)[None, None, :] * (0.4 + 0.9 * np.clip(diffuse, 0, 1))[..., None] + 255 * (spec ** 40)[..., None]
    a[..., :3] = np.where(gm, np.clip(gemcol, 0, 255), a[..., :3])
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    out = soft_shadow(mask, K * 3, 0.7, (K * 2, K * 3))
    out.alpha_composite(img)
    return shrink(out, (S, S))


# ---------------------------------------------------------------- 월계수 가지
def laurel_branch(N, M, leaves=6, seed=3, flip=False):
    """가로로 뻗은 월계수 가지 마스크 (N x M). 잎은 가지 끝 쪽으로 비스듬히 난 길쭉한 타원."""
    rng = random.Random(seed)
    m = Image.new("L", (N, M), 0)
    d = ImageDraw.Draw(m)
    pts = [(N * (0.03 + 0.80 * t), M * (0.56 - 0.16 * math.sin(math.pi * t * 0.85))) for t in np.linspace(0, 1, 80)]
    d.line(pts, fill=255, width=max(2, M // 26))

    def leaf(px, py, ang, L, Wd):
        dx, dy = math.cos(ang), math.sin(ang)
        nx, ny = -dy, dx
        poly = []
        for t in np.linspace(0, 1, 18):
            w = Wd * math.sin(math.pi * t) ** 0.75
            poly.append((px + dx * L * t + nx * w, py + dy * L * t + ny * w))
        for t in np.linspace(1, 0, 18):
            w = Wd * math.sin(math.pi * t) ** 0.75
            poly.append((px + dx * L * t - nx * w, py + dy * L * t - ny * w))
        d.polygon(poly, fill=255)

    for i in range(leaves):
        t = 0.06 + 0.86 * i / (leaves - 1)
        k = int(t * 79)
        px, py = pts[k]
        qx, qy = pts[min(79, k + 1)]
        base = math.atan2(qy - py, qx - px)
        size = M * (0.46 - 0.20 * t)
        for side in (-1, 1):
            ang = base + side * math.radians(30 + rng.uniform(-4, 4))
            leaf(px + (side * 0 + 1) * size * 0.05, py, ang, size, size * 0.17)
    # 끝 잎
    px, py = pts[-1]
    leaf(px - M * 0.02, py, math.atan2(pts[-1][1] - pts[-6][1], pts[-1][0] - pts[-6][0]), M * 0.22, M * 0.055)
    m = m.filter(ImageFilter.GaussianBlur(1.0))
    if flip:
        m = m.transpose(Image.FLIP_LEFT_RIGHT)
    return to_arr(m)


def laurel_tex(W=128, H=64, K=8):
    N, M = W * K, H * K
    mask = laurel_branch(N, M)
    height = blur(mask, K * 1.6)
    img = metal(height, np.clip(mask * 1.5, 0, 1), strength=N / 10)
    out = soft_shadow(mask, K * 2, 0.6, (K, K * 2))
    out.alpha_composite(img)
    return shrink(out, (W, H))


# ---------------------------------------------------------------- 제목 명판
def title_plaque(masks, leather_gray, W=512, H=256, K=4):
    N, M = W * K, H * K
    # 카르투슈: 양 끝이 오목하게 파인 둥근 판
    cx, cy = N / 2, M * 0.66
    bw, bh = N * 0.66, M * 0.42
    outer = Image.new("L", (N, M), 0)
    d = ImageDraw.Draw(outer)
    d.rounded_rectangle((cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2), radius=int(bh * 0.18), fill=255)
    for sx in (-1, 1):
        r = bh * 0.32
        ex = cx + sx * bw / 2
        d.ellipse((ex - r, cy - r, ex + r, cy + r), fill=0)
    outer_a = to_arr(outer)
    inner = outer.filter(ImageFilter.MinFilter(int(K * 9) | 1))
    inner_a = to_arr(inner)
    frame = np.clip(outer_a - inner_a, 0, 1)
    height = blur(frame, K * 2.5) * 0.9
    # 안쪽 가는 금선
    thin = np.clip(inner_a - to_arr(inner.filter(ImageFilter.MinFilter(int(K * 2) | 1))), 0, 1)
    ring2 = np.clip(to_arr(inner.filter(ImageFilter.MinFilter(int(K * 4) | 1))) - to_arr(inner.filter(ImageFilter.MinFilter(int(K * 5) | 1))), 0, 1)
    # 월계수 가지 (양옆)
    lb = laurel_branch(int(N * 0.30), int(M * 0.50), leaves=5)
    lbm = np.zeros((M, N), np.float32)
    place(lbm, lb[:, ::-1], int(N * 0.005), int(cy - M * 0.27))
    place(lbm, lb, int(N * 0.695), int(cy - M * 0.27))
    lbm = lbm * (1 - outer_a)
    height = np.maximum(height, blur(lbm, K * 1.5) * 0.7)
    # 위쪽 나침반 장식
    cm = mask_resize(masks["compass"], (int(M * 0.42), int(M * 0.42)))
    yy, xx = np.mgrid[0:M, 0:N].astype(np.float32)
    ccx, ccy = N / 2, cy - bh / 2 - M * 0.12
    rr = np.sqrt((xx - ccx) ** 2 + (yy - ccy) ** 2)
    medal = np.clip((M * 0.23 - rr) / (K * 2), 0, 1)
    height = np.maximum(height, medal * 0.55)
    cmp_layer = np.zeros((M, N), np.float32)
    place(cmp_layer, cm, int(ccx - cm.shape[1] / 2), int(ccy - cm.shape[0] / 2))
    height = np.maximum(height, medal * 0.55 + blur(cmp_layer, K) * 0.35 * medal)
    # 나침반 위 뾰족한 별
    star = Image.new("L", (N, M), 0)
    ds = ImageDraw.Draw(star)
    top = ccy - M * 0.23
    ds.polygon([(ccx, top - M * 0.13), (ccx + M * 0.035, top + M * 0.02), (ccx - M * 0.035, top + M * 0.02)], fill=255)
    height = np.maximum(height, blur(to_arr(star), K * 1.5) * 0.7)

    gold_mask = np.clip(height * 5, 0, 1) * (1 - inner_a * (1 - np.clip(thin + ring2, 0, 1)))
    height = height + (thin + ring2) * 0.25
    gold_mask = np.maximum(gold_mask, thin + ring2)
    rough = noise((M, N), 8, 43) * 0.5 + 0.5
    gold = metal(height, np.clip(gold_mask, 0, 1), strength=N / 12, rough=rough)
    # 안쪽 가죽
    lt = np.asarray(leather_gray.resize((N, M), Image.LANCZOS).convert("L"), np.float32) / 255
    base = np.array([58, 26, 18], np.float32)
    shade_in = 1 - 0.55 * np.clip(1 - to_arr(inner.filter(ImageFilter.MinFilter(int(K * 14) | 1)).filter(ImageFilter.GaussianBlur(K * 6))), 0, 1)
    leather = base[None, None, :] * (0.65 + 0.5 * lt)[..., None] * shade_in[..., None]
    la = np.dstack([np.clip(leather, 0, 255).astype(np.uint8), (inner_a * 255).astype(np.uint8)])
    out = soft_shadow(np.clip(outer_a + lbm + medal, 0, 1), K * 4, 0.7, (0, K * 3))
    out.alpha_composite(Image.fromarray(la, "RGBA"))
    out.alpha_composite(gold)
    return shrink(out, (W, H))


# ---------------------------------------------------------------- 깃발
def banner_tex(masks, W=128, H=256, K=4):
    N, M = W * K, H * K
    m = Image.new("L", (N, M), 0)
    d = ImageDraw.Draw(m)
    x0, x1 = N * 0.12, N * 0.88
    top, bot, notch = M * 0.06, M * 0.97, M * 0.84
    d.polygon([(x0, top), (x1, top), (x1, bot), (N / 2, notch), (x0, bot)], fill=255)
    cloth = to_arr(m)
    xx = np.linspace(0, 1, N)[None, :]
    yy = np.linspace(0, 1, M)[:, None]
    folds = 0.5 + 0.5 * np.sin(xx * math.pi * 3.2 + 0.6) * (0.4 + 0.6 * yy)
    fabric = noise((M, N), 3, 51) * 0.5 + 0.5
    red = np.array([150, 26, 22], np.float32)
    col = red[None, None, :] * (0.55 + 0.55 * folds)[..., None] * (0.9 + 0.1 * fabric)[..., None]
    col *= (1 - 0.35 * yy)[..., None] * np.ones((M, N, 1))
    # 금색 테두리 (안쪽으로 조금 들어간 선)
    inner = m.filter(ImageFilter.MinFilter(int(K * 7) | 1))
    inner2 = inner.filter(ImageFilter.MinFilter(int(K * 3) | 1))
    trim = np.clip(to_arr(inner) - to_arr(inner2), 0, 1)
    # 가운데 문장
    em = mask_resize(masks["griffin-symbol"], (int(N * 0.56), int(N * 0.56)))
    emb = np.zeros((M, N), np.float32)
    place(emb, em, int(N / 2 - em.shape[1] / 2), int(M * 0.36))
    # 위쪽 막대
    rod = np.zeros((M, N), np.float32)
    rod[int(M * 0.01):int(M * 0.06), :] = 1
    for cxk in (0.03, 0.97):
        yy2, xx2 = np.mgrid[0:M, 0:N].astype(np.float32)
        rod = np.maximum(rod, (np.sqrt((xx2 - N * cxk) ** 2 + (yy2 - M * 0.035) ** 2) < M * 0.035).astype(np.float32))
    gold_h = blur(trim, K) * 0.5 + blur(emb, K * 1.2) * 0.6 + blur(rod, K * 1.5) * 0.7
    gold_m = np.clip(trim + emb + rod, 0, 1)
    gold = metal(gold_h, gold_m, strength=N / 10)
    base = np.dstack([np.clip(col, 0, 255).astype(np.uint8), (cloth * 255).astype(np.uint8)])
    out = soft_shadow(np.clip(cloth + rod, 0, 1), K * 4, 0.6, (K * 2, K * 3))
    out.alpha_composite(Image.fromarray(base, "RGBA"))
    out.alpha_composite(gold)
    return shrink(out, (W, H))


# ---------------------------------------------------------------- 가죽끈과 버클
def strap_tex(leather_gray, W=128, H=64, K=4):
    N, M = W * K, H * K
    y0, y1 = int(M * 0.24), int(M * 0.76)
    strap = np.zeros((M, N), np.float32)
    strap[y0:y1, int(N * 0.02):] = 1
    sm = Image.fromarray((strap * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(K))
    strap = to_arr(sm)
    lt = np.asarray(leather_gray.resize((N, M), Image.LANCZOS).convert("L"), np.float32) / 255
    yy = np.linspace(0, 1, M)[:, None]
    prof = np.clip(1 - ((yy - 0.5) / 0.27) ** 2, 0, 1) ** 0.4
    base = np.array([82, 40, 24], np.float32)
    col = base[None, None, :] * (0.55 + 0.5 * lt)[..., None] * (0.6 + 0.5 * prof)[..., None]
    # 바느질
    stitch = np.zeros((M, N), np.float32)
    for yy_ in (y0 + K * 4, y1 - K * 4):
        for x in range(int(N * 0.05), int(N * 0.62), K * 6):
            stitch[yy_ - K // 2:yy_ + K // 2 + 1, x:x + K * 3] = 1
    col = col * (1 - 0.5 * stitch[..., None]) + np.array([200, 170, 120])[None, None, :] * 0.6 * stitch[..., None]
    leather = np.dstack([np.clip(col, 0, 255).astype(np.uint8), (strap * 255).astype(np.uint8)])
    # 버클: 둥근 사각 고리 + 가로대 + 혀
    bx0, bx1 = int(N * 0.60), int(N * 0.86)
    by0, by1 = int(M * 0.10), int(M * 0.90)
    ring = Image.new("L", (N, M), 0)
    d = ImageDraw.Draw(ring)
    d.rounded_rectangle((bx0, by0, bx1, by1), radius=K * 8, fill=255)
    d.rounded_rectangle((bx0 + K * 8, by0 + K * 8, bx1 - K * 8, by1 - K * 8), radius=K * 4, fill=0)
    d.rectangle(((bx0 + bx1) / 2 - K * 2.5, by0 + K * 4, (bx0 + bx1) / 2 + K * 2.5, by1 - K * 4), fill=255)
    d.rounded_rectangle((int(N * 0.70), int(M * 0.46), int(N * 0.97), int(M * 0.54)), radius=K * 2, fill=255)
    rm = to_arr(ring)
    h = blur(rm, K * 2)
    buckle = metal(h, rm, strength=N / 10)
    # 끈 끝이 버클을 지나 나온다
    out = soft_shadow(np.clip(strap + rm, 0, 1), K * 3, 0.6, (K, K * 2))
    out.alpha_composite(Image.fromarray(leather, "RGBA"))
    out.alpha_composite(buckle)
    return shrink(out, (W, H))


# ---------------------------------------------------------------- 탭 / 버튼 / 배지 / 입력칸
def _shape_tex(shape_mask, fill_rgb, K, border=5, gold=True, edge_dark=0.5, W=None, H=None, bevel=1.0, inner_shadow=0.0):
    M, N = shape_mask.shape
    sm = Image.fromarray((shape_mask * 255).astype(np.uint8))
    inner = to_arr(sm.filter(ImageFilter.MinFilter(int(K * border) | 1)))
    rim = np.clip(shape_mask - inner, 0, 1)
    # 채움
    fill = np.dstack([fill_rgb[..., i] for i in range(3)])
    if inner_shadow:
        ins = blur(inner, K * 4)
        fill = fill * (1 - inner_shadow * (1 - ins))[..., None]
    base = np.dstack([np.clip(fill, 0, 255).astype(np.uint8), (inner * 255).astype(np.uint8)])
    out = Image.new("RGBA", (N, M), (0, 0, 0, 0))
    out.alpha_composite(Image.fromarray(base, "RGBA"))
    if gold:
        # 윗면이 평평한 테: 위아래·좌우 어느 쪽 테도 고르게 금빛이 난다
        h = np.clip(blur(rim, K * 1.0) * 1.7, 0, 0.85) * bevel
        out.alpha_composite(metal(h, rim, strength=N / 14))
    return out


def tab_tex(active, leather_gray, W=256, H=64, K=4):
    N, M = W * K, H * K
    m = Image.new("L", (N, M), 0)
    d = ImageDraw.Draw(m)
    s = N * 0.07
    r = K * 10
    d.polygon([(0, M), (s, r), (s + r * 0.6, 0), (N - s - r * 0.6, 0), (N - s, r), (N, M)], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(K * 1.5)).point(lambda v: 255 if v > 128 else 0)
    shape = to_arr(m)
    yy = np.linspace(0, 1, M)[:, None, None]
    if active:
        top, bot = np.array([252, 222, 140], np.float32), np.array([196, 142, 58], np.float32)
        fill = top * (1 - yy) + bot * yy
        fill = fill * np.ones((M, N, 3))
    else:
        lt = np.asarray(leather_gray.resize((N, M), Image.LANCZOS).convert("L"), np.float32)[..., None] / 255
        base = np.array([58, 27, 18], np.float32)
        fill = base * (0.6 + 0.5 * lt) * (1.2 - 0.55 * yy)
    out = _shape_tex(shape, fill, K, border=6, inner_shadow=0.45 if not active else 0.1)
    return shrink(out, (W, H))


def button_tex(kind, leather_gray, W=256, H=64, K=4):
    N, M = W * K, H * K
    shape = rounded_mask(N, M, (K, K, N - K, M - K), K * 10)
    yy = np.linspace(0, 1, M)[:, None, None]
    lt = np.asarray(leather_gray.resize((N, M), Image.LANCZOS).convert("L"), np.float32)[..., None] / 255
    if kind == "active":
        top, bot = np.array([248, 214, 132], np.float32), np.array([190, 136, 56], np.float32)
        fill = (top * (1 - yy) + bot * yy) * (0.92 + 0.08 * lt)
    elif kind == "red":
        base = np.array([150, 32, 24], np.float32)
        fill = base * (0.75 + 0.3 * lt) * (1.2 - 0.5 * yy)
    else:
        base = np.array([70, 34, 22], np.float32)
        fill = base * (0.6 + 0.5 * lt) * (1.2 - 0.5 * yy)
    out = _shape_tex(shape, fill * np.ones((M, N, 3)), K, border=4.5, inner_shadow=0.35)
    return shrink(out, (W, H))


def badge_tex(W=64, H=32, K=8):
    N, M = W * K, H * K
    shape = rounded_mask(N, M, (K, K, N - K, M - K), M // 2 - K)
    fill = np.ones((M, N, 3)) * np.array([38, 22, 16], np.float32)
    out = _shape_tex(shape, fill, K, border=2.6, inner_shadow=0.4)
    return shrink(out, (W, H))


def field_tex(W=256, H=64, K=4):
    N, M = W * K, H * K
    shape = rounded_mask(N, M, (K, K, N - K, M - K), K * 9)
    fill = np.ones((M, N, 3)) * np.array([40, 26, 19], np.float32)
    out = _shape_tex(shape, fill, K, border=3.2, inner_shadow=0.6)
    return shrink(out, (W, H))


def icon_frame_tex(S=64, K=8):
    N = S * K
    outer = rounded_mask(N, N, (0, 0, N - 1, N - 1), K * 4)
    inner = rounded_mask(N, N, (K * 6, K * 6, N - K * 6, N - K * 6), K * 2)
    rim = np.clip(outer - inner, 0, 1)
    # 윗면이 평평한 테 + 가운데 가는 홈
    h = np.clip(blur(rim, K * 1.0) * 1.8, 0, 0.85)
    groove = np.clip(rounded_mask(N, N, (K * 2.6, K * 2.6, N - K * 2.6, N - K * 2.6), K * 3)
                     - rounded_mask(N, N, (K * 3.6, K * 3.6, N - K * 3.6, N - K * 3.6), K * 2.6), 0, 1)
    h = h - blur(groove, K * 0.5) * 0.18
    img = metal(h, rim, strength=N / 12)
    return shrink(img, (S, S))


def close_tex(S=64, K=8):
    N = S * K
    shape = rounded_mask(N, N, (K * 2, K * 2, N - K * 2, N - K * 2), K * 6)
    yy = np.linspace(0, 1, N)[:, None, None]
    fill = np.array([168, 34, 26], np.float32) * (1.15 - 0.55 * yy) * np.ones((N, N, 3))
    out = _shape_tex(shape, fill, K, border=7, inner_shadow=0.45)
    x = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(x)
    a, b = N * 0.32, N * 0.68
    d.line((a, a, b, b), fill=255, width=int(K * 6.5))
    d.line((a, b, b, a), fill=255, width=int(K * 6.5))
    xm = to_arr(x.filter(ImageFilter.GaussianBlur(K * 0.6)))
    xg = metal(blur(xm, K * 1.5), xm, strength=N / 10, base=(235, 205, 150))
    out.alpha_composite(xg)
    return shrink(out, (S, S))


def scroll_thumb_tex(W=32, H=64, K=8):
    N, M = W * K, H * K
    shape = rounded_mask(N, M, (K * 6, K * 2, N - K * 6, M - K * 2), K * 10)
    h = blur(shape, K * 4)
    return shrink(metal(h, shape, strength=N / 8), (W, H))


def scroll_arrow_tex(S=32, K=8):
    N = S * K
    shape = rounded_mask(N, N, (K * 2, K * 2, N - K * 2, N - K * 2), K * 4)
    fill = np.ones((N, N, 3)) * np.array([60, 30, 20], np.float32)
    out = _shape_tex(shape, fill, K, border=3.5, inner_shadow=0.3)
    t = Image.new("L", (N, N), 0)
    ImageDraw.Draw(t).polygon([(N * 0.5, N * 0.30), (N * 0.74, N * 0.66), (N * 0.26, N * 0.66)], fill=255)
    tm = to_arr(t.filter(ImageFilter.GaussianBlur(K * 0.5)))
    out.alpha_composite(metal(blur(tm, K), tm, strength=N / 10))
    return shrink(out, (S, S))


def checkbox_tex(S=32, K=8):
    N = S * K
    shape = rounded_mask(N, N, (K * 3, K * 3, N - K * 3, N - K * 3), K * 3)
    fill = np.ones((N, N, 3)) * np.array([226, 206, 160], np.float32)
    out = _shape_tex(shape, fill, K, border=2.6, gold=False, inner_shadow=0.35)
    sm = Image.fromarray((shape * 255).astype(np.uint8))
    rim = np.clip(shape - to_arr(sm.filter(ImageFilter.MinFilter(int(K * 2.6) | 1))), 0, 1)
    rim_img = np.dstack([np.full((N, N), 70, np.uint8), np.full((N, N), 44, np.uint8), np.full((N, N), 26, np.uint8),
                         (rim * 255).astype(np.uint8)])
    out.alpha_composite(Image.fromarray(rim_img, "RGBA"))
    return shrink(out, (S, S))


# ---------------------------------------------------------------- 양피지 칸
def parchment_panel(parchment_gray, S=512, K=2, seed=61):
    """가장자리가 거칠게 찢기고 그을린 양피지 한 장 (회색조, 게임에서 색을 입힌다)"""
    N = S * K
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32) / N
    d = np.minimum(np.minimum(xx, 1 - xx), np.minimum(yy, 1 - yy))
    rough = noise((N, N), 10, seed) * 0.007 + noise((N, N), 40, seed + 1) * 0.008
    dd = d + rough
    alpha = np.clip((dd - 0.004) / 0.004, 0, 1)
    burn = np.clip(1 - (dd - 0.004) / 0.05, 0, 1) ** 1.6
    p = np.asarray(parchment_gray.resize((N, N), Image.LANCZOS).convert("L"), np.float32)
    v = p * (1 - 0.55 * burn) - 18 * np.clip(1 - (dd - 0.004) / 0.012, 0, 1)
    img = np.dstack([np.clip(v, 0, 255).astype(np.uint8)] * 3 + [(alpha * 255).astype(np.uint8)])
    return shrink(Image.fromarray(img, "RGBA"), (S, S))


# ---------------------------------------------------------------- 잉크 삽화 (판화처럼)
def engrave(mask, hatch_period=7, angle=35, outline=3, density=0.7):
    """실루엣 마스크 → 윤곽선 + 빗금 (0~1 배열)"""
    H, W = mask.shape
    m = Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8))
    er = to_arr(m.filter(ImageFilter.MinFilter(outline * 2 + 1)))
    edge = np.clip(mask - er, 0, 1)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    t = math.radians(angle)
    ph = (xx * math.cos(t) + yy * math.sin(t)) % hatch_period
    lines = (ph < hatch_period * 0.32).astype(np.float32)
    # 오른쪽 아래가 더 짙은 그늘
    shade_w = np.clip((xx / W) * 0.6 + (yy / H) * 0.6 - 0.25, 0, 1)
    hatch = lines * er * (0.35 + 0.65 * shade_w) * density
    return np.clip(edge + hatch, 0, 1)


def sketch_scene(masks, kind, W=512, H=256, K=2):
    N, M = W * K, H * K
    ink = np.zeros((M, N), np.float32)
    rng = random.Random(7 if kind == "castle" else 11)
    # 멀리 산맥 (능선 + 짧은 빗금)
    ridge = Image.new("L", (N, M), 0)
    d = ImageDraw.Draw(ridge)
    pts = []
    x = 0
    y = M * 0.42
    while x <= N:
        pts.append((x, y))
        x += rng.randint(30, 70) * K // 2
        y = max(M * 0.18, min(M * 0.55, y + rng.uniform(-60, 60) * K / 2))
    d.line(pts, fill=255, width=K * 2)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if y1 > y0:
            for k in range(4):
                tx = x0 + (x1 - x0) * (0.2 + 0.2 * k)
                ty = y0 + (y1 - y0) * (0.2 + 0.2 * k)
                d.line((tx, ty, tx + K * 6, ty + K * 14), fill=180, width=K)
    ink = np.maximum(ink, to_arr(ridge) * 0.6)
    # 땅
    ground = Image.new("L", (N, M), 0)
    dg = ImageDraw.Draw(ground)
    gy = M * 0.86
    dg.line([(N * 0.02, gy + 8 * K), (N * 0.3, gy), (N * 0.6, gy + 4 * K), (N * 0.98, gy - 4 * K)], fill=255, width=K * 2)
    for _ in range(40):
        x = rng.uniform(0.05, 0.95) * N
        y = gy + rng.uniform(4, 30) * K
        dg.line((x, y, x + rng.uniform(10, 26) * K, y), fill=150, width=K)
    ink = np.maximum(ink, to_arr(ground) * 0.7)

    def put(name, size, x, y, flip=False, period=7):
        mk = masks[name]
        if flip:
            mk = mk.transpose(Image.FLIP_LEFT_RIGHT)
        a = mask_resize(mk, (int(size * K), int(size * K)))
        e = engrave(a, hatch_period=period * K / 2, outline=K + 1)
        # 뒤의 선을 가린다
        layer = np.zeros_like(ink)
        place(layer, a, int(x * K), int(y * K))
        ink[:] = ink * (1 - layer)
        place(ink, e, int(x * K), int(y * K))

    if kind == "castle":
        put("stone-bridge", 150, 18, 128)
        put("castle-ruins", 190, 150, 55)
        put("pine-tree", 70, 360, 150)
        put("pine-tree", 52, 410, 168)
        put("pine-tree", 60, 450, 160, flip=True)
    else:
        put("forest-camp", 180, 230, 80)
        put("tower-flag", 90, 150, 112)
        put("pine-tree", 80, 420, 130)
        put("pine-tree", 60, 470, 152)
        put("pine-tree", 56, 80, 158, flip=True)
    # 가장자리는 흐리게 사라진다
    yy, xx = np.mgrid[0:M, 0:N].astype(np.float32)
    fade = np.clip(np.minimum(np.minimum(xx / (N * 0.12), (N - xx) / (N * 0.12)), np.minimum(yy / (M * 0.1), (M - yy) / (M * 0.1))), 0, 1)
    ink = ink * fade
    img = np.dstack([np.full((M, N), 255, np.uint8)] * 3 + [(np.clip(ink, 0, 1) * 255).astype(np.uint8)])
    return shrink(Image.fromarray(img, "RGBA"), (W, H))


# ---------------------------------------------------------------- 표지 메달
def cover_medallion(masks, leather_gray, S=256, K=4):
    N = S * K
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    r = np.sqrt((xx - N / 2) ** 2 + (yy - N / 2) ** 2) / (N / 2)
    ring = np.clip((0.96 - r) / 0.02, 0, 1) * np.clip((r - 0.80) / 0.02, 0, 1)
    ang = np.arctan2(yy - N / 2, xx - N / 2)
    ticks = (np.cos(ang * 32) > 0.6).astype(np.float32) * np.clip((0.86 - r) / 0.01, 0, 1) * np.clip((r - 0.80) / 0.01, 0, 1)
    h = blur(ring, K * 3) * 0.8 + ticks * 0.15
    inner = np.clip((0.80 - r) / 0.01, 0, 1)
    gm = mask_resize(masks["griffin-symbol"], (int(N * 0.62), int(N * 0.62)))
    g = np.zeros((N, N), np.float32)
    place(g, gm, int(N * 0.19), int(N * 0.18))
    h = np.maximum(h, blur(g, K * 1.6) * 0.75)
    mask = np.clip(ring + g, 0, 1)
    gold = metal(h, mask, strength=N / 9)
    lt = np.asarray(leather_gray.resize((N, N), Image.LANCZOS).convert("L"), np.float32) / 255
    base = np.array([48, 22, 15], np.float32) * (0.6 + 0.5 * lt)[..., None] * (1 - 0.4 * np.clip(r / 0.8, 0, 1) ** 3)[..., None]
    disc = np.dstack([np.clip(base, 0, 255).astype(np.uint8), (inner * 255).astype(np.uint8)])
    out = soft_shadow(np.clip(r < 0.97, 0, 1).astype(np.float32), K * 4, 0.6, (0, K * 3))
    out.alpha_composite(Image.fromarray(disc, "RGBA"))
    out.alpha_composite(gold)
    return shrink(out, (S, S))
