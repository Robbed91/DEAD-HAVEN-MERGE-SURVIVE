from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "art" / "hollow_creek"
CONCEPT = ROOT / "assets" / "concepts" / "vertical_slice"


def ensure_dirs() -> None:
    for path in [
        ART / "environments" / "runtime",
        ART / "environments" / "layers",
        ART / "characters",
        ART / "enemies",
        ART / "animation" / "window_boarding",
        ROOT / "assets" / "items" / "construction",
        ROOT / "assets" / "ui" / "hollow_creek",
        ROOT / "assets" / "audio" / "music",
        ROOT / "assets" / "audio" / "ambience",
        ROOT / "assets" / "audio" / "sfx",
    ]:
        path.mkdir(parents=True, exist_ok=True)


def fit_runtime(image: Image.Image) -> Image.Image:
    return ImageOps.fit(image.convert("RGB"), (720, 1116), method=Image.Resampling.LANCZOS, centering=(0.5, 0.48))


def save_environment_states() -> Image.Image:
    env_dir = ART / "environments"
    final = None
    for source in sorted(env_dir.glob("hollow_creek_state_*.png")):
        runtime = fit_runtime(Image.open(source))
        runtime = ImageEnhance.Sharpness(runtime).enhance(1.08)
        runtime.save(env_dir / "runtime" / source.name, optimize=True)
        if "state_05" in source.name:
            final = runtime
    if final is None:
        raise RuntimeError("Missing Hollow Creek state 05")
    return final


def feathered_mask(size: tuple[int, int], polygon: list[tuple[int, int]], blur: int = 8) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    return mask.filter(ImageFilter.GaussianBlur(blur)) if blur else mask


def save_layer(base: Image.Image, name: str, polygon: list[tuple[int, int]], blur: int = 8) -> None:
    layer = base.convert("RGBA")
    layer.putalpha(feathered_mask(base.size, polygon, blur))
    layer.save(ART / "environments" / "layers" / f"{name}.png", optimize=True)


def save_environment_layers(base: Image.Image) -> None:
    w, h = base.size
    layers = {
        "sky": ([(0, 0), (w, 0), (w, 410), (0, 455)], 18),
        "distant_landscape": ([(0, 300), (430, 270), (480, 610), (0, 660)], 12),
        "trees": ([(0, 260), (w, 300), (w, 520), (0, 560)], 14),
        "barn": ([(0, 330), (245, 300), (270, 670), (0, 690)], 8),
        "main_farmhouse": ([(105, 210), (690, 190), (720, 820), (120, 900)], 8),
        "roof": ([(115, 205), (700, 190), (720, 540), (90, 540)], 6),
        "windows": ([(180, 390), (720, 350), (720, 700), (180, 720)], 5),
        "doors": ([(285, 495), (470, 495), (480, 820), (275, 820)], 5),
        "porch": ([(130, 500), (700, 485), (720, 870), (100, 905)], 6),
        "fence": ([(0, 610), (720, 560), (720, 980), (0, 1010)], 8),
        "garden": ([(0, 650), (720, 650), (720, h), (0, h)], 18),
        "ground": ([(0, 590), (720, 590), (720, h), (0, h)], 10),
        "debris": ([(390, 665), (720, 665), (720, 1040), (350, 1040)], 8),
        "repair_overlays": ([(0, 330), (720, 280), (720, 1010), (0, 1050)], 10),
        "foreground_vegetation": ([(0, 820), (720, 780), (720, h), (0, h)], 20),
    }
    for name, (poly, blur) in layers.items():
        save_layer(base, name, poly, blur)

    transparent = Image.new("RGBA", base.size, (0, 0, 0, 0))
    transparent.save(ART / "environments" / "layers" / "characters.png")
    transparent.save(ART / "environments" / "layers" / "hollow.png")
    transparent.save(ART / "environments" / "layers" / "weather.png")
    transparent.save(ART / "environments" / "layers" / "particles.png")

    lighting = Image.new("RGBA", base.size, (0, 0, 0, 0))
    pixels = lighting.load()
    lights = [(365, 600, 120, (226, 162, 74)), (500, 610, 105, (226, 162, 74)), (590, 440, 70, (226, 162, 74))]
    for cx, cy, radius, color in lights:
        for y in range(max(0, cy - radius), min(h, cy + radius)):
            for x in range(max(0, cx - radius), min(w, cx + radius)):
                d = math.hypot(x - cx, y - cy) / radius
                if d < 1.0:
                    a = int(90 * (1.0 - d) ** 2)
                    old = pixels[x, y]
                    if a > old[3]:
                        pixels[x, y] = (*color, a)
    lighting = lighting.filter(ImageFilter.GaussianBlur(10))
    lighting.save(ART / "environments" / "layers" / "lighting.png", optimize=True)


