"""Build the original Dead Haven audio library using deterministic synthesis.

No recordings, samples, model outputs, copyrighted music, or third-party sound
libraries are used. Every sample is generated from oscillators, envelopes and
seeded noise here, making provenance reproducible and auditable.
"""
from __future__ import annotations
import csv, json, math, random, struct, wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets" / "audio"
RATE = 22050
TAU = math.tau

def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(0.001, max(abs(v) for v in samples))
    gain = min(0.92 / peak, 1.0)
    pcm = b"".join(struct.pack("<h", int(max(-1, min(1, v * gain)) * 32767)) for v in samples)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE); out.writeframes(pcm)

def env(t: float, duration: float, attack: float = .01, release: float = .16) -> float:
    return min(1.0, t / max(attack, 1e-4)) * min(1.0, (duration - t) / max(release, 1e-4))

def synth_sfx(kind: str, duration: float, base: float, seed: int) -> list[float]:
    rng = random.Random(seed)
    phases = [rng.random() * TAU for _ in range(8)]
    out: list[float] = []
    filtered = 0.0
    hits = {"impact": [0.02, .17], "steps": [.03, .28], "construction": [.03, .25, .48, .71]}.get(kind, [0.02])
    for i in range(int(RATE * duration)):
        t = i / RATE
        noise = rng.random() * 2 - 1
        filtered = filtered * .91 + noise * .09
        sample = 0.0
        if kind in ("ui", "confirm", "reward", "electronic"):
            glide = base * (1.0 + .45 * t / duration) if kind in ("confirm", "reward") else base
            sample = .28 * math.sin(TAU * glide * t + phases[0]) + .11 * math.sin(TAU * glide * 1.5 * t + phases[1])
            sample *= env(t, duration, .008, duration * .45)
        elif kind in ("impact", "wood", "metal", "drop", "construction", "steps"):
            for hit in hits:
                local = t - hit
                if 0 <= local < .18:
                    decay = math.exp(-local * (22 if kind != "metal" else 12))
                    tonal = math.sin(TAU * base * local) * (.26 if kind != "metal" else .38)
                    sample += decay * (tonal + filtered * (.30 if kind in ("wood", "steps", "construction") else .18))
        elif kind in ("hollow", "engine", "threat"):
            wobble = 1.0 + .035 * math.sin(TAU * (3.0 + seed % 3) * t)
            sample = .23 * math.sin(TAU * base * wobble * t) + .12 * math.sin(TAU * base * .51 * t + phases[2]) + filtered * .09
            sample *= env(t, duration, .06, .22)
        elif kind in ("saw", "rain", "air", "fire", "radio"):
            carrier = filtered
            if kind == "saw": carrier += .17 * math.sin(TAU * base * t) * (1 if int(t * 18) % 2 else -1)
            if kind == "radio": carrier += .09 * math.sin(TAU * base * t) * math.sin(TAU * 7 * t)
            if kind == "fire": carrier *= .5 + .5 * math.sin(TAU * 8 * t) ** 2
            sample = carrier * env(t, duration, .04, .18) * .42
        else:
            sample = (.2 * math.sin(TAU * base * t) + filtered * .08) * env(t, duration)
        out.append(sample)
    return out

