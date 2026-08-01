extends Node
## Focused export contract. Kept outside smoke_test*.tscn so the suite remains 33.

const PackedDirectoryScript := preload("res://scripts/data/packed_directory.gd")
const EXPECTED_COUNTS := {
	"items": 101,
	"chains": 13,
	"characters": 6,
	"dialogue": 23,
	"residences": 5,
	"quests": 42,
	"scavenging": 10,
	"vehicles": 1,
}
const REQUIRED_INCLUDES := [
	"assets/audio/audio_catalog.json",
	"data/chains/*.json",
]
const REQUIRED_EXCLUDES := [
	"docs/*",
	"tests/*",
	"tools/*",
	"android/*",
	"assets/concepts/*",
	"assets/manifests/*",
	"assets/**/source/*",
	"assets/art/hollow_creek/environments/hollow_creek_state_*.png",
	"icon.svg",
]

var _failures: Array[String] = []

func _ready() -> void:
	_check(PackedDirectoryScript.resource_name("thing.tres") == "thing.tres", "editor resource name changed")
	_check(PackedDirectoryScript.resource_name("thing.tres.remap") == "thing.tres", "PCK remap name was not normalized")
	_check(PackedDirectoryScript.resource_name("thing.png").is_empty(), "non-resource filename was accepted")
	_check(ResourceLoader.exists("res://assets/art/dialogue/runtime/intro_farmhouse_approach.png"), "promoted dialogue runtime art missing")
	_check(not ResourceLoader.exists("res://assets/concepts/vertical_slice/dialogue/intro_farmhouse_approach_concept.png"), "live dialogue still references concept path")

	var config := ConfigFile.new()
	_check(config.load("res://export_presets.cfg") == OK, "export_presets.cfg could not be parsed")
	_check_preset(config, 0, "Android", false)
	_check_preset(config, 1, "Android Verification", true)
	var project := ConfigFile.new()
	_check(project.load("res://project.godot") == OK, "project.godot could not be parsed")
	_check(int(project.get_value("display", "window/handheld/orientation", -1)) == 1, "Android orientation is not the Godot portrait enum")

	_check(ItemDatabase.get_all_item_ids().size() == EXPECTED_COUNTS.items, "item catalog count changed")
	_check(ItemDatabase.get_all_chain_ids().size() == EXPECTED_COUNTS.chains, "chain catalog count changed")
	_check(CharacterDatabase.get_all_survivor_ids().size() == EXPECTED_COUNTS.characters, "character catalog count changed")
	_check(ScavengingManager.get_all_mission_ids().size() == EXPECTED_COUNTS.scavenging, "scavenging catalog count changed")
	_check(DialogueManager.has_entry("signal_keeper_05"), "dialogue catalog incomplete")
	_check(ResidenceManager.get_residence("northgate_prison") != null, "residence catalog incomplete")
	_check(ResidenceManager.get_quest("q_rescue_caleb") != null, "quest catalog incomplete")
	_check(ResidenceManager.get_hotspot_quest_link_count() == 41, "packed hotspot task-link count changed")
	_check(ResidenceManager.validate_hotspot_quest_links().is_empty(), "packed hotspot task links are invalid")
	_check(VehicleManager.get_vehicle("delivery_van") != null, "vehicle catalog incomplete")

	if _failures.is_empty():
		print("ANDROID_EXPORT_RESOURCE_TEST_OK presets=2 version_code=2 shipping_abis=arm64 verification_abis=arm64,x86_64 catalogs=%s" % str(EXPECTED_COUNTS))
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("ANDROID_EXPORT_RESOURCE_TEST: %s" % failure)
		push_error("ANDROID_EXPORT_RESOURCE_TEST_FAIL")
		get_tree().quit(1)

func _check_preset(config: ConfigFile, index: int, expected_name: String, x86_64: bool) -> void:
	var section := "preset.%d" % index
	var options := "%s.options" % section
	_check(config.get_value(section, "name", "") == expected_name, "%s name mismatch" % section)
	_check(config.get_value(section, "export_filter", "") == "all_resources", "%s must audit all runtime resources" % section)
	_check(int(config.get_value(options, "version/code", 0)) == 2, "%s version code is not 2" % section)
	_check(config.get_value(options, "package/unique_name", "") == "com.deadhaven.mergeandsurvive", "%s package ID changed" % section)
	_check(bool(config.get_value(options, "architectures/arm64-v8a", false)), "%s is missing arm64" % section)
	_check(bool(config.get_value(options, "architectures/x86_64", false)) == x86_64, "%s x86_64 policy mismatch" % section)
	var includes := String(config.get_value(section, "include_filter", ""))
	var excludes := String(config.get_value(section, "exclude_filter", ""))
	for pattern in REQUIRED_INCLUDES:
		_check(pattern in includes, "%s missing include %s" % [section, pattern])
	for pattern in REQUIRED_EXCLUDES:
		_check(pattern in excludes, "%s missing exclusion %s" % [section, pattern])

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
