"""Build deterministic supporting art and audio for the construction merge slice.

The hero board illustration and construction items are authored raster art.  This
script creates the small state overlays, particles, storage materials and short
sound cues that need exact dimensions and repeatable alpha edges.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / "assets" / "ui" / "merge_board"
SFX = ROOT / "assets" / "audio" / "sfx"
ITEMS = ROOT / "assets" / "items" / "construction"


def material_cell(path: Path, border: tuple[int, int, int], glow: tuple[int, int, int] | None = None) -> None:
    rng = random.Random(path.name)
    image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rounded_rectangle((4, 4, 123, 123), radius=13, fill=(73, 58, 43, 228), outline=(18, 19, 18, 255), width=6)
    draw.rounded_rectangle((9, 9, 118, 118), radius=9, outline=(*border, 230), width=3)
    for y in range(18, 116, 17):
        draw.line((13, y, 114, y + rng.randint(-2, 2)), fill=(137, 105, 68, 48), width=1)
    for _ in range(34):
        x, y = rng.randint(14, 113), rng.randint(14, 113)
        draw.ellipse((x, y, x + 1, y + 1), fill=(24, 22, 19, rng.randint(35, 80)))
    if glow:
        halo = Image.new("RGBA", image.size, (0, 0, 0, 0))
        hd = ImageDraw.Draw(halo, "RGBA")
        hd.rounded_rectangle((7, 7, 120, 120), radius=11, outline=(*glow, 235), width=8)
        halo = halo.filter(ImageFilter.GaussianBlur(5))
        image.alpha_composite(halo)
        draw.rounded_rectangle((8, 8, 119, 119), radius=10, outline=(*glow, 255), width=3)
    image.save(path, optimize=True)


def save_overlay_assets() -> None:
    UI.mkdir(parents=True, exist_ok=True)
    material_cell(UI / "cell_normal.png", (132, 112, 82))
    material_cell(UI / "cell_valid.png", (153, 172, 112), (188, 211, 118))
    material_cell(UI / "cell_invalid.png", (151, 82, 62), (194, 75, 51))
    material_cell(UI / "cell_locked.png", (75, 78, 76))
    material_cell(UI / "storage_slot.png", (151, 119, 76))

    selection = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    sd = ImageDraw.Draw(selection, "RGBA")
    for width, color in ((12, (240, 171, 69, 58)), (5, (232, 177, 80, 235)), (2, (255, 237, 185, 255))):
        sd.rounded_rectangle((7, 7, 120, 120), radius=15, outline=color, width=width)
    for x, y in ((11, 11), (116, 11), (11, 116), (116, 116)):
        sd.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 211, 112, 245))
    selection.save(UI / "selection_frame.png", optimize=True)

    lock = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lock, "RGBA")
    ld.rounded_rectangle((23, 41, 73, 82), radius=7, fill=(45, 43, 38, 248), outline=(192, 166, 111, 255), width=4)
    ld.arc((30, 12, 66, 58), 180, 360, fill=(202, 178, 126, 255), width=8)
    ld.ellipse((43, 54, 53, 64), fill=(226, 191, 97, 255))
    ld.polygon(((46, 62), (51, 62), (55, 73), (42, 73)), fill=(226, 191, 97, 255))
    lock.save(UI / "lock_plate.png", optimize=True)

    web = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    wd = ImageDraw.Draw(web, "RGBA")
    center = (3, 3)
    silk = (225, 226, 216, 190)
    for angle in range(0, 91, 15):
        a = math.radians(angle)
        wd.line((center[0], center[1], 5 + math.cos(a) * 118, 5 + math.sin(a) * 118), fill=silk, width=2)
    for radius in (25, 48, 74, 104):
        wd.arc((3 - radius, 3 - radius, 3 + radius, 3 + radius), 0, 90, fill=silk, width=2)
    web = web.filter(ImageFilter.GaussianBlur(0.35))
    web.save(UI / "cobweb.png", optimize=True)

    glow = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    gp = glow.load()
    for y in range(128):
        for x in range(128):
            d = math.hypot(x - 63.5, y - 63.5) / 63.5
            if d < 1:
                gp[x, y] = (245, 178, 72, int(210 * (1 - d) ** 2.25))
    glow.save(UI / "reward_glow.png", optimize=True)

    chip = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chip, "RGBA")
    cd.polygon(((4, 15), (25, 7), (28, 15), (9, 25)), fill=(161, 108, 55, 255), outline=(67, 45, 29, 255))
    cd.line((8, 17, 24, 11), fill=(222, 169, 96, 190), width=2)
    chip.save(UI / "wood_chip.png", optimize=True)

    dust = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dp = dust.load()
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5) / 31.5
            if d < 1:
                dp[x, y] = (205, 175, 128, int(120 * (1 - d) ** 2.4))
    dust.save(UI / "dust_soft.png", optimize=True)


def save_producer_variants() -> None:
    """Derive readable, genuinely distinct charge states from approved art."""
    cooldown = Image.open(ITEMS / "producer_cooldown.png").convert("RGBA")
    exhausted = Image.open(ITEMS / "producer_exhausted.png").convert("RGBA")
    reward = Image.open(ITEMS / "producer_reward.png").convert("RGBA")

    low = ImageEnhance.Brightness(cooldown).enhance(0.78)
    low_draw = ImageDraw.Draw(low, "RGBA")
    # Three depleted charge studs integrated into the lower iron rail.
    for index, fill in enumerate(((190, 74, 43, 245), (89, 64, 47, 245), (63, 55, 48, 245))):
        x = 91 + index * 18
        low_draw.ellipse((x, 211, x + 10, 221), fill=fill, outline=(33, 29, 25, 255), width=2)
    low.save(ITEMS / "producer_low_charge.png", optimize=True)

    exhausted.save(ITEMS / "producer_empty.png", optimize=True)

    recharge = cooldown.copy()
    aura = Image.new("RGBA", recharge.size, (0, 0, 0, 0))
    aura_draw = ImageDraw.Draw(aura, "RGBA")
    aura_draw.arc((42, 26, 220, 205), 195, 344, fill=(237, 175, 74, 235), width=7)
    for x, y, radius in ((64, 84, 3), (193, 65, 4), (211, 119, 3), (49, 135, 2)):
        aura_draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 214, 111, 235))
    soft = aura.filter(ImageFilter.GaussianBlur(6))
    recharge.alpha_composite(soft)
    recharge.alpha_composite(aura)
    recharge.save(ITEMS / "producer_recharge.png", optimize=True)

    upgraded = reward.copy()
    upgraded.save(ITEMS / "producer_upgraded.png", optimize=True)


def write_wav(path: Path, samples: list[tuple[float, float]], rate: int = 22050) -> None:
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        frames = bytearray()
        for left, right in samples:
            frames.extend(struct.pack("<hh", int(max(-1, min(1, left)) * 32767), int(max(-1, min(1, right)) * 32767)))
        wav.writeframes(frames)


def cue(name: str, duration: float, voices: list[tuple[float, float]], noise: float, seed: int, rise: bool = False) -> None:
    rate = 22050
    rng = random.Random(seed)
    samples = []
    state = 0.0
    for i in range(int(rate * duration)):
        t = i / rate
        phase = t / duration
        envelope = (math.sin(math.pi * phase) ** 0.7 if rise else (1 - phase) ** 1.8)
        state = state * 0.68 + rng.uniform(-1, 1) * 0.32
        value = sum(amp * math.sin(2 * math.pi * freq * t) for freq, amp in voices)
        value = (value + state * noise) * envelope
        samples.append((value * 0.94, value))
    write_wav(SFX / name, samples, rate)


def save_sfx() -> None:
    SFX.mkdir(parents=True, exist_ok=True)
    cue("merge_pull_wood.wav", 0.20, [(92, 0.10), (184, 0.08)], 0.08, 21, True)
    cue("merge_wood_high.wav", 0.72, [(98, 0.13), (196, 0.10), (392, 0.08), (784, 0.05)], 0.07, 22, True)
    cue("producer_empty.wav", 0.30, [(82, 0.16), (61, 0.12)], 0.035, 23)
    cue("producer_recharge.wav", 0.46, [(176, 0.07), (264, 0.06), (352, 0.04)], 0.02, 24, True)
    cue("item_lift.wav", 0.11, [(310, 0.09), (465, 0.05)], 0.012, 25)


def main() -> None:
    save_overlay_assets()
    save_producer_variants()
    save_sfx()
    print("Merge-board supporting assets built.")


if __name__ == "__main__":
    main()
