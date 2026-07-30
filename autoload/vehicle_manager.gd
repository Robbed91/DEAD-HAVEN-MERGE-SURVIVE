extends Node
## VehicleManager
##
## Owns vehicle content and runtime state (current_stage / is_discovered
## are tracked here, not mutated on the loaded VehicleDefinition resource
## - same pattern as ResidenceManager keeping hotspot state in its own
## Dictionary rather than touching shared/cached Resource instances).

const VEHICLES_DIR := "res://data/vehicles/"

var _vehicles: Dictionary = {} # id -> VehicleDefinition
var discovered_vehicle_ids: Dictionary = {} # id -> true
var current_stages: Dictionary = {} # id -> int

func _ready() -> void:
	var dir := DirAccess.open(VEHICLES_DIR)
	if dir == null:
		push_error("VehicleManager: could not open %s" % VEHICLES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var vehicle: VehicleDefinition = load(VEHICLES_DIR + file_name)
			if vehicle == null:
				push_error("VehicleManager: failed to load %s" % file_name)
			else:
				_vehicles[vehicle.id] = vehicle
		file_name = dir.get_next()
	dir.list_dir_end()

func reset_new_game() -> void:
	discovered_vehicle_ids.clear()
	current_stages.clear()

func get_vehicle(id: String) -> VehicleDefinition:
	return _vehicles.get(id)

func is_discovered(id: String) -> bool:
	return discovered_vehicle_ids.has(id)

func discover_vehicle(id: String) -> void:
	if not _vehicles.has(id) or is_discovered(id):
		return
	discovered_vehicle_ids[id] = true
	current_stages[id] = 0
	EventBus.vehicle_discovered.emit(id)
	SaveManager.request_autosave()

func get_current_stage(id: String) -> int:
	return int(current_stages.get(id, 0))

func get_current_stage_name(id: String) -> String:
	var vehicle := get_vehicle(id)
	if vehicle == null:
		return ""
	var stage := get_current_stage(id)
	if stage < 0 or stage >= vehicle.upgrade_stage_names.size():
		return ""
	return vehicle.upgrade_stage_names[stage]

func is_fully_upgraded(id: String) -> bool:
	var vehicle := get_vehicle(id)
	if vehicle == null:
		return false
	return get_current_stage(id) >= vehicle.upgrade_stage_names.size() - 1

## Requirements for the NEXT stage past the vehicle's current one, or an
## empty Dictionary if it's already fully upgraded.
func get_next_stage_requirements(id: String) -> Dictionary:
	var vehicle := get_vehicle(id)
	if vehicle == null or is_fully_upgraded(id):
		return {}
	var next_stage := get_current_stage(id) + 1
	return vehicle.stage_requirements.get(next_stage, {})

func next_stage_requirements_met(id: String) -> bool:
	var reqs := get_next_stage_requirements(id)
	if reqs.is_empty() and is_fully_upgraded(id):
		return false
	for item_id in reqs:
		if BoardState.count_item(item_id) < int(reqs[item_id]):
			return false
	return true

## Consumes the next stage's required items and advances current_stage by
## one. Returns a result dict matching BoardState/ResidenceManager's
## success/reason pattern.
func upgrade_stage(id: String) -> Dictionary:
	if not is_discovered(id):
		return {"success": false, "reason": "not_discovered"}
	if is_fully_upgraded(id):
		return {"success": false, "reason": "fully_upgraded"}
	if not next_stage_requirements_met(id):
		return {"success": false, "reason": "requirements_not_met"}

	var reqs := get_next_stage_requirements(id)
	for item_id in reqs:
		BoardState.consume_item(item_id, int(reqs[item_id]))

	current_stages[id] = get_current_stage(id) + 1
	EventBus.vehicle_stage_changed.emit(id, current_stages[id])
	SaveManager.request_autosave()
	return {"success": true, "new_stage": current_stages[id]}

func to_save_data() -> Dictionary:
	return {
		"discovered_vehicle_ids": discovered_vehicle_ids.keys(),
		"current_stages": current_stages.duplicate(),
	}

func apply_save_data(data: Dictionary) -> void:
	discovered_vehicle_ids.clear()
	current_stages.clear()
	for id in data.get("discovered_vehicle_ids", []):
		discovered_vehicle_ids[id] = true
	for id in data.get("current_stages", {}):
		current_stages[id] = int(data["current_stages"][id])
