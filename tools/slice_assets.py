"""BIG CHRONICLE :: 에셋 시트 자르기

art/ 폴더의 에셋 시트 3장(사용자가 제공한 그림)에서 UI 조각을 잘라
(그리고 로고 그림 logo.png · title.png · minimap.png 가 있으면 바탕을 걷어 내)
투명 배경 TGA(2의 거듭제곱 크기)로 저장하고, 조각의 크기와 늘림 여백을
BigChronicle/UI/Atlas.lua 로 내보낸다.

    python3 tools/slice_assets.py [미리보기.png]

필요: Pillow, numpy, scipy
"""
import math
import pathlib
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

ROOT = pathlib.Path(__file__).resolve().parent.parent
ART = ROOT / "art"
MEDIA = ROOT / "BigChronicle" / "Media"
UIOUT = ROOT / "BigChronicle" / "UI" / "Atlas.lua"
(MEDIA / "UI").mkdir(parents=True, exist_ok=True)

SHEET = {
    "K": Image.open(ART / "sheet-kit.png").convert("RGB"),      # 버튼·칸·틀 모음 (가죽 바탕)
    "P": Image.open(ART / "sheet-panels.png").convert("RGB"),   # 판·탭·명판 모음
    "R": Image.open(ART / "sheet-parts.png").convert("RGB"),    # 인장·막대·아이콘 모음
}
THR = {"K": 60, "P": 45, "R": 45}   # 바탕과 조각을 가르는 밝기
SCALE = 0.7                          # 게임에서 보이는 크기 ≈ 원본의 0.7배

atlas = {}
preview = []


def pot(n):
    """원본의 0.7배 이상을 담는 가장 작은 2의 거듭제곱"""
    return max(16, 2 ** math.ceil(math.log2(max(1.0, n * SCALE))))


def save(name, img, **meta):
    w, h = img.size
    out = img.resize((pot(w), pot(h)), Image.LANCZOS)
    out.save(MEDIA / "UI" / f"{name}.tga")
    atlas[name] = dict(w=w, h=h, **meta)
    preview.append((name, img))
    return img


def mask_of(rgb, thr, close=2, fill=True):
    a = np.asarray(rgb).astype(np.int32)
    m = a.max(axis=2) > thr
    if close:
        m = ndi.binary_closing(m, iterations=close)
    if fill:
        m = ndi.binary_fill_holes(m)
    return m


def cut(sheet, box, pad=4, thr=None, close=2, fill=True, keep="center", glow=False, soft=0.8):
    """조각 하나를 잘라 RGBA 로 돌려준다. 바탕은 투명하게."""
    src = SHEET[sheet]
    x0, y0, x1, y1 = box
    X0, Y0, X1, Y1 = max(0, x0 - pad), max(0, y0 - pad), min(src.size[0], x1 + pad), min(src.size[1], y1 + pad)
    rgb = src.crop((X0, Y0, X1, Y1))
    thr = thr or THR[sheet]
    m = mask_of(rgb, thr, close, fill)
    lab, n = ndi.label(m)
    if n > 1 and keep != "all":
        # 상자 안쪽과 가장 많이 겹치는 덩어리(들)만 남긴다 (옆 조각의 끄트머리를 버린다)
        inner = np.zeros_like(m)
        inner[y0 - Y0:y1 - Y0, x0 - X0:x1 - X0] = True
        sizes = ndi.sum(inner, lab, range(1, n + 1))
        best = sizes.max()
        ok = [i + 1 for i, s in enumerate(sizes) if s >= best * (0.02 if keep == "parts" else 0.5)]
        m = np.isin(lab, ok)
    alpha = ndi.gaussian_filter(m.astype(np.float32), soft)
    if glow:
        # 둘레의 빛 번짐은 밝기에 비례해 부드럽게 남긴다
        v = np.asarray(rgb).astype(np.float32).max(axis=2)
        ramp = np.clip((v - 45) / 90, 0, 1)
        near = ndi.gaussian_filter(ndi.binary_dilation(m, iterations=7).astype(np.float32), 2.5)
        alpha = np.maximum(alpha, ramp * near)
    out = np.dstack([np.asarray(rgb), (np.clip(alpha, 0, 1) * 255).astype(np.uint8)])
    return Image.fromarray(out, "RGBA")


