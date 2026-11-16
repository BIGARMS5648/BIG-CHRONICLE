"""BIG CHRONICLE :: 효과 에셋 만들기 (입자 그림, 효과음)

화면 그림(창틀, 탭, 버튼, 양피지, 밀랍 인장, 아이콘)은 art/ 의 에셋 시트에서
tools/slice_assets.py 가 잘라 낸다. 이 스크립트는 효과용 파일만 만든다.

  - 입자: Kenney "Particle Pack" (CC0)  https://kenney.nl/assets/particle-pack
  - 효과음: Kenney "RPG Audio" (CC0)    https://kenney.nl/assets/rpg-audio

캐시 폴더의 kenney/ 아래에 p_star_06.png, p_light_01.png, p_dirt_02.png,
p_magic_05.png 와 bookOpen.ogg 등 효과음 파일을 받아 두고 실행한다.

사용법 (Python + Pillow):
    python3 tools/build_assets.py <캐시_폴더>
"""
import pathlib
import shutil
import sys

from PIL import Image, ImageChops

ROOT = pathlib.Path(__file__).resolve().parent.parent
MEDIA = ROOT / "BigChronicle" / "Media"
CACHE = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/bigchronicle-assets").resolve()

PARTICLES = (("star_06", "Star"), ("light_01", "Glow"), ("dirt_02", "Crumb"), ("magic_05", "Magic"))
SOUNDS = ("bookOpen", "bookClose", "bookPlace1")


def save_tga(img, rel):
    w, h = img.size
    assert w & (w - 1) == 0 and h & (h - 1) == 0, f"{rel}: {w}x{h} is not a power of two"
    out = MEDIA / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGBA").save(out)
    print("wrote", out.relative_to(ROOT), img.size)


def main():
    K = CACHE / "kenney"
    for src, dst in PARTICLES:
        g = Image.open(K / f"p_{src}.png").convert("RGBA")
        lum = g.convert("L")
        a = ImageChops.multiply(lum, g.getchannel("A"))   # 검은 바탕이든 투명 바탕이든 밝기를 알파로
        out = Image.new("RGBA", g.size, (255, 255, 255, 0))
        out.putalpha(a)
        save_tga(out.resize((64, 64), Image.LANCZOS), f"FX/{dst}.tga")
    (MEDIA / "Sounds").mkdir(parents=True, exist_ok=True)
    for n in SOUNDS:
        shutil.copy(K / f"{n}.ogg", MEDIA / "Sounds" / f"{n}.ogg")
    print("done")


if __name__ == "__main__":
    main()