def loop_bed(duration: float, seed: int, tones: list[tuple[float, float]], texture: str) -> list[float]:
    rng = random.Random(seed)
    phase = [rng.random() * TAU for _ in range(18)]
    cycles = [rng.randint(1, max(2, int(duration * 3))) for _ in phase]
    out = []
    for i in range(int(RATE * duration)):
        t = i / RATE
        v = sum(amp * math.sin(TAU * freq * t + phase[n]) for n, (freq, amp) in enumerate(tones))
        # Periodic pseudo-noise: integer-cycle sines guarantee identical loop endpoints.
        noise = sum(math.sin(TAU * cycles[n] * t / duration + phase[n]) for n in range(6, 18)) / 12
        if texture == "rain": v += noise * .16 + math.sin(TAU * 13 * t / duration) ** 18 * .08
        elif texture == "wind": v += noise * (.11 + .05 * math.sin(TAU * t / duration))
        elif texture == "fire": v += noise * (.04 + .07 * math.sin(TAU * 9 * t / duration) ** 2)
        elif texture == "radio": v += noise * .045 + math.sin(TAU * 37 * t / duration) * .018
        elif texture == "danger": v += math.sin(TAU * 8 * t / duration) ** 14 * .16 + noise * .035
        out.append(v)
    # one-sample endpoint ramp avoids clicks in importers that repeat without interpolation
    fade = min(256, len(out) // 8)
    for i in range(fade):
        blend = i / fade
        mixed = out[-fade + i] * (1 - blend) + out[i] * blend
        out[-fade + i] = mixed
    return out

SFX = {
    # key: bus, kind, duration, frequency, variants, description, concurrency, pitch semitones
    "ui_button": ("UI","ui",.13,330,4,"Muted weathered-control press",3,1.5),
    "ui_navigation": ("UI","ui",.16,420,3,"Navigation tab change",2,1.0),
    "modal_open": ("UI","air",.28,240,3,"Panel cloth and metal reveal",2,.8),
    "modal_close": ("UI","air",.22,190,3,"Panel close and settle",2,.8),
    "confirmation": ("UI","confirm",.32,440,2,"Restrained confirmation chime",2,.5),
    "error": ("UI","impact",.28,105,3,"Blocked action knock",2,.8),
    "notification": ("UI","electronic",.38,620,2,"Radio-notification ping",2,.5),
    "reward": ("UI","reward",.62,390,3,"Warm reward shimmer",3,.6),
    "level_up": ("UI","reward",1.15,330,1,"Hopeful level-up rise",1,0),
    "quest_complete": ("UI","confirm",.78,360,2,"Repair task completion",2,.5),
    "item_discovery": ("UI","reward",.82,470,2,"New-item discovery flourish",2,.4),
    "item_pickup": ("SFX","air",.17,240,4,"Item lift from workbench",4,2.2),
    "item_drop": ("SFX","drop",.24,145,4,"Item contact on workbench",4,2.0),
    "merge_invalid": ("SFX","impact",.25,92,3,"Invalid merge block",2,1.2),
    "merge_generic": ("SFX","confirm",.42,260,4,"Generic merge compression and release",4,1.5),
    "merge_wood": ("SFX","wood",.45,145,4,"Wood merge clack",4,1.8),
    "merge_metal": ("SFX","metal",.52,410,4,"Metal merge fastening ring",4,1.5),
    "merge_medical": ("SFX","air",.42,310,3,"Medical fabric and kit merge",3,1.2),
    "merge_food": ("SFX","drop",.36,185,3,"Food container merge",3,1.4),
    "merge_electronics": ("SFX","electronic",.48,560,4,"Electronics merge pulse",4,1.5),
    "merge_fuel": ("SFX","metal",.48,220,3,"Fuel container merge",3,1.2),
    "merge_high": ("SFX","reward",.86,290,2,"Maximum-tier merge reward",2,.4),
    "producer_activate": ("SFX","construction",.75,185,4,"Producer latch and tool handling",3,1.8),
    "producer_empty": ("SFX","impact",.32,82,3,"Empty producer knock",2,1.2),
    "producer_recharge": ("SFX","electronic",.58,260,3,"Producer recharge tick",2,1.0),
    "coin_collect": ("UI","metal",.48,720,4,"Coin cluster collection",4,2.0),
    "energy_collect": ("UI","electronic",.52,520,3,"Energy charge collection",3,1.4),
    "chest_open": ("SFX","construction",.92,120,3,"Reward chest latch and lid",2,1.0),
    "hammer": ("Characters","construction",.88,165,8,"Hammer strike sequence",3,2.5),
    "saw": ("Characters","saw",1.35,170,3,"Hand-saw work phrase",1,1.2),
    "wood_place": ("Characters","wood",.55,125,6,"Board placement",3,2.0),
    "metal_fastening": ("Characters","metal",.66,460,5,"Metal fastening",3,1.7),
    "debris_clear": ("Characters","construction",1.05,95,5,"Debris clearing",2,2.0),
    "door_repair": ("Characters","wood",.86,115,4,"Door hinge and timber repair",2,1.5),
    "window_board": ("Characters","construction",1.0,155,6,"Window board hammering",2,2.0),
    "generator_start": ("Characters","engine",1.8,54,3,"Generator crank and catch",1,1.0),
    "trap_deploy": ("Characters","metal",.72,380,4,"Trap deployment snap",2,1.4),
    "fence_repair": ("Characters","metal",.88,270,4,"Fence wire and fastening",2,1.5),
    "footstep_dirt": ("Characters","steps",.42,92,8,"Boot step on dirt and mud",4,2.8),
    "footstep_interior": ("Characters","steps",.38,130,8,"Boot step on interior floor",4,2.4),
    "tool_handle": ("Characters","metal",.38,510,6,"Tool handling and buckle",4,2.0),
    "hollow_idle": ("Threats","hollow",1.15,58,5,"Drifter Hollow breath",2,2.2),
    "hollow_detect": ("Threats","hollow",.86,78,4,"Hollow target detection",2,1.8),
    "hollow_attack": ("Threats","threat",.72,66,5,"Hollow barricade attack",3,2.0),
    "hollow_hit": ("Threats","impact",.48,72,4,"Hollow hit reaction",3,2.2),
    "hollow_collapse": ("Threats","impact",1.0,54,4,"Hollow collapse",2,1.5),
    "vehicle_start": ("SFX","engine",2.2,48,4,"Old van crank and start",1,1.0),
    "vehicle_door": ("SFX","metal",.72,180,4,"Van door open or close",2,1.5),
    "vehicle_exhaust": ("SFX","engine",.62,46,3,"Van exhaust cough",2,1.4),
    "vehicle_headlights": ("SFX","electronic",.28,310,2,"Headlight relay",2,.8),
    "scavenge_launch": ("Characters","construction",1.15,125,3,"Gear-up and departure",2,1.2),
    "scavenge_search": ("Characters","construction",.84,105,5,"Container and backpack search",3,2.0),
    "scavenge_success": ("UI","confirm",.82,350,2,"Contained scavenging success",2,.5),
    "scavenge_failure": ("Threats","impact",.76,74,2,"Non-terminal scavenging setback",2,.5),
    "defence_warning": ("Threats","radio",1.25,135,2,"Threat warning radio horn",1,.5),
    "barricade_impact": ("Threats","construction",.72,82,8,"Barricade hit and strain",4,2.3),
    "defence_success": ("UI","confirm",1.15,300,1,"Defence secured cue",1,0),
    "defence_failure": ("Threats","impact",1.05,62,1,"Defence setback cue",1,0),
    "dialogue_advance": ("UI","radio",.18,310,3,"Dialogue radio/page advance",2,1.0),
    "dialogue_choice": ("UI","confirm",.28,380,2,"Dialogue choice confirmation",2,.6),
    "radio_pulse": ("Characters","radio",.62,280,4,"Radio tuning pulse",2,1.5),
}

MUSIC = {
    "main_menu": (18, [(55,.08),(82.5,.045),(110,.025)], "radio", "Restrained title motif with radio texture"),
    "safe_residence": (20, [(73.42,.065),(110,.045),(146.83,.025)], "fire", "Warm acoustic-like haven ostinato"),
    "merge_board": (16, [(65.41,.045),(98,.025),(196,.012)], "radio", "Low-fatigue workbench pulse"),
    "world_map": (18, [(61.74,.055),(92.5,.025),(123.47,.018)], "wind", "Exploration motif"),
    "scavenging": (16, [(55,.06),(82.5,.03),(165,.012)], "danger", "Cautious scavenging pulse"),
    "dialogue": (20, [(69.3,.045),(103.8,.026),(138.6,.014)], "radio", "Sparse dialogue underscore"),
    "tension": (14, [(46.25,.075),(69.3,.028),(92.5,.018)], "danger", "Low-string tension bed"),
    "defence_preparation": (16, [(48.99,.07),(73.42,.025),(146.83,.012)], "radio", "Defence preparation pulse"),
    "defence": (14, [(43.65,.08),(65.41,.03),(130.81,.014)], "danger", "Percussive defence loop"),
    "emotional": (20, [(65.41,.05),(98,.03),(130.81,.018)], "fire", "Restrained emotional theme"),
    "victory": (8, [(73.42,.065),(110,.04),(146.83,.026),(220,.014)], "fire", "Hopeful victory theme"),
    "residence_completion": (10, [(82.41,.06),(123.47,.038),(164.81,.022)], "fire", "Residence completion theme"),
}

AMBIENCE = {
    "wind": (10, [(32,.018),(47,.012)], "wind", "Rural wind"),
    "rain": (10, [(43,.01)], "rain", "Steady rain"),
    "thunder": (12, [(27.5,.035),(41.25,.018)], "danger", "Distant storm and thunder"),
    "distant_hollow": (12, [(38,.028),(57,.014)], "danger", "Distant Hollow activity"),
    "forest": (12, [(49,.012),(73,.007)], "wind", "Forest canopy and insects"),
    "abandoned_building": (10, [(41,.016),(82,.006)], "wind", "Empty building room tone"),
    "fire": (8, [(58,.009)], "fire", "Hearth fire"),
    "lantern": (8, [(91,.006)], "fire", "Lantern flame"),
    "generator": (8, [(55,.035),(110,.015)], "radio", "Generator idle"),
    "electrical_hum": (8, [(50,.024),(100,.01)], "radio", "Electrical system hum"),
    "road": (10, [(36,.012),(72,.006)], "wind", "Distant road ambience"),
    "vehicle_engine": (8, [(48,.04),(96,.018)], "radio", "Old van engine idle loop"),
    "hollow_creek_storm": (12, [(32,.018),(48,.012)], "rain", "Hollow Creek storm composite"),
    "redwater_station": (12, [(55,.02),(83,.008)], "wind", "Redwater forecourt composite"),
}

def main() -> None:
    catalog = {"sfx": {}, "music": {}, "ambience": {}}
    manifest = []
    for key, (bus, kind, dur, base, variants, desc, limit, pitch) in SFX.items():
        paths = []
        for variant in range(variants):
            rel = Path("assets/audio/sfx") / key / f"{key}_{variant+1:02d}.wav"
            write_wav(ROOT / rel, synth_sfx(kind, dur, base * (1 + (variant - variants/2) * .018), 1000 + len(manifest) * 17 + variant))
            paths.append("res://" + rel.as_posix())
            manifest.append([f"SFX_{key.upper()}_{variant+1:02d}","SFX",rel.as_posix(),key,bus,"Original deterministic procedural synthesis", "Project-owned original; no third-party material",f"variant {variant+1}/{variants}","one-shot"])
        catalog["sfx"][key] = {"paths": paths, "bus": bus, "limit": limit, "pitch_semitones": pitch}
    for key, (dur, tones, texture, desc) in MUSIC.items():
        rel = Path("assets/audio/music") / f"{key}_loop.wav"
        write_wav(ROOT / rel, loop_bed(dur, 3000 + len(manifest), tones, texture))
        catalog["music"][key] = "res://" + rel.as_posix()
        manifest.append([f"MUS_{key.upper()}","Music",rel.as_posix(),key,"Music",desc,"Project-owned original; no third-party material","single original track",f"seamless {dur}s loop"])
    for key, (dur, tones, texture, desc) in AMBIENCE.items():
        rel = Path("assets/audio/ambience") / f"{key}_loop.wav"
        write_wav(ROOT / rel, loop_bed(dur, 5000 + len(manifest), tones, texture))
        catalog["ambience"][key] = "res://" + rel.as_posix()
        manifest.append([f"AMB_{key.upper()}","Ambience",rel.as_posix(),key,"Ambience",desc,"Project-owned original; no third-party material","single original loop",f"seamless {dur}s loop"])
    (AUDIO / "audio_catalog.json").write_text(json.dumps(catalog, indent=2), encoding="utf-8")
    for manifest_name in ["AUDIO_PROVENANCE_MANIFEST.csv", "AUDIO_MANIFEST.csv"]:
        with (ROOT / "docs" / manifest_name).open("w", newline="", encoding="utf-8") as out:
            writer = csv.writer(out)
            writer.writerow(["Asset ID","Type","File path","Cue key","Bus","Origin / design","Licence","Variation","Looping"])
            writer.writerows(manifest)
    print(f"Built {len(manifest)} original audio files and catalogued {len(SFX)} cues, {len(MUSIC)} music tracks, {len(AMBIENCE)} ambience loops.")

if __name__ == "__main__": main()