def tile_from(sheet, box, flatten=40):
    """깨끗한 부분을 거울처럼 이어 붙여 이음매 없는 반복 무늬를 만든다."""
    patch = np.asarray(SHEET[sheet].crop(box)).astype(np.float32)
    if flatten:
        # 큰 얼룩(밝기 기울기)은 걷어 내고 결만 남긴다 → 반복해도 무늬가 눈에 띄지 않는다
        low = np.dstack([ndi.gaussian_filter(patch[..., c], flatten) for c in range(3)])
        mean = low.mean(axis=(0, 1), keepdims=True)
        patch = mean + (patch - low) * 0.55      # 결의 대비도 조금 낮춘다 (거울 무늬가 덜 보이게)
    patch = np.clip(patch, 0, 255).astype(np.uint8)
    top = np.concatenate([patch, patch[:, ::-1]], axis=1)
    full = np.concatenate([top, top[::-1]], axis=0)
    return Image.fromarray(full, "RGB").convert("RGBA")


def leather_tile():
    """창 안쪽 가죽: 시트 K 아래쪽의 깨끗한 띠(높이 36)를 여러 군데에서 떼어 세로로 엮는다.
    줄과 줄은 서서히 섞고, 위아래·좌우가 이어지도록 만든다."""
    src = np.asarray(SHEET["K"]).astype(np.float32)
    band = src[964:1000, 70:1380]                  # 1310 x 36
    rows, rh, ov, w = 8, 32, 4, 256
    H = rows * rh
    out = np.zeros((H, w, 3), np.float32)
    wsum = np.zeros((H, w, 1), np.float32)
    for i in range(rows):
        seg = band[:, i * 150:i * 150 + w]
        seg = seg - seg.mean(axis=1, keepdims=True) + seg.mean(axis=(0, 1), keepdims=True)   # 줄무늬 방지
        if i % 2:
            seg = seg[::-1]
        weight = np.ones((rh + ov, 1, 1), np.float32)
        weight[:ov, 0, 0] = np.linspace(0, 1, ov, endpoint=False)
        weight[-ov:, 0, 0] = np.linspace(1, 0, ov, endpoint=False)
        for k in range(rh + ov):
            y = (i * rh + k) % H
            out[y] += seg[k] * weight[k]
            wsum[y] += weight[k]
    out /= np.maximum(wsum, 1e-6)
    low = np.dstack([ndi.gaussian_filter(out[..., c], 30, mode="wrap") for c in range(3)])
    out = np.clip(out - low + low.mean(axis=(0, 1), keepdims=True), 0, 255).astype(np.uint8)
    full = np.concatenate([out, out[:, ::-1]], axis=1)   # 좌우는 거울처럼 이어 붙인다 → 512 x 256
    return Image.fromarray(full, "RGB").resize((512, 512), Image.LANCZOS).convert("RGBA")


def feather_inner(img, l, r, t, b, width):
    """9조각 판의 가운데 쪽 가장자리를 서서히 투명하게 (아래에 깔리는 반복 무늬와 자연스럽게 섞인다)"""
    a = np.asarray(img).astype(np.float32).copy()
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.minimum(np.minimum(xx - (l - width), (w - r + width) - xx), np.minimum(yy - (t - width), (h - b + width) - yy))
    fade = np.clip(1 - d / width, 0, 1)   # 안쪽 경계에서 0, 바깥쪽으로 width 만큼 가면 1
    a[..., 3] *= fade
    return Image.fromarray(a.astype(np.uint8), "RGBA")


