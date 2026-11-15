"""Draw the BIG CHRONICLE icon as SVG and render it to PNG/TGA with Playwright + PIL."""
import sys, pathlib
from PIL import Image

out_dir = pathlib.Path(sys.argv[1])
out_dir.mkdir(parents=True, exist_ok=True)


def svg(banner: bool) -> str:
    # 배너가 없는 작은 아이콘은 두루마리를 조금 키워 가운데에 둔다
    t = "translate(256 250) scale(1.0) translate(-256 -235)" if banner else "translate(256 256) scale(1.18) translate(-256 -235)"
    claws = []
    for i, dx in enumerate((-36, 0, 36)):
        x1, y1 = 318 + dx, 150 + abs(dx) * 0.25
        x2, y2 = 222 + dx, 318 - abs(dx) * 0.25
        claws.append(
            f'<path d="M{x1},{y1} Q{x1 - 54},{(y1 + y2) / 2} {x2},{y2} Q{x1 - 18},{(y1 + y2) / 2} {x1},{y1} Z" '
            f'fill="url(#claw)" opacity="0.92"/>'
        )
    lines = []
    for i, w in enumerate((104, 86, 112, 70, 96)):
        y = 166 + i * 30
        lines.append(f'<line x1="166" y1="{y}" x2="{166 + w}" y2="{y}" stroke="#8a6a45" stroke-width="6" stroke-linecap="round" opacity="0.55"/>')

    def roller(cy):
        return f'''
      <g>
        <rect x="120" y="{cy - 17}" width="272" height="34" rx="17" fill="url(#wood)"/>
        <rect x="132" y="{cy - 10}" width="248" height="3" rx="1.5" fill="#f3c98a" opacity="0.35"/>
        <ellipse cx="114" cy="{cy}" rx="15" ry="24" fill="url(#knob)" stroke="#c9a24a" stroke-width="3"/>
        <ellipse cx="398" cy="{cy}" rx="15" ry="24" fill="url(#knob)" stroke="#c9a24a" stroke-width="3"/>
        <circle cx="96" cy="{cy}" r="7" fill="#c9a24a"/>
        <circle cx="416" cy="{cy}" r="7" fill="#c9a24a"/>
      </g>'''

    banner_svg = ""
    if banner:
        banner_svg = '''
    <g>
      <path d="M58,398 L104,398 L104,450 L58,450 L76,424 Z" fill="#5e110d"/>
      <path d="M454,398 L408,398 L408,450 L454,450 L436,424 Z" fill="#5e110d"/>
      <path d="M92,392 L420,392 L420,446 L92,446 Z" fill="url(#ribbon)" stroke="#c9a24a" stroke-width="3"/>
      <path d="M92,446 L104,456 L104,446 Z M420,446 L408,456 L408,446 Z" fill="#3e0906"/>
      <text x="256" y="430" text-anchor="middle" font-family="Caladea, 'DejaVu Serif', serif" font-weight="700"
            font-size="36" letter-spacing="3" fill="#f6dc94" stroke="#3e0906" stroke-width="1">BIG CHRONICLE</text>
    </g>'''

    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <radialGradient id="bg" cx="50%" cy="44%" r="70%">
      <stop offset="0" stop-color="#5a3519"/>
      <stop offset="0.65" stop-color="#2b170a"/>
      <stop offset="1" stop-color="#140a04"/>
    </radialGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0" stop-color="#ffd88a" stop-opacity="0.35"/>
      <stop offset="1" stop-color="#ffd88a" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fbf2da"/>
      <stop offset="1" stop-color="#e2c992"/>
    </linearGradient>
    <linearGradient id="paperEdge" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#7a4f24" stop-opacity="0.35"/>
      <stop offset="0.12" stop-color="#7a4f24" stop-opacity="0"/>
      <stop offset="0.88" stop-color="#7a4f24" stop-opacity="0"/>
      <stop offset="1" stop-color="#7a4f24" stop-opacity="0.35"/>
    </linearGradient>
    <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#a8703a"/>
      <stop offset="0.45" stop-color="#6b3c18"/>
      <stop offset="1" stop-color="#2e1708"/>
    </linearGradient>
    <radialGradient id="knob" cx="40%" cy="35%" r="70%">
      <stop offset="0" stop-color="#6a3a16"/>
      <stop offset="1" stop-color="#1f0e04"/>
    </radialGradient>
    <linearGradient id="claw" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#b3261e"/>
      <stop offset="1" stop-color="#5e110d"/>
    </linearGradient>
    <radialGradient id="seal" cx="40%" cy="35%" r="70%">
      <stop offset="0" stop-color="#c8372b"/>
      <stop offset="1" stop-color="#6a100b"/>
    </radialGradient>
    <linearGradient id="ribbon" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#9c2219"/>
      <stop offset="1" stop-color="#5e110d"/>
    </linearGradient>
  </defs>

  <rect x="8" y="8" width="496" height="496" rx="88" fill="url(#bg)"/>
  <rect x="24" y="24" width="464" height="464" rx="74" fill="none" stroke="#c9a24a" stroke-width="6"/>
  <rect x="34" y="34" width="444" height="444" rx="66" fill="none" stroke="#c9a24a" stroke-width="1.5" opacity="0.45"/>
  <circle cx="256" cy="236" r="210" fill="url(#glow)"/>

  <g transform="{t}">
    <path d="M136,118 C170,126 342,126 376,118 L376,354 C342,362 170,362 136,354 Z" fill="url(#paper)" stroke="#8a5a2b" stroke-width="2.5"/>
    <path d="M136,118 C170,126 342,126 376,118 L376,354 C342,362 170,362 136,354 Z" fill="url(#paperEdge)"/>
    {''.join(lines)}
    {''.join(claws)}
    {roller(114)}
    {roller(358)}
    <g transform="translate(350 318)">
      <circle r="38" fill="url(#seal)"/>
      <circle r="38" fill="none" stroke="#4a0805" stroke-width="3" opacity="0.6"/>
      <circle r="27" fill="none" stroke="#f0a090" stroke-width="2" opacity="0.55"/>
      <text y="10" text-anchor="middle" font-family="Caladea, 'DejaVu Serif', serif" font-weight="700" font-size="30"
            fill="#f7c6b6" opacity="0.92">BC</text>
    </g>
  </g>
  {banner_svg}
