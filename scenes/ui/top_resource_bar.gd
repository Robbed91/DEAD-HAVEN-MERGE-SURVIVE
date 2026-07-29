extends PanelContainer
## TopResourceBar
##
## Reusable header shown on every main screen: level/xp, energy, coins,
## Haven Tokens and a notification bell. Reads GameManager on _ready and
## then only updates via EventBus signals - it never polls.

@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _energy_label: Label = %EnergyLabel
@onready var _energy_bar: ProgressBar = %EnergyBar
@onready var _coins_label: Label = %CoinsLabel
@onready var _tokens_label: Label = %TokensLabel
@onready var _notification_dot: Control = %NotificationDot

func _ready() -> void:
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.energy_changed.connect(_on_energy_changed)
	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.haven_tokens_changed.connect(_on_tokens_changed)
	_refresh_all()

func _refresh_all() -> void:
	var res: Dictionary = GameManager.resources
	var prof: Dictionary = GameManager.profile
	_on_level_up(prof.level)
	_on_energy_changed(res.energy, res.energy_max)
	_on_coins_changed(res.coins)
	_on_tokens_changed(res.haven_tokens)
	set_notification_visible(false)

func _on_xp_changed(current: int, needed: int) -> void:
	_xp_bar.max_value = needed
	_xp_bar.value = current

func _on_level_up(new_level: int) -> void:
	_level_label.text = "Lv %d" % new_level

func _on_energy_changed(current: int, maximum: int) -> void:
	_energy_label.text = "%d/%d" % [current, maximum]
	_energy_bar.max_value = maximum
	_energy_bar.value = current

func _on_coins_changed(amount: int) -> void:
	_coins_label.text = str(amount)

func _on_tokens_changed(amount: int) -> void:
	_tokens_label.text = str(amount)

func set_notification_visible(visible_flag: bool) -> void:
	_notification_dot.visible = visible_flag