# ------------------------------------------------------------------ 창틀 (시트 K 전체가 하나의 창)
def window_frame():
    src = SHEET["K"]
    a = np.asarray(src).astype(np.int32)
    v = a.max(axis=2)
    H, W = v.shape
    # ① 창의 바깥 윤곽: 네 귀퉁이에서 시작해 검은 바탕만 따라가며 채운 곳이 '바깥'
    solid = ndi.binary_closing(v > 30, iterations=4)
    seeds = np.zeros_like(solid)
    seeds[0, :] = seeds[-1, :] = True
    seeds[:, 0] = seeds[:, -1] = True
    outside = ndi.binary_propagation(seeds & ~solid, mask=~solid)
    shape = ndi.binary_fill_holes(~outside)
    dist = ndi.distance_transform_edt(shape)
    # ② 가죽 테두리 띠: 바깥 윤곽에서 안쪽으로 46px (가죽 관 + 박음질), 그 뒤 12px 에 걸쳐 사라진다
    band = np.clip((58 - dist) / 12.0, 0, 1) * shape
    # ③ 금 모서리와 위아래 장식: 테두리와 이어진 밝은 덩어리
    bright = ndi.binary_closing(v > 52, iterations=4)
    lab, n = ndi.label(bright)
    ring = (dist > 0) & (dist < 40)
    sizes = ndi.sum(ring, lab, range(1, n + 1))
    gold = lab == (int(np.argmax(sizes)) + 1)
    holes, hn = ndi.label(~gold)
    hs = ndi.sum(np.ones_like(gold), holes, range(1, hn + 1))
    for i, sz in enumerate(hs):
        if sz < 2500:
            gold |= holes == (i + 1)
    gold &= shape
    alpha = np.maximum(band, ndi.gaussian_filter(gold.astype(np.float32), 1.0))
    alpha *= ndi.gaussian_filter(shape.astype(np.float32), 0.8)
    rgba = Image.fromarray(np.dstack([np.asarray(src), (np.clip(alpha, 0, 1) * 255).astype(np.uint8)]), "RGBA")
    C, T, B, S = 124, 70, 92, 64
    save("FrameTL", rgba.crop((0, 0, C, C)))
    save("FrameTR", rgba.crop((W - C, 0, W, C)))
    save("FrameBL", rgba.crop((0, H - C, C, H)))
    save("FrameBR", rgba.crop((W - C, H - C, W, H)))
    # 위아래 가장자리: 장식이 없는 구간을 거울처럼 이어 붙여 가로로 반복할 수 있게 한다 (창 폭이 달라도 쓸 수 있다)
    def htile(y0, y1):
        seg = np.asarray(rgba.crop((C + 6, y0, 560, y1)))
        return Image.fromarray(np.concatenate([seg, seg[:, ::-1]], axis=1), "RGBA")
    et = htile(0, T)
    save("FrameT", et, tile=et.size[0])
    eb = htile(H - T, H)
    save("FrameB", eb, tile=eb.size[0])
    save("FrameL", rgba.crop((0, C, S, H - C)))
    save("FrameR", rgba.crop((W - S, C, W, H - C)))
    # 위아래 가운데의 나침반·월계수 장식은 따로
    save("OrnamentTop", rgba.crop((580, 0, 868, T)))
    save("OrnamentBottom", rgba.crop((580, H - B, 868, H)))
    atlas["Frame"] = dict(w=W, h=H, corner=C, top=T, bottom=T, side=S)