</svg>'''


import subprocess, json
for name, banner in (("icon-banner", True), ("icon-plain", False)):
    (out_dir / f"{name}.svg").write_text(svg(banner), encoding="utf-8")
subprocess.run(["node", str(pathlib.Path(__file__).with_name("render.js")), str(out_dir)], check=True)

big = Image.open(out_dir / "icon-banner@1024.png").convert("RGBA")
big.resize((512, 512), Image.LANCZOS).save(out_dir / "BigChronicle-icon-512.png")
big.resize((400, 400), Image.LANCZOS).save(out_dir / "BigChronicle-icon-400.png")
plain = Image.open(out_dir / "icon-plain@1024.png").convert("RGBA")
plain.resize((512, 512), Image.LANCZOS).save(out_dir / "BigChronicle-icon-plain-512.png")
small = plain.resize((64, 64), Image.LANCZOS)
small.save(out_dir / "Icon-64.png")
small.save(out_dir / "Icon.tga")  # 게임 내 애드온 목록용 (32비트 TGA, 2의 거듭제곱 크기)
# 작은 크기에서 어떻게 보이는지 확인용 미리보기
preview = Image.new("RGBA", (512 + 16 + 128 + 16 + 64 + 16 + 32, 512), (40, 40, 40, 255))
preview.paste(big.resize((512, 512), Image.LANCZOS), (0, 0))
preview.paste(plain.resize((128, 128), Image.LANCZOS), (528, 0))
preview.paste(small, (672, 0))
preview.paste(plain.resize((32, 32), Image.LANCZOS), (752, 0))
preview.save(out_dir / "preview.png")
print("done")
