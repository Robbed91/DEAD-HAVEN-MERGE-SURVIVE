extends SceneTree
## One-off: verify whether Godot's own String.match() (the same matcher the
## exporter uses for include_filter/exclude_filter) treats '*' as crossing
## '/' or not - this determines whether "docs/*" in export_presets.cfg
## actually excludes nested files like docs/producer-state-captures/x.png,
## or only direct children of docs/. Not a permanent test, just a targeted
## verification for the export-size audit.

func _initialize() -> void:
	var cases := [
		["docs/producer-state-captures/live_merge_vfx_electronics.png", "docs/*"],
		["docs/vertical-slice-captures/hollow_creek_character_animation.avi", "docs/*"],
		["tests/smoke_test_merge.gd", "tests/*"],
		["assets/concepts/vertical_slice/characters/noah_vance_character_sheet_concept.png", "assets/concepts/*"],
		["assets/items/construction/source/construction_master.png", "assets/**/source/*"],
		["assets/items/tool/producer_active.png", "assets/**/source/*"],
	]
	for c in cases:
		var path: String = c[0]
		var pattern: String = c[1]
		print("%s matches %s -> %s" % [path, pattern, path.matchn(pattern)])
	quit()