def erase_text(img, inset):
    """배지 안에 그려진 숫자를 지운다: 테 안쪽을 그 둘레의 색으로 고르게 채운다."""
    a = np.asarray(img).astype(np.float32).copy()
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r = h / 2 - inset
    cx0, cx1, cy = h / 2, w - h / 2, h / 2
    dx = np.where(xx < cx0, cx0 - xx, np.where(xx > cx1, xx - cx1, 0))
    inside = np.sqrt(dx * dx + (yy - cy) ** 2) < r
    ringband = (np.sqrt(dx * dx + (yy - cy) ** 2) < r + 2) & ~inside
    col = np.median(a[ringband][:, :3], axis=0)
    noise = ndi.gaussian_filter(np.random.default_rng(3).standard_normal((h, w)), 1.2) * 3
    for c in range(3):
        a[..., c] = np.where(inside, col[c] + noise, a[..., c])
    soft = ndi.gaussian_filter(inside.astype(np.float32), 1.0)[..., None]
    orig = np.asarray(img).astype(np.float32)
    a[..., :3] = orig[..., :3] * (1 - soft) + a[..., :3] * soft
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def from_white(path, width, square=False):
    """로고 그림을 투명 바탕으로 다듬는다.
    그림에 이미 투명 바탕이 있으면 그대로 쓰고, 흰 바탕이면 바탕을 걷어 내고(밝고 색이 옅은 곳 = 바탕)
    가장자리의 흰 기운을 뺀다."""
    src = Image.open(path)
    if src.mode in ("RGBA", "LA") and np.asarray(src.convert("RGBA"))[..., 3].min() < 16:
        img = src.convert("RGBA")
        a = np.asarray(img)[..., 3]
        ys, xs = np.nonzero(a > 8)
        img = img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        return fit(img, width, square)
    rgb = np.asarray(src.convert("RGB")).astype(np.float32)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    bg = np.clip((mn - 205) / 35, 0, 1) * np.clip((45 - (mx - mn)) / 30, 0, 1)
    a = 1 - bg
    # 바탕 쪽에 흩어진 작은 얼룩은 지운다
    solid = ndi.binary_opening(a > 0.5, iterations=2)
    lab, n = ndi.label(solid)
    if n:
        sizes = ndi.sum(solid, lab, range(1, n + 1))
        keep = np.isin(lab, [i + 1 for i, v in enumerate(sizes) if v > solid.sum() * 0.002])
        a = a * ndi.binary_dilation(keep, iterations=3)
    # 흰색과 섞인 가장자리 색을 되돌린다: c = (c - (1 - a) * 255) / a
    k = np.maximum(a, 0.05)[..., None]
    col = np.clip((rgb - (1 - k) * 255) / k, 0, 255)
    out = np.dstack([col, a[..., None] * 255]).astype(np.uint8)
    img = Image.fromarray(out, "RGBA")
    ys, xs = np.nonzero(a > 0.03)
    img = img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    return fit(img, width, square)


def scroll_card(src, card_w=620, card_h=124, l=76, r=100, pad=4, tilt=2.7):
    """장 제목 카드용 두루마리 한 장.
    게임 화면 비율(620×124)대로 가운데를 늘여 붙인 뒤, 펼쳐진 면이 오른쪽으로 처지지 않도록
    반시계 방향으로 tilt도 돌려 둔다. 글씨를 놓을 면의 가운데 높이(face)도 함께 적는다."""
    w, h = src.size
    k = (card_h) / (h - 2 * pad)                     # 화면 픽셀 / 원본 픽셀
    band_w = round(card_w / k) + 2 * pad              # 원본 픽셀로 잰 카드 폭
    mid_w = band_w - l - r
    up = 2                                            # 돌릴 때 뭉개지지 않도록 두 배로 그린다
    left = src.crop((0, 0, l, h))
    mid = src.crop((l, 0, w - r, h)).resize((mid_w, h), Image.LANCZOS)
    right = src.crop((w - r, 0, w, h))
    band = Image.new("RGBA", (band_w, h), (0, 0, 0, 0))
    band.paste(left, (0, 0)); band.paste(mid, (l, 0)); band.paste(right, (l + mid_w, 0))
    band = band.resize((band_w * up, h * up), Image.LANCZOS)
    rot = band.rotate(tilt, resample=Image.BICUBIC, expand=True)
    a = np.asarray(rot)[..., 3]
    ys, xs = np.nonzero(a > 8)
    rot = rot.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    a = np.asarray(rot)[..., 3]
    # 글씨가 놓일 가운데 절반에서 펼쳐진 면의 위·아래 끝을 재어 가운데 높이를 구한다
    cw = rot.size[0]
    centers = []
    for x in range(int(cw * 0.3), int(cw * 0.7), 4):
        col = np.nonzero(a[:, x] > 200)[0]
        if len(col):
            centers.append((col.min() + col.max()) / 2)
    face = float(np.mean(centers))
    # 두 배로 그린 그대로 저장한다 (화면 폭 620px보다 촘촘하게)
    # band: 카드 폭(card_w)에 해당하는 그림 픽셀 수 → 게임에서 이 비율로 크기를 정한다
    save("ScrollCard", rot, band=(band_w - 2 * pad) * up, face=round(face, 1))


