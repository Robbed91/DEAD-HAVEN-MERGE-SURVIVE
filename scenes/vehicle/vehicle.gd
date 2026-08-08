extends Control
const MotionFXScript = preload("res://scripts/vfx/motion_fx.gd")
## Vehicle
##
## Single-screen view of the delivery van. VehicleManager remains the source
## of truth; this scene binds its existing stages to final art, motion, and
## audio while retaining the original requirement/upgrade flow.

const VEHICLE_ID := "delivery_van"

@onready var _visual: VehicleVisual = %VehicleVisual
@onready var _stage_label: Label = %StageLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _stage_progress: ProgressBar = %StageProgress
@onready var _requirement_card: PanelContainer = %RequirementCard
@onready var _requirement_panel: VBoxContainer = %RequirementPanel
@onready var _requirement_icon: ItemView = %RequirementIcon
@onready var _requirement_label: Label = %RequirementLabel
@onready var _next_upgrade_label: Label = %NextUpgradeLabel
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _complete_label: Label = %CompleteLabel
@onready var _engine_status: Label = %EngineStatus

var _engine_audio_active := false

func _ready() -> void:
	if not VehicleManager.is_discovered(VEHICLE_ID):
		if get_tree().current_scene == self:
			EventBus.show_toast.emit("No vehicle found yet.")
			SceneRouter.go_to("world_map", {}, false)
		return

	# SceneRouter's generic vehicle bed is corrected here to the actual saved
	# stage: a wreck must remain silent; repaired stages may idle.
	AudioManager.stop_ambience_layer("vehicle_engine", 0.1)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	%BackButton.pressed.connect(func(): SceneRouter.go_to("world_map", {}, false))
	EventBus.vehicle_stage_changed.connect(func(id, new_stage):
		if id == VEHICLE_ID:
			AudioManager.play_sfx("vehicle_door")
			AudioManager.play_sfx("vehicle_headlights")
			if int(new_stage) >= 1:
				AudioManager.play_sfx("vehicle_exhaust")
			_refresh()
			_visual.play_upgrade_sequence()
	)
	_refresh()

func _exit_tree() -> void:
	if _engine_audio_active:
		AudioManager.stop_ambience_layer("vehicle_engine")

func _refresh() -> void:
	var vehicle := VehicleManager.get_vehicle(VEHICLE_ID)
	if vehicle == null:
		return
	var stage := VehicleManager.get_current_stage(VEHICLE_ID)
	_visual.stage = stage
	_stage_label.text = VehicleManager.get_current_stage_name(VEHICLE_ID)
	_progress_label.text = "Stage %d / %d" % [stage, vehicle.upgrade_stage_names.size() - 1]
	_stage_progress.value = stage
	_engine_status.text = "EXPEDITION READY" if stage >= 8 else ("ENGINE ONLINE  •  IDLE" if stage >= 1 else "ENGINE OFFLINE")
	_sync_engine_audio(stage >= 1)

	if VehicleManager.is_fully_upgraded(VEHICLE_ID):
		_requirement_card.visible = false
		_complete_label.visible = true
		return

	_complete_label.visible = false
	_requirement_card.visible = true
	_next_upgrade_label.text = "NEXT: %s" % String(vehicle.upgrade_stage_names[stage + 1]).to_upper()
	var reqs := VehicleManager.get_next_stage_requirements(VEHICLE_ID)
	if reqs.is_empty():
		_requirement_label.text = "No requirement data for this stage."
		_upgrade_button.disabled = true
		return
	var item_id: String = reqs.keys()[0]
	var needed: int = int(reqs[item_id])
	var owned: int = BoardState.count_item(item_id)
	var def := ItemDatabase.get_item(item_id)
	_requirement_icon.preview_item_id = item_id
	_requirement_label.text = "%s: %d / %d" % [def.display_name if def else item_id, owned, needed]
	_upgrade_button.disabled = owned < needed

func _on_upgrade_pressed() -> void:
	var result := VehicleManager.upgrade_stage(VEHICLE_ID)
	if result.success:
		EventBus.show_toast.emit("Upgraded: %s" % VehicleManager.get_current_stage_name(VEHICLE_ID))
	else:
		AudioManager.play_sfx("error")
		EventBus.show_toast.emit("Not enough materials yet.")
		MotionFXScript.shake(_upgrade_button)

func _sync_engine_audio(should_play: bool) -> void:
	if should_play == _engine_audio_active:
		return
	_engine_audio_active = should_play
	if should_play:
		AudioManager.play_ambience_layer("vehicle_engine", -12.0)
	else:
		AudioManager.stop_ambience_layer("vehicle_engine")