def estimate_background(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    w, h = rgb.size
    samples = []
    for y in list(range(min(16, h))) + list(range(max(0, h - 16), h)):
        for x in range(0, w, max(1, w // 32)):
            samples.append(rgb.getpixel((x, y)))
    for x in list(range(min(16, w))) + list(range(max(0, w - 16), w)):
        for y in range(0, h, max(1, h // 32)):
            samples.append(rgb.getpixel((x, y)))
    samples.sort(key=lambda c: sum(c))
    mid = samples[len(samples) // 4 : len(samples) * 3 // 4]
    return tuple(sum(c[i] for c in mid) // max(1, len(mid)) for i in range(3))


def _keep_center_component(alpha: Image.Image) -> Image.Image:
    threshold = alpha.point(lambda value: 255 if value >= 72 else 0)
    w, h = threshold.size
    source = threshold.load()
    cx, cy = w // 2, h // 2
    candidates = []
    for radius in range(0, max(w, h), 6):
        for x, y in [(cx - radius, cy), (cx + radius, cy), (cx, cy - radius), (cx, cy + radius)]:
            if 0 <= x < w and 0 <= y < h and source[x, y]:
                candidates.append((x, y))
        if candidates:
            break
    if not candidates:
        return alpha
    stack = [candidates[0]]
    seen = {candidates[0]}
    while stack:
        x, y = stack.pop()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and source[nx, ny] and (nx, ny) not in seen:
                seen.add((nx, ny))
                stack.append((nx, ny))
    component = Image.new("L", (w, h), 0)
    cp = component.load()
    for x, y in seen:
        cp[x, y] = 255
    component = component.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(1.0))
    return ImageChops.multiply(alpha, component)


def remove_sheet_background(image: Image.Image, low: int = 28, high: int = 105) -> Image.Image:
    rgb = image.convert("RGB")
    bg = estimate_background(rgb)
    alpha = Image.new("L", rgb.size)
    ap = alpha.load()
    px = rgb.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            dist = math.sqrt((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2)
            saturation = max(r, g, b) - min(r, g, b)
            value = dist + saturation * 0.22
            ap[x, y] = int(max(0, min(255, (value - low) * 255 / max(1, high - low))))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.65))
    alpha = _keep_center_component(alpha)
    rgba = rgb.convert("RGBA")
    rgba.putalpha(alpha)
    bbox = alpha.getbbox()
    return rgba.crop(bbox) if bbox else rgba


def place_on_canvas(image: Image.Image, size: tuple[int, int], padding: int = 18) -> Image.Image:
    max_w, max_h = size[0] - padding * 2, size[1] - padding * 2
    scale = min(max_w / image.width, max_h / image.height)
    resized = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size[0] - resized.width) // 2, size[1] - padding - resized.height))
    return canvas


def save_character_assets() -> None:
    mara_sheet = Image.open(CONCEPT / "characters" / "mara_vale_character_sheet_concept.png")
    noah_sheet = Image.open(CONCEPT / "characters" / "noah_vance_character_sheet_concept.png")
    drifter_sheet = Image.open(CONCEPT / "enemies" / "drifter_concept_sheet.png")

    mara = remove_sheet_background(mara_sheet.crop((22, 18, 230, 520)), 25, 105)
    noah = remove_sheet_background(noah_sheet.crop((18, 15, 225, 510)), 25, 110)
    drifter = remove_sheet_background(drifter_sheet.crop((45, 18, 390, 690)), 24, 95)
    place_on_canvas(mara, (512, 1024), 24).save(ART / "characters" / "mara_vale_full.png", optimize=True)
    place_on_canvas(noah, (512, 1024), 24).save(ART / "characters" / "noah_vance_full.png", optimize=True)
    place_on_canvas(drifter, (512, 1024), 24).save(ART / "enemies" / "drifter_hollow_full.png", optimize=True)

    mara_portrait = ImageOps.fit(mara_sheet.crop((790, 455, 990, 655)).convert("RGB"), (512, 512), Image.Resampling.LANCZOS)
    noah_portrait = ImageOps.fit(noah_sheet.crop((590, 500, 770, 710)).convert("RGB"), (512, 512), Image.Resampling.LANCZOS)
    mara_portrait.save(ART / "characters" / "mara_vale_portrait.png", optimize=True)
    noah_portrait.save(ART / "characters" / "noah_vance_portrait.png", optimize=True)


def save_construction_items() -> None:
    sheet = Image.open(CONCEPT / "items" / "construction_chain_concept.png")
    out = ROOT / "assets" / "items" / "construction"
    segment = sheet.width / 8
    for index in range(8):
        x0 = max(0, round(index * segment - 10))
        x1 = min(sheet.width, round((index + 1) * segment + 10))
        cut = remove_sheet_background(sheet.crop((x0, 120, x1, 730)), 28, 112)
        place_on_canvas(cut, (256, 256), 14).save(out / f"level_{index + 1}.png", optimize=True)

    producer_sheet = Image.open(CONCEPT / "items" / "salvaged_tool_crate_states_concept.png")
    psegment = producer_sheet.width / 6
    names = ["producer", "producer_selected", "producer_active", "producer_cooldown", "producer_exhausted", "producer_reward"]
    for index, name in enumerate(names):
        x0 = max(0, round(index * psegment - 10))
        x1 = min(producer_sheet.width, round((index + 1) * psegment + 10))
        cut = remove_sheet_background(producer_sheet.crop((x0, 80, x1, 620)), 28, 112)
        place_on_canvas(cut, (256, 256), 12).save(out / f"{name}.png", optimize=True)


def save_boarding_frames() -> None:
    sheet = Image.open(CONCEPT / "animation" / "window_boarding_storyboard_concept.png").convert("RGB")
    cols, rows = 5, 2
    cell_w, cell_h = sheet.width // cols, sheet.height // rows
    out = ART / "animation" / "window_boarding"
    for row in range(rows):
        for col in range(cols):
            index = row * cols + col
            box = (col * cell_w + 3, row * cell_h + 3, (col + 1) * cell_w - 3, (row + 1) * cell_h - 3)
            frame = ImageOps.fit(sheet.crop(box), (512, 512), Image.Resampling.LANCZOS)
            frame.save(out / f"window_boarding_{index:02d}.jpg", quality=88, optimize=True)


def material_texture(size: tuple[int, int], base: tuple[int, int, int], border: tuple[int, int, int], seed: int) -> Image.Image:
    random.seed(seed)
    image = Image.new("RGBA", size, (*base, 255))
    draw = ImageDraw.Draw(image, "RGBA")
    for y in range(size[1]):
        shade = int(18 * (1 - y / max(1, size[1] - 1)))
        draw.line((0, y, size[0], y), fill=(min(255, base[0] + shade), min(255, base[1] + shade), min(255, base[2] + shade), 255))
    for _ in range(size[0] * size[1] // 14):
        x, y = random.randrange(size[0]), random.randrange(size[1])
        value = random.choice([-1, 1]) * random.randrange(3, 13)
        draw.point((x, y), fill=(max(0, min(255, base[0] + value)), max(0, min(255, base[1] + value)), max(0, min(255, base[2] + value)), random.randrange(25, 75)))
    draw.rounded_rectangle((2, 2, size[0] - 3, size[1] - 3), radius=12, outline=(*border, 255), width=3)
    draw.line((10, 7, size[0] - 10, 7), fill=(235, 220, 190, 80), width=2)
    for x, y in [(10, 10), (size[0] - 11, 10), (10, size[1] - 11), (size[0] - 11, size[1] - 11)]:
        draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(135, 140, 135, 210), outline=(35, 35, 32, 220))
    return image


def save_ui_textures() -> None:
    ui = ROOT / "assets" / "ui" / "hollow_creek"
    material_texture((128, 128), (30, 31, 30), (104, 112, 103), 11).save(ui / "panel_iron.png", optimize=True)
    material_texture((128, 128), (91, 67, 47), (166, 126, 78), 22).save(ui / "panel_wood.png", optimize=True)
    parchment = Image.new("RGBA", (128, 128), (214, 199, 166, 255))
    pd = ImageDraw.Draw(parchment, "RGBA")
    random.seed(33)
    for y in range(128):
        shade = round(8 * (1 - y / 127))
        pd.line((0, y, 127, y), fill=(214 + shade, 199 + shade, 166 + shade, 255))
    pd.rounded_rectangle((2, 2, 125, 125), radius=12, outline=(79, 58, 42, 255), width=4)
    pd.rounded_rectangle((7, 7, 120, 120), radius=9, outline=(166, 126, 78, 180), width=2)
    parchment.save(ui / "panel_parchment.png", optimize=True)
    material_texture((128, 64), (76, 91, 62), (150, 168, 117), 44).save(ui / "button_olive.png", optimize=True)
    material_texture((128, 64), (153, 65, 36), (220, 127, 71), 55).save(ui / "button_rust.png", optimize=True)
    material_texture((128, 64), (47, 48, 45), (103, 106, 99), 66).save(ui / "button_disabled.png", optimize=True)
    material_texture((128, 128), (70, 57, 43), (133, 111, 78), 77).save(ui / "board_cell.png", optimize=True)

    board = Image.new("RGB", (720, 1116), (63, 52, 40))
    draw = ImageDraw.Draw(board, "RGBA")
    random.seed(88)
    for y in range(0, 1116, 72):
        draw.rectangle((0, y, 720, y + 70), fill=(66 + (y // 72) % 2 * 5, 53, 39, 255))
        draw.line((0, y + 70, 720, y + 70), fill=(27, 24, 21, 210), width=3)
        for _ in range(12):
            x = random.randrange(720)
            length = random.randrange(24, 110)
            draw.line((x, y + random.randrange(12, 62), min(720, x + length), y + random.randrange(12, 62)), fill=(120, 87, 55, 55), width=1)
    vignette = Image.new("L", board.size, 0)
    vp = vignette.load()
    for y in range(board.height):
        for x in range(board.width):
            nx = abs(x / board.width - 0.5) * 2
            ny = abs(y / board.height - 0.5) * 2
            vp[x, y] = int(max(nx, ny) ** 2 * 115)
    dark = Image.new("RGB", board.size, (15, 14, 13))
    board = Image.composite(dark, board, vignette)
    board.save(ui / "merge_board_surface.jpg", quality=86, optimize=True)

    particle = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    pp = particle.load()
    for y in range(64):
        for x in range(64):
            d = math.hypot(x - 31.5, y - 31.5) / 31.5
            if d < 1:
                pp[x, y] = (240, 204, 140, int(255 * (1 - d) ** 2))
    particle.save(ui / "particle_soft.png", optimize=True)

    ring = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring, "RGBA")
    for width, color in [(14, (17, 19, 18, 125)), (7, (226, 162, 74, 235)), (2, (240, 230, 208, 230))]:
        rd.ellipse((12, 12, 116, 116), outline=color, width=width)
    for angle in range(0, 360, 45):
        a = math.radians(angle)
        x, y = 64 + math.cos(a) * 52, 64 + math.sin(a) * 52
        rd.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(126, 132, 126, 255), outline=(24, 24, 22, 255), width=1)
    ring.save(ui / "hotspot_ring.png", optimize=True)

    repaired = material_texture((128, 128), (78, 57, 39), (183, 143, 85), 91)
    repaired.putalpha(feathered_mask((128, 128), [(15, 24), (112, 16), (118, 105), (21, 114)], 2))
    repaired.save(ui / "hotspot_repaired.png", optimize=True)


def write_wav(path: Path, samples: list[tuple[float, float]], rate: int = 22050) -> None:
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        frames = bytearray()
        for left, right in samples:
            l = max(-32767, min(32767, int(left * 32767)))
            r = max(-32767, min(32767, int(right * 32767)))
            frames.extend(struct.pack("<hh", l, r))
        wav.writeframes(frames)


def fade_loop(samples: list[tuple[float, float]], count: int) -> None:
    for i in range(count):
        t = i / max(1, count - 1)
        a = samples[i]
        b = samples[-count + i]
        blend = (a[0] * (1 - t) + b[0] * t, a[1] * (1 - t) + b[1] * t)
        samples[i] = blend
        samples[-count + i] = blend


def save_music_and_ambience() -> None:
    rate = 22050
    seconds = 32
    rng = random.Random(1701)
    notes = [73.42, 87.31, 110.0, 146.83, 174.61, 220.0]
    music = []
    noise_l = noise_r = 0.0
    for i in range(rate * seconds):
        t = i / rate
        drone = 0.075 * math.sin(2 * math.pi * 36.71 * t) + 0.045 * math.sin(2 * math.pi * 55.0 * t)
        pulse = 0.018 * math.sin(2 * math.pi * 0.125 * t) * math.sin(2 * math.pi * 110.0 * t)
        pluck = 0.0
        beat = t % 4.0
        note = notes[int(t // 4) % len(notes)]
        if beat < 2.2:
            env = math.exp(-2.0 * beat)
            pluck = 0.12 * env * (math.sin(2 * math.pi * note * t) + 0.35 * math.sin(2 * math.pi * note * 2 * t))
        noise_l = noise_l * 0.997 + rng.uniform(-1, 1) * 0.003
        noise_r = noise_r * 0.997 + rng.uniform(-1, 1) * 0.003
        music.append((drone + pulse + pluck * 0.92 + noise_l * 0.025, drone + pulse + pluck * 0.78 + noise_r * 0.025))
    fade_loop(music, rate * 2)
    write_wav(ROOT / "assets" / "audio" / "music" / "hollow_creek_residence_loop.wav", music, rate)

    ambience = []
    wind_l = wind_r = rain_l = rain_r = 0.0
    rng = random.Random(405)
    for i in range(rate * 20):
        t = i / rate
        raw_l, raw_r = rng.uniform(-1, 1), rng.uniform(-1, 1)
        wind_l = wind_l * 0.9992 + raw_l * 0.0008
        wind_r = wind_r * 0.9992 + raw_r * 0.0008
        rain_l = rain_l * 0.78 + raw_l * 0.22
        rain_r = rain_r * 0.78 + raw_r * 0.22
        gust = 0.45 + 0.35 * math.sin(2 * math.pi * 0.07 * t) + 0.15 * math.sin(2 * math.pi * 0.19 * t)
        ambience.append((wind_l * gust * 0.28 + rain_l * 0.018, wind_r * gust * 0.28 + rain_r * 0.018))
    fade_loop(ambience, rate * 2)
    write_wav(ROOT / "assets" / "audio" / "ambience" / "hollow_creek_storm_loop.wav", ambience, rate)


def tone_sfx(path: Path, duration: float, voices: list[tuple[float, float]], noise: float = 0.0, seed: int = 1) -> None:
    rate = 22050
    rng = random.Random(seed)
    frames = []
    for i in range(int(rate * duration)):
        t = i / rate
        env = max(0.0, 1.0 - t / duration) ** 2
        sample = sum(amp * math.sin(2 * math.pi * freq * t) for freq, amp in voices)
        sample += rng.uniform(-noise, noise)
        sample *= env
        frames.append((sample * 0.92, sample))
    write_wav(path, frames, rate)


def save_sfx() -> None:
    out = ROOT / "assets" / "audio" / "sfx"
    tone_sfx(out / "ui_tap.wav", 0.09, [(440, 0.18), (660, 0.10)], 0.01, 2)
    tone_sfx(out / "merge_wood.wav", 0.34, [(120, 0.18), (185, 0.11), (720, 0.035)], 0.10, 3)
    tone_sfx(out / "merge_invalid.wav", 0.18, [(92, 0.18), (84, 0.15)], 0.025, 4)
    tone_sfx(out / "producer_tools.wav", 0.48, [(165, 0.12), (330, 0.09), (990, 0.035)], 0.07, 5)
    tone_sfx(out / "discovery.wav", 0.72, [(220, 0.08), (330, 0.08), (440, 0.07), (660, 0.05)], 0.01, 6)
    tone_sfx(out / "task_complete.wav", 0.78, [(196, 0.07), (293.66, 0.08), (392, 0.08), (587.33, 0.05)], 0.015, 7)
    tone_sfx(out / "window_hammer.wav", 0.24, [(94, 0.22), (188, 0.08), (810, 0.025)], 0.13, 8)
    tone_sfx(out / "wood_creak.wav", 0.62, [(72, 0.12), (83, 0.08)], 0.08, 9)
    tone_sfx(out / "radio_crackle.wav", 0.55, [(220, 0.025), (440, 0.018)], 0.15, 10)
    tone_sfx(out / "lantern_ignite.wav", 0.32, [(310, 0.05), (620, 0.04)], 0.10, 11)
    tone_sfx(out / "repair_whoosh.wav", 0.52, [(110, 0.05), (220, 0.04), (440, 0.03)], 0.08, 12)


def main() -> None:
    ensure_dirs()
    final = save_environment_states()
    save_environment_layers(final)
    save_character_assets()
    save_construction_items()
    save_boarding_frames()
    save_ui_textures()
    save_music_and_ambience()
    save_sfx()
    print("Hollow Creek vertical-slice assets built.")


if __name__ == "__main__":
    main()