def plain_edge_middles(img, l, r, band, strip):
    """위·아래 가장자리의 가운데 부분(장식이 있는 곳)을 무늬 없는 금테 조각을 이어 붙여 채운다.
    band: 가장자리 두께(원본 픽셀), strip: 이어 붙일 무늬 없는 구간 (x0, x1)"""
    a = np.asarray(img.convert("RGBA")).copy()
    h, w = a.shape[:2]
    x0, x1 = strip
    piece_w = x1 - x0
    for rows in (slice(0, band), slice(h - band, h)):
        src = a[rows, x0:x1].copy()
        x = l
        while x < w - r:
            n = min(piece_w, w - r - x)
            a[rows, x:x + n] = src[:, :n]
            x += n
    return Image.fromarray(a, "RGBA")


def feather_sides(img, width):
    """조각의 왼쪽·오른쪽 끝을 부드럽게 투명하게 (겹쳐 놓았을 때 이음매가 보이지 않도록)"""
    a = np.asarray(img.convert("RGBA")).astype(np.float32)
    w = a.shape[1]
    ramp = np.ones(w, np.float32)
    for i in range(width):
        k = (i + 1) / (width + 1)
        ramp[i] = min(ramp[i], k)
        ramp[w - 1 - i] = min(ramp[w - 1 - i], k)
    a[..., 3] *= ramp[None, :]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def match_gold(img, refs):
    """img 의 금빛을 refs(창틀 조각들)의 금박 색에 맞춘다.
    밝기 순서는 그대로 두고, 각 채널의 분포를 창틀 금박의 분포로 옮긴다 (히스토그램 맞추기)."""
    def gold_pixels(im):
        a = np.asarray(im.convert("RGBA")).astype(np.float32)
        rgb, al = a[..., :3], a[..., 3]
        mx, mn = rgb.max(axis=2), rgb.min(axis=2)
        # 금박: 불투명하고, 노랑~주황 계열이며, 어느 정도 밝은 곳
        m = (al > 230) & (mx > 90) & ((mx - mn) > 40) & (rgb[..., 0] >= rgb[..., 1]) & (rgb[..., 1] >= rgb[..., 2])
        return rgb[m]
    ref = np.concatenate([gold_pixels(r) for r in refs])
    a = np.asarray(img.convert("RGBA")).astype(np.float32)
    rgb, al = a[..., :3], a[..., 3]
    m = al > 8
    out = rgb.copy()
    for c in range(3):
        src = rgb[..., c][m]
        order = np.argsort(src, kind="stable")
        ranks = np.empty_like(order)
        ranks[order] = np.arange(len(src))
        q = ranks / max(1, len(src) - 1)
        out[..., c][m] = np.quantile(ref[:, c], q)
    res = np.dstack([np.clip(out, 0, 255), al]).astype(np.uint8)
    return Image.fromarray(res, "RGBA")


