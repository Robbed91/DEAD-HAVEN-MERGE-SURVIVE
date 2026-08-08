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
@onready var _margin: MarginContainer = %Margin
@onready var _row: HBoxContainer = %Row
@onready var _notification_button: Button = %NotificationButton
@onready var _resource_icons: Array[TextureRect] = [%EnergyTexture, %CoinsTexture, %TokensTexture]

func _ready() -> void:
	_level_label.add_theme_font_override("font", ThemeFactory.display_font())
	get_viewport().size_changed.connect(_apply_layout)
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.energy_changed.connect(_on_energy_changed)
	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.haven_tokens_changed.connect(_on_tokens_changed)
	_refresh_all()
	_apply_layout()

func _apply_layout() -> void:
	var narrow := size.x > 0.0 and size.x < 560.0
	var side_margin := 8 if narrow else 16
	var top_inset := _safe_top_inset()
	_margin.add_theme_constant_override("margin_left", side_margin)
	_margin.add_theme_constant_override("margin_right", side_margin)
	_margin.add_theme_constant_override("margin_top", 8 + top_inset)
	_margin.add_theme_constant_override("margin_bottom", 8)
	_row.add_theme_constant_override("separation", 5 if narrow else 12)
	_level_label.custom_minimum_size.x = 46 if narrow else 58
	_level_label.add_theme_font_size_override("font_size", 20 if narrow else 24)
	_energy_label.add_theme_font_size_override("font_size", 18 if narrow else 22)
	_coins_label.add_theme_font_size_override("font_size", 18 if narrow else 22)
	_tokens_label.add_theme_font_size_override("font_size", 18 if narrow else 22)
	for icon in _resource_icons:
		icon.custom_minimum_size = Vector2(25, 25) if narrow else Vector2(30, 30)
	_notification_button.custom_minimum_size = Vector2(44, 44) if narrow else Vector2(52, 52)
	custom_minimum_size.y = 84 + top_inset

func _safe_top_inset() -> int:
	var test_value := OS.get_environment("DEAD_HAVEN_SAFE_TOP")
	if not test_value.is_empty():
		return maxi(0, int(test_value))
	if not OS.has_feature("mobile"):
		return 0
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if window_size.y <= 0:
		return 0
	return maxi(0, int(round(float(safe.position.y) * get_viewport_rect().size.y / float(window_size.y))))

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
	_notification_button.theme_type_variation = "NotificationButton" if visible_flag else "NavButton"
