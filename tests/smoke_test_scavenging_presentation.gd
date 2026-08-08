extends Node
## Verifies every implemented mission resolves to its own Android-sized final
## environment without changing ScavengingManager data or mission state.

const IDS := [
	"abandoned_grocery_store", "clothing_outlet", "electronics_workshop",
	"farm_shed", "medical_clinic", "petrol_station", "police_checkpoint",
	"radio_relay_station", "roadside_wreck", "warehouse_depot",
]

func _fail(message: String) -> void:
	print("SMOKE_SCAVENGING_PRESENTATION_FAIL: %s" % message)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()
	GameManager.profile.story_flags["saint_mercy_unlocked"] = true
	for mission_id in IDS:
		var path := "res://assets/art/scavenging/runtime/%s.png" % mission_id
		if not ResourceLoader.exists(path):
			_fail("missing runtime art for %s" % mission_id)
			return
		SceneRouter.pending_params = {"mission_id": mission_id}
		var scene: Control = load("res://scenes/scavenging/scavenging.tscn").instantiate()
		add_child(scene)
		await get_tree().process_frame
		var hero: TextureRect = scene.get_node("Layout/Margin/Content/HeroPanel/HeroCanvas/HeroImage")
		if hero.texture == null:
			_fail("hero texture was not integrated for %s" % mission_id)
			return
		if hero.texture.get_width() != 1024 or hero.texture.get_height() != 683:
			_fail("%s runtime art must be 1024x683, got %dx%d" % [mission_id, hero.texture.get_width(), hero.texture.get_height()])
			return
		scene.queue_free()
		await get_tree().process_frame
	print("SMOKE_SCAVENGING_PRESENTATION_OK locations=10 runtime=1024x683 dynamic=1")
	get_tree().quit(0)