def fit(img, width, square=False):
    if square:
        side = max(img.size)
        sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        sq.paste(img, ((side - img.size[0]) // 2, (side - img.size[1]) // 2))
        return sq.resize((width, width), Image.LANCZOS)
    h = round(img.size[1] * width / img.size[0])
    return img.resize((width, h), Image.LANCZOS)


def main():
    window_frame()

    # 반복 무늬: 창 안쪽의 짙은 가죽, 양피지
    save("LeatherTile", leather_tile(), tile=512, tileH=512)
    img = tile_from("R", (536, 128, 716, 244), flatten=30)   # 삽화가 없는 깨끗한 부분
    save("ParchmentTile", img, tile=img.size[0], tileH=img.size[1])

    # --- 판과 명판
    save("Plaque", cut("P", (450, 141, 1111, 279), keep="parts"))
    edge = cut("P", (29, 513, 385, 631))
    l, t = 30, 26
    save("PaperEdge", feather_inner(edge, l + 4, l + 4, t + 4, t + 4, 14), l=l + 4, r=l + 4, t=t + 4, b=t + 4, pad=4)
    save("PaperCastle", cut("P", (1093, 514, 1415, 631)))
    save("PaperMountain", cut("P", (750, 514, 1074, 631)))
    save("Card", cut("P", (746, 825, 956, 966)), l=40, r=40, t=40, b=40, pad=4)
    save("Tab", cut("P", (206, 344, 381, 396)), l=36, r=36, pad=4)
    save("TabActive", cut("P", (596, 345, 782, 398)), l=36, r=36, pad=4)
    save("Divider", cut("P", (49, 474, 437, 509), keep="all", close=1, fill=False, soft=0.6), pad=4)
    save("Divider2", cut("P", (483, 476, 769, 505), keep="all", close=1, fill=False, soft=0.6), pad=4)

    # --- 버튼·칸·틀 (시트 K)
    save("Button", cut("K", (77, 258, 294, 323)), l=30, r=30, pad=4)
    save("ButtonGold", cut("K", (317, 259, 523, 321), pad=10, glow=True), l=36, r=36, pad=10)
    save("ButtonDark", cut("K", (546, 258, 754, 324)), l=30, r=30, pad=4)
    save("Close", cut("K", (1176, 86, 1264, 175)), pad=4)
    save("Gear", cut("K", (1286, 86, 1373, 175)), pad=4)
    save("CheckBox", cut("K", (643, 372, 685, 413)), pad=4)
    save("CheckBoxOn", cut("K", (711, 371, 754, 414)), pad=4)
    search = cut("K", (80, 468, 454, 530))
    save("FieldSearch", search, l=62, r=26, pad=4)
    # 돋보기 없는 입력칸: 오른쪽 끝을 뒤집어 왼쪽 끝으로 쓴다
    w, h = search.size
    right = search.crop((w // 2, 0, w, h))
    plain = Image.new("RGBA", (right.size[0] * 2, h), (0, 0, 0, 0))
    plain.paste(right.transpose(Image.FLIP_LEFT_RIGHT), (0, 0))
    plain.paste(right, (right.size[0], 0))
    save("Field", plain, l=26, r=26, pad=4)
    # 3D 모습 액자: 위·아래 가장자리 가운데의 장식은 늘어나지 않도록 따로 떼어 내고,
    # 액자 자체는 그 자리를 무늬 없는 금테로 채워 늘려도 자연스럽게 한다
    slot = cut("K", (507, 584, 627, 702))
    save("Slot", plain_edge_middles(slot, l=40, r=40, band=22, strip=(42, 50)), l=40, r=40, t=40, b=40, pad=4)
    sw, sh = slot.size
    save("SlotOrnTop", feather_sides(slot.crop((50, 0, 78, 24)), 4))
    save("SlotOrnBottom", feather_sides(slot.crop((50, sh - 24, 78, sh)), 4))
    save("Plate", cut("K", (323, 765, 555, 839)), l=40, r=40, pad=4)
    save("Badge", erase_text(cut("K", (802, 780, 880, 826), pad=3), 9), l=24, r=24, pad=3)
    # 스크롤바: 시트의 큰 스크롤바 하나에서 위·아래 버튼, 홈(위 끝 · 반복되는 가운데 · 아래 끝), 손잡이를 모두 딴다
    # (홈은 손잡이가 없는 깨끗한 부분만 쓰고, 가운데는 위아래로 뒤집어 붙여 이음매 없이 반복시킨다)
    save("ScrollUp", cut("K", (1247, 217, 1307, 270), pad=2), pad=2)
    save("ScrollDown", cut("K", (1247, 654, 1307, 707), pad=2), pad=2)
    K = SHEET["K"]
    tx0, tx1 = 1248, 1306
    save("ScrollTrackTop", K.crop((tx0, 268, tx1, 292)).convert("RGBA"))
    save("ScrollTrackBottom", K.crop((tx0, 628, tx1, 654)).convert("RGBA"))
    mid = K.crop((tx0, 470, tx1, 628)).convert("RGBA")
    tile = Image.new("RGBA", (mid.size[0], mid.size[1] * 2))
    tile.paste(mid, (0, 0))
    tile.paste(mid.transpose(Image.FLIP_TOP_BOTTOM), (0, mid.size[1]))
    save("ScrollTrackMid", tile, tileH=tile.size[1])
    save("ScrollThumb", cut("K", (1262, 338, 1292, 460), pad=3, thr=95, close=3), pad=3)

    # --- 인장·막대·아이콘 (시트 R)
    # 장 제목 카드의 두루마리 (한 장으로 이어 붙여 살짝 돌린 그림만 쓴다)
    scroll_card(cut("R", (1052, 441, 1293, 528)))
    save("SealAch", cut("R", (1329, 431, 1429, 560)), pad=4)
    save("SealDex", cut("R", (1329, 677, 1433, 785)), pad=4)
    save("Seal", cut("R", (1330, 566, 1431, 665)), pad=4)
    save("BarFill", cut("R", (436, 579, 774, 624)), l=18, r=18, pad=4)
    save("BarTrack", cut("R", (437, 680, 773, 719)), l=18, r=18, pad=4)
    save("IconFrame", cut("R", (915, 580, 1009, 668), fill=False, close=1), pad=4)
    save("IconJournal", cut("R", (964, 936, 1053, 1026)), pad=4)
    save("IconBestiary", cut("R", (1248, 936, 1337, 1027)), pad=4)
    save("IconAchievements", cut("R", (869, 936, 958, 1026)), pad=4)
    save("IconStats", cut("R", (1154, 936, 1242, 1026)), pad=4)
    save("Banner", cut("R", (869, 450, 943, 552)), pad=4)

    # --- 사용자가 따로 준 그림: 명판 글자, 미니맵 아이콘 (art/logo.png 는 소개 페이지용 원본)
    if (ART / "title.png").exists():
        # 명판 글자는 창틀·장식의 금박과 같은 색으로 맞춘다
        refs = [Image.open(MEDIA / "UI" / f"{n}.tga") for n in ("FrameTL", "OrnamentTop", "OrnamentBottom", "Plaque")]
        save("Title", match_gold(from_white(ART / "title.png", 460), refs))   # 명판 위에 높이 27px로 보인다
    if (ART / "minimap.png").exists():
        icon = from_white(ART / "minimap.png", 128, square=True)
        icon.save(MEDIA / "Icon.tga")                             # 미니맵 버튼, 애드온 목록 아이콘
        preview.append(("Icon", icon))

    # --- Atlas.lua
    lines = ["-- BIG CHRONICLE :: 에셋 조각 정보 (tools/slice_assets.py 가 만든 파일 — 직접 고치지 마세요)",
             "-- w, h: 원본 크기(픽셀) / l, r, t, b: 늘리지 않는 가장자리 / pad: 조각 둘레의 투명 여백 / tile: 반복 무늬 한 칸",
             "", "local ADDON, ns = ...", "ns.UI = ns.UI or {}", "ns.UI.ATLAS = {"]
    for name in sorted(atlas):
        e = atlas[name]
        body = ", ".join(f"{k} = {e[k]}" for k in ("w", "h", "l", "r", "t", "b", "pad", "tile", "tileH", "corner", "top", "bottom", "side", "band", "face") if k in e)
        lines.append(f"\t{name} = {{ {body} }},")
    lines.append("}")
    UIOUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {len(preview)} textures and {UIOUT.relative_to(ROOT)}")

    if len(sys.argv) > 1:
        # 확인용: 밝은 바탕과 짙은 바탕 위에 조각을 늘어놓는다
        cols, cell = 7, 210
        rows = math.ceil(len(preview) / cols)
        sheet = Image.new("RGBA", (cols * cell, rows * cell), (40, 70, 110, 255))
        from PIL import ImageDraw
        d = ImageDraw.Draw(sheet)
        for i, (name, im) in enumerate(preview):
            x, y = (i % cols) * cell, (i // cols) * cell
            if (i // cols + i % cols) % 2:
                d.rectangle((x, y, x + cell, y + cell), fill=(150, 150, 150, 255))
            s = min(1.0, (cell - 20) / im.size[0], (cell - 34) / im.size[1])
            t = im.resize((max(1, int(im.size[0] * s)), max(1, int(im.size[1] * s))), Image.LANCZOS)
            sheet.alpha_composite(t, (x + (cell - t.size[0]) // 2, y + 22 + (cell - 34 - t.size[1]) // 2))
            d.text((x + 4, y + 4), f"{name} {im.size[0]}x{im.size[1]}", fill=(255, 255, 255, 255))
        sheet.convert("RGB").save(sys.argv[1])


if __name__ == "__main__":
    main()
