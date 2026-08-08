class_name MergeVFX
extends RefCounted
## Chain-ID-driven merge burst data. One pooled particle class
## (MergeParticle) plus this style table replace the old hardcoded wood/dust
## look every chain's merge used to share. Pure data/math only - node
## lifecycle (the actual pool, adding to the tree, tweening) stays owned by
## whichever scene plays the burst, same as the rest of this project's
## static VFX helpers (see scripts/vfx/motion_fx.gd).

const STYLES := {
	"construction": {"primary": "shard", "primary_color": Color("8a6a45"), "secondary": "puff", "secondary_color": Color("cbb98f")},
	"tool": {"primary": "fragment", "primary_color": Color("9aa0a6"), "secondary": "spark", "secondary_color": Color("f0e6b0")},
	"food": {"primary": "crumb", "primary_color": Color("c9a06a"), "secondary": "fleck", "secondary_color": Color("7a9a5a")},
	"medical": {"primary": "cross", "primary_color": Color("e7f0ea"), "secondary": "glint", "secondary_color": Color("9fd6c2")},
	"trap": {"primary": "fragment", "primary_color": Color("6d6a63"), "secondary": "cord", "secondary_color": Color("7a5a3c")},
	"fuel": {"primary": "droplet", "primary_color": Color("4f7a8c"), "secondary": "glint", "secondary_color": Color("e0a83f")},
	"vehicle_parts": {"primary": "chunk", "primary_color": Color("5c5e60"), "secondary": "spark", "secondary_color": Color("e0a83f")},
	"electronics": {"primary": "ring", "primary_color": Color("4fb0d6"), "secondary": "zigzag", "secondary_color": Color("cdeaf5")},
	"clothing": {"primary": "fiber", "primary_color": Color("8c7a9c"), "secondary": "fiber", "secondary_color": Color("cbbfd6")},
}
const DEFAULT_STYLE_CHAIN := "construction"

## Every particle plan entry a burst needs, computed once as plain data so
## it's independently testable without instantiating any Control/pool.
## quality: "low" | "standard" | "high" (GameManager settings.graphics_quality).
static func burst_plan(chain_id: String, level: int, quality: String) -> Dictionary:
	var style: Dictionary = STYLES.get(chain_id, STYLES[DEFAULT_STYLE_CHAIN])
	var base_count: int = 12 if level >= 5 else 7
	var count: int = base_count
	if quality == "low":
		count = maxi(3, int(round(base_count / 3.0)))
	elif quality == "high":
		count = base_count
	var particles: Array[Dictionary] = []
	for i in count:
		var use_secondary: bool = i % 3 == 0
		particles.append({
			"shape": String(style.secondary if use_secondary else style.primary),
			"color": style.secondary_color if use_secondary else style.primary_color,
			"particle_size": Vector2(28, 28) if use_secondary else Vector2(16, 16),
		})
	return {
		"count": count,
		"particles": particles,
		"emphasize": level >= 5,
	}

static func has_style(chain_id: String) -> bool:
	return STYLES.has(chain_id)
