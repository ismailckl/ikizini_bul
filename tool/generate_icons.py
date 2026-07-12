from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BG = (15, 118, 110, 255)
DARK = (36, 59, 54, 255)
CARD = (255, 255, 255, 255)
GOLD = (245, 158, 11, 255)
TEAL_SOFT = (217, 244, 239, 255)


def font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def draw_icon(size: int, maskable: bool = False) -> Image.Image:
    scale = size / 1024
    image = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(image)

    def s(value: int) -> int:
        return max(1, round(value * scale))

    draw.rounded_rectangle(
        [s(64), s(64), size - s(64), size - s(64)],
        radius=s(210),
        fill=BG,
    )
    draw.ellipse([s(90), s(110), s(390), s(410)], fill=(20, 184, 166, 80))
    draw.ellipse([s(610), s(650), s(930), s(970)], fill=(245, 158, 11, 75))

    left = [s(230), s(250), s(560), s(760)]
    right = [s(465), s(250), s(795), s(760)]

    draw.rounded_rectangle(
        [left[0] - s(22), left[1] + s(26), left[2] - s(22), left[3] + s(26)],
        radius=s(62),
        fill=(0, 0, 0, 45),
    )
    draw.rounded_rectangle(
        [right[0] + s(22), right[1] + s(26), right[2] + s(22), right[3] + s(26)],
        radius=s(62),
        fill=(0, 0, 0, 45),
    )

    draw.rounded_rectangle(left, radius=s(62), fill=CARD)
    draw.rounded_rectangle(right, radius=s(62), fill=CARD)

    inner_left = [left[0] + s(42), left[1] + s(42), left[2] - s(42), left[3] - s(42)]
    inner_right = [
        right[0] + s(42),
        right[1] + s(42),
        right[2] - s(42),
        right[3] - s(42),
    ]
    draw.rounded_rectangle(inner_left, radius=s(44), outline=TEAL_SOFT, width=s(18))
    draw.rounded_rectangle(inner_right, radius=s(44), outline=TEAL_SOFT, width=s(18))

    star_font = font(s(170))
    for box in (inner_left, inner_right):
        text = "?"
        bbox = draw.textbbox((0, 0), text, font=star_font)
        x = (box[0] + box[2] - (bbox[2] - bbox[0])) / 2
        y = (box[1] + box[3] - (bbox[3] - bbox[1])) / 2 - s(12)
        draw.text((x, y), text, fill=DARK, font=star_font)

    badge = [s(368), s(678), s(656), s(892)]
    draw.rounded_rectangle(badge, radius=s(94), fill=GOLD)
    label_font = font(s(124))
    label = "IB"
    bbox = draw.textbbox((0, 0), label, font=label_font)
    draw.text(
        (
            (badge[0] + badge[2] - (bbox[2] - bbox[0])) / 2,
            (badge[1] + badge[3] - (bbox[3] - bbox[1])) / 2 - s(10),
        ),
        label,
        fill=(255, 255, 255, 255),
        font=label_font,
    )

    if maskable:
        safe = s(72)
        masked = Image.new("RGBA", (size, size), BG)
        masked.alpha_composite(image.resize((size - safe * 2, size - safe * 2)), (safe, safe))
        return masked

    return image


def save_png(path: Path, size: int, maskable: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    draw_icon(size, maskable=maskable).save(path)


def main() -> None:
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        save_png(ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png", size)

    web_icons = {
        "favicon.png": 32,
        "icons/Icon-192.png": 192,
        "icons/Icon-512.png": 512,
        "icons/Icon-maskable-192.png": 192,
        "icons/Icon-maskable-512.png": 512,
    }
    for name, size in web_icons.items():
        save_png(ROOT / "web" / name, size, maskable="maskable" in name)

    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in ios_sizes.items():
        save_png(ios_dir / name, size)

    ico_image = draw_icon(256)
    ico_image.save(
        ROOT / "windows" / "runner" / "resources" / "app_icon.ico",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
