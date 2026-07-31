extends Control
const MotionFXScript = preload("res://scripts/vfx/motion_fx.gd")
## Vehicle
##
## Single-screen view of the delivery van: current stage, an evolving
## procedural silhouette, and (until fully upgraded) the next stage's
## requirement with an Upgrade button - the same "show what's needed, gate
## the action on having it" pattern as TaskPanel.

const VEHICLE_ID := "delivery_van"

@onready var _visual: VehicleVisual = %VehicleVisual
@onready var _stage_label: Label = %StageLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _requirement_panel: VBoxContainer = %RequirementPanel
@onready var _requirement_icon: ItemView = %RequirementIcon
@onready var _requirement_label: Label = %RequirementLabel
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _complete_label: Label = %CompleteLabel

func _ready() -> void:
	if not VehicleManager.is_discovered(VEHICLE_ID):
		if get_tree().current_scene == self:
			EventBus.show_toast.emit("No vehicle found yet.")
			SceneRouter.go_to("world_map", {}, false)
		return

	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	%BackButton.pressed.connect(func(): SceneRouter.go_to("world_map", {}, false))
	EventBus.vehicle_stage_changed.connect(func(id, _stage):
		if id == VEHICLE_ID:
			_refresh()
			_visual.play_upgrade_sequence()
	)
	_refresh()

func _refresh() -> void:
	var vehicle := VehicleManager.get_vehicle(VEHICLE_ID)
	if vehicle == null:
		return
	var stage := VehicleManager.get_current_stage(VEHICLE_ID)
	_visual.stage = stage
	_stage_label.text = VehicleManager.get_current_stage_name(VEHICLE_ID)
	_progress_label.text = "Stage %d / %d" % [stage, vehicle.upgrade_stage_names.size() - 1]

	if VehicleManager.is_fully_upgraded(VEHICLE_ID):
		_requirement_panel.visible = false
		_complete_label.visible = true
		return

	_complete_label.visible = false
	_requirement_panel.visible = true
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
		_refresh()
	else:
		EventBus.show_toast.emit("Not enough materials yet.")
		MotionFXScript.shake(_upgrade_button)
