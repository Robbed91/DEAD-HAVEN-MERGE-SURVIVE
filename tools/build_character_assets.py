"""Extract final runtime character art and separated rig layers from identity sheets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from build_hollow_creek_assets import _keep_center_component, place_on_canvas, remove_sheet_background


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "art" / "characters" / "source"
OUTPUT = ROOT / "assets" / "art" / "characters"
ENEMY_SOURCE = ROOT / "assets" / "art" / "enemies" / "source"
ENEMY_OUTPUT = ROOT / "assets" / "art" / "enemies" / "drifter_hollow"

EXPRESSIONS = ["neutral", "concerned", "angry", "afraid", "relieved", "injured", "exhausted", "determined"]

# All coordinates are on the 1536 x 1024 production sheets.  Portrait cells
# are explicitly mapped so expression names remain stable runtime keys.
LAYOUTS = {
    "mara_vale": {
        "poses": [(18, 18, 222, 520), (210, 18, 410, 520), (405, 18, 600, 520), (590, 18, 785, 520)],
        "outfits": [(20, 530, 250, 1020), (510, 530, 790, 1020)],
        "portraits": [(800, 530, 984, 695), (1168, 530, 1352, 695), (984, 695, 1168, 860), (1352, 695, 1535, 860), (984, 530, 1168, 695), (800, 860, 984, 1023), (984, 860, 1168, 1023), (1168, 860, 1352, 1023)],
    },
    "noah_vance": {
        "poses": [(15, 15, 210, 505), (200, 15, 395, 505), (390, 15, 585, 505), (580, 15, 775, 505)],
        "outfits": [(15, 515, 205, 1020), (390, 515, 590, 1020)],
        "portraits": [(590, 510, 748, 765), (1064, 510, 1222, 765), (590, 765, 748, 1023), (1380, 510, 1535, 765), (748, 510, 906, 765), (1064, 765, 1222, 1023), (906, 765, 1064, 1023), (1222, 765, 1380, 1023)],
    },
    "lena_ortiz": {
        "poses": [(15, 25, 210, 855), (195, 25, 390, 855), (380, 25, 585, 855), (570, 25, 790, 855)],
        "outfits": [(195, 25, 390, 855), (790, 320, 1110, 610)],
        "portraits": [(800, 600, 984, 800), (984, 600, 1168, 800), (1168, 600, 1352, 800), (1352, 600, 1535, 800), (800, 795, 984, 1023), (1168, 795, 1352, 1023), (984, 795, 1168, 1023), (1352, 795, 1535, 1023)],
    },
    "imogen_shaw": {
        "poses": [(15, 20, 215, 875), (205, 20, 410, 875), (400, 20, 610, 875), (600, 20, 810, 875)],
        "outfits": [(15, 20, 215, 875), (810, 20, 1040, 555)],
        "portraits": [(815, 565, 995, 780), (995, 565, 1175, 780), (1175, 565, 1355, 780), (1355, 565, 1535, 780), (815, 775, 995, 1023), (1175, 775, 1355, 1023), (995, 775, 1175, 1023), (1355, 775, 1535, 1023)],
    },
    "riley_chen": {
        "poses": [(15, 15, 225, 665), (215, 15, 435, 665), (425, 15, 650, 665), (640, 15, 875, 665)],
        "outfits": [(15, 665, 260, 1023), (520, 665, 790, 1023)],
        "portraits": [(885, 610, 1047, 814), (1047, 610, 1209, 814), (1209, 610, 1371, 814), (1371, 610, 1534, 814), (885, 814, 1047, 1023), (1209, 814, 1371, 1023), (1047, 814, 1209, 1023), (1371, 814, 1534, 1023)],
    },
    "caleb_rusk": {
        "poses": [(15, 15, 215, 575), (205, 15, 405, 575), (395, 15, 590, 575), (580, 15, 785, 575)],
        "outfits": [(15, 575, 215, 1023), (785, 15, 1020, 570)],
        "portraits": [(657, 582, 856, 783), (856, 582, 1056, 783), (1056, 582, 1275, 783), (1275, 582, 1534, 783), (657, 783, 856, 1022), (1056, 783, 1275, 1022), (856, 783, 1056, 1022), (1275, 783, 1534, 1022)],
    },
}


def extract(sheet: Image.Image, box: tuple[int, int, int, int], canvas: tuple[int, int], low: int = 24, high: int = 100) -> Image.Image:
    crop = sheet.crop(box)
    crop = crop.crop((8, 8, crop.width - 8, crop.height - 8))
    subject = remove_sheet_background(crop, low, high)
    pixels = subject.load()
    alpha = subject.getchannel("A")
    original_alpha = alpha.copy()
    ap = alpha.load()
    is_full_body = subject.height > subject.width * 1.4
    if is_full_body:
        for y in range(subject.height):
            for x in range(subject.width):
                r, g, b, _ = pixels[x, y]
                value = max(r, g, b)
                saturation = value - min(r, g, b)
                if value > 145 and saturation < 52:
                    ap[x, y] = 0
                elif value > 120 and saturation < 28:
                    ap[x, y] = min(ap[x, y], 24)
        # Preserve enclosed face and torso materials such as Mara's cream
        # shirt; these protected regions are occupied by the body in every
        # standardized full-body crop.
        op = original_alpha.load()
        for y in range(int(subject.height * 0.02), int(subject.height * 0.58)):
            for x in range(int(subject.width * 0.27), int(subject.width * 0.73)):
                ap[x, y] = max(ap[x, y], op[x, y])
    alpha = _keep_center_component(alpha)
    # Restore enclosed light areas (skin highlights, cream shirts, sclera)
    # while keeping exterior parchment and genuine limb gaps transparent.
    binary = alpha.point(lambda a: 255 if a > 28 else 0)
    bp = binary.load()
    exterior: set[tuple[int, int]] = set()
    stack: list[tuple[int, int]] = []
    for x in range(binary.width):
        if bp[x, 0] == 0:
            stack.append((x, 0))
        if bp[x, binary.height - 1] == 0:
            stack.append((x, binary.height - 1))
    for y in range(binary.height):
        if bp[0, y] == 0:
            stack.append((0, y))
        if bp[binary.width - 1, y] == 0:
            stack.append((binary.width - 1, y))
    while stack:
        x, y = stack.pop()
        if (x, y) in exterior or bp[x, y] != 0:
            continue
        exterior.add((x, y))
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < binary.width and 0 <= ny < binary.height:
                stack.append((nx, ny))
    for y in range(binary.height):
        for x in range(binary.width):
            if bp[x, y] == 0 and (x, y) not in exterior:
                ap[x, y] = 255
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.55))
    subject.putalpha(alpha)
    bbox = alpha.getbbox()
    subject = subject.crop(bbox) if bbox else subject
    return place_on_canvas(subject, canvas, 18)


def save_rig_layers(character_dir: Path, neutral: Image.Image) -> None:
    rig_dir = character_dir / "rig"
    rig_dir.mkdir(parents=True, exist_ok=True)
    w, h = neutral.size
    regions = {
        "head": (0.25, 0.00, 0.75, 0.25),
        "torso": (0.25, 0.20, 0.75, 0.60),
        "arm_left": (0.00, 0.18, 0.40, 0.62),
        "arm_right": (0.60, 0.18, 1.00, 0.62),
        "leg_left": (0.18, 0.52, 0.52, 0.93),
        "leg_right": (0.48, 0.52, 0.82, 0.93),
        "foot_left": (0.10, 0.87, 0.52, 1.00),
        "foot_right": (0.48, 0.87, 0.90, 1.00),
    }
    for name, region in regions.items():
        mask = Image.new("L", neutral.size, 0)
        x0, y0, x1, y1 = int(region[0] * w), int(region[1] * h), int(region[2] * w), int(region[3] * h)
        ImageDraw.Draw(mask).rectangle((x0, y0, x1, y1), fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(1.0))
        layer = neutral.copy()
        layer.putalpha(Image.composite(neutral.getchannel("A"), Image.new("L", neutral.size, 0), mask))
        layer.save(rig_dir / f"{name}.png", optimize=True)


def build_survivors() -> None:
    pose_names = ["neutral", "front_three_quarter", "reverse_three_quarter", "back"]
    for character_id, layout in LAYOUTS.items():
        sheet = Image.open(SOURCE / f"{character_id}_sheet.png").convert("RGB")
        char_dir = OUTPUT / character_id
        pose_dir = char_dir / "poses"
        portrait_dir = char_dir / "portraits"
        pose_dir.mkdir(parents=True, exist_ok=True)
        portrait_dir.mkdir(parents=True, exist_ok=True)
        for name, box in zip(pose_names, layout["poses"]):
            extract(sheet, box, (512, 1024)).save(pose_dir / f"{name}.png", optimize=True)
        extract(sheet, layout["outfits"][0], (512, 1024)).save(pose_dir / "residence.png", optimize=True)
        extract(sheet, layout["outfits"][1], (512, 1024)).save(pose_dir / "scavenging.png", optimize=True)
        for name, box in zip(EXPRESSIONS, layout["portraits"]):
            extract(sheet, box, (512, 512), 22, 94).save(portrait_dir / f"{name}.png", optimize=True)
        save_rig_layers(char_dir, Image.open(pose_dir / "neutral.png").convert("RGBA"))


def build_drifter() -> None:
    sheet = Image.open(ENEMY_SOURCE / "drifter_hollow_sheet.png").convert("RGB")
    ENEMY_OUTPUT.mkdir(parents=True, exist_ok=True)
    states = {
        "neutral": (20, 10, 280, 485),
        "front_three_quarter": (275, 10, 500, 485),
        "reverse_three_quarter": (500, 10, 735, 485),
        "back": (720, 10, 965, 485),
        "idle_sway": (15, 465, 150, 735),
        "slow_walk": (270, 465, 440, 735),
        "detect_target": (430, 465, 610, 735),
        "attack_barricade": (575, 455, 875, 735),
        "hit_reaction": (850, 455, 1035, 735),
        "trap_reaction": (1010, 455, 1210, 735),
        "collapse": (1190, 455, 1535, 735),
        "distant_wandering": (150, 465, 300, 735),
    }
    for name, box in states.items():
        extract(sheet, box, (512, 1024), 18, 80).save(ENEMY_OUTPUT / f"{name}.png", optimize=True)
    save_rig_layers(ENEMY_OUTPUT, Image.open(ENEMY_OUTPUT / "neutral.png").convert("RGBA"))


def main() -> None:
    build_survivors()
    build_drifter()
    print("Final survivor and Drifter runtime assets built.")


if __name__ == "__main__":
    main()
