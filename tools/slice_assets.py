"""BIG CHRONICLE :: 에셋 시트 자르기

art/ 폴더의 에셋 시트 3장(사용자가 제공한 그림)에서 UI 조각을 잘라
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
    save("Slot", cut("K", (507, 584, 627, 702)), l=40, r=40, t=40, b=40, pad=4)
    save("Plate", cut("K", (323, 765, 555, 839)), l=40, r=40, pad=4)
    save("Badge", erase_text(cut("K", (802, 780, 880, 826), pad=3), 9), l=24, r=24, pad=3)
    save("ScrollUp", cut("K", (1338, 227, 1372, 262), pad=2), pad=2)
    save("ScrollDown", cut("K", (1338, 668, 1372, 705), pad=2), pad=2)
    save("ScrollTrack", SHEET["K"].crop((1340, 276, 1371, 420)).convert("RGBA"))
    save("ScrollThumb", cut("K", (1262, 338, 1292, 460), pad=3, thr=95, close=3), pad=3)

    # --- 인장·막대·아이콘 (시트 R)
    save("Scroll", cut("R", (1052, 441, 1293, 528)), l=76, r=100, pad=4)
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
    save("Buckle", cut("R", (926, 803, 1087, 897)), pad=4)

    # --- 책장 넘김에 쓰는 양피지 한 장 (가장자리 + 반복 무늬를 미리 합쳐 둔다)
    sheet_w, sheet_h = 980, 720
    pt = img
    page = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    for x in range(0, sheet_w, pt.size[0]):
        for y in range(0, sheet_h, pt.size[1]):
            page.paste(pt, (x, y))
    ea = np.asarray(cut("P", (29, 513, 385, 631)))
    eh, ew = ea.shape[:2]
    L, T = 38, 34
    full = np.asarray(page).copy()
    alpha = np.zeros((sheet_h, sheet_w), np.float32)
    alpha[10:-10, 10:-10] = 255
    full[..., 3] = alpha.astype(np.uint8)
    canvas = Image.fromarray(full, "RGBA")
    edge_img = feather_inner(Image.fromarray(ea, "RGBA"), L, L, T, T, 14)

    def blit(sx0, sy0, sx1, sy1, dx0, dy0, dx1, dy1):
        piece = edge_img.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS)
        canvas.alpha_composite(piece, (dx0, dy0))

    # 가운데 바탕은 가장자리 조각의 알파가 0인 바깥쪽에서 비치지 않도록 먼저 지운다
    cl = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    inner = canvas.crop((L - 14, T - 14, sheet_w - L + 14, sheet_h - T + 14))
    cl.paste(inner, (L - 14, T - 14))
    canvas = cl
    blit(0, 0, L, T, 0, 0, L, T); blit(ew - L, 0, ew, T, sheet_w - L, 0, sheet_w, T)
    blit(0, eh - T, L, eh, 0, sheet_h - T, L, sheet_h); blit(ew - L, eh - T, ew, eh, sheet_w - L, sheet_h - T, sheet_w, sheet_h)
    blit(L, 0, ew - L, T, L, 0, sheet_w - L, T); blit(L, eh - T, ew - L, eh, L, sheet_h - T, sheet_w - L, sheet_h)
    blit(0, T, L, eh - T, 0, T, L, sheet_h - T); blit(ew - L, T, ew, eh - T, sheet_w - L, T, sheet_w, sheet_h - T)
    save("PageSheet", canvas)

    # --- Atlas.lua
    lines = ["-- BIG CHRONICLE :: 에셋 조각 정보 (tools/slice_assets.py 가 만든 파일 — 직접 고치지 마세요)",
             "-- w, h: 원본 크기(픽셀) / l, r, t, b: 늘리지 않는 가장자리 / pad: 조각 둘레의 투명 여백 / tile: 반복 무늬 한 칸",
             "", "local ADDON, ns = ...", "ns.UI = ns.UI or {}", "ns.UI.ATLAS = {"]
    for name in sorted(atlas):
        e = atlas[name]
        body = ", ".join(f"{k} = {e[k]}" for k in ("w", "h", "l", "r", "t", "b", "pad", "tile", "tileH", "corner", "top", "bottom", "side") if k in e)
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
