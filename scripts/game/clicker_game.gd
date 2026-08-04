extends Control

## Contrôleur principal du jeu : économie, progression et interface du cliqueur.

const RESOURCE_ORDER: Array[String] = ["points", "apples", "wood", "stone"]
const MAX_CLICK_LEVEL := 20
const MAX_AUTO_LEVEL := 20
const MAX_SPEED_LEVEL := 20
const MAX_BOOST_LEVEL := 5
const CLICKER_UPGRADE_COST_FACTOR := 0.75
const SPEED_BONUS_PER_LEVEL := 0.25
const POINTS_AUTO_CLICKS_PER_SECOND := [
	0.0,
	1.0,
	2.0,
	3.0,
	5.0,
	10.0,
	25.0,
	50.0,
	100.0,
	150.0,
	200.0,
	350.0,
	500.0,
	1000.0,
	2500.0,
	5000.0,
	10000.0,
	25000.0,
	50000.0,
	100000.0,
	250000.0,
]
const AUTO_CLICK_MILESTONES := {
	5: 10.0,
	8: 100.0,
	10: 200.0,
	12: 500.0,
	15: 5000.0,
	18: 50000.0,
	20: 250000.0,
}

const COLORS := {
	"background": Color("0d1224"),
	"background_alt": Color("151c33"),
	"panel": Color("1b2440"),
	"panel_hover": Color("253252"),
	"text": Color("f5f7ff"),
	"muted": Color("9ba8c7"),
	"points": Color("72d8ff"),
	"apples": Color("ff6f7d"),
	"wood": Color("e0a76a"),
	"stone": Color("b8c2d8"),
	"success": Color("71e1a1"),
	"warning": Color("ffd166"),
	"danger": Color("ff7b8b"),
}

var resources: Dictionary = {
	"points": {
		"name": "Points",
		"symbol": "✦",
		"amount": 0.0,
		"per_click": 1.0,
		"auto_level": 0,
		"auto_base": 1.0,
		"unlocked": true,
	},
	"apples": {
		"name": "Pommes",
		"symbol": "●",
		"amount": 0.0,
		"per_click": 1.0,
		"auto_level": 0,
		"auto_base": 0.5,
		"unlocked": false,
	},
	"wood": {
		"name": "Bois",
		"symbol": "▰",
		"amount": 0.0,
		"per_click": 1.0,
		"auto_level": 0,
		"auto_base": 0.35,
		"unlocked": false,
	},
	"stone": {
		"name": "Pierre",
		"symbol": "⬟",
		"amount": 0.0,
		"per_click": 1.0,
		"auto_level": 0,
		"auto_base": 0.2,
		"unlocked": false,
	},
}

var click_levels: Dictionary = {
	"points": 0,
	"apples": 0,
	"wood": 0,
	"stone": 0,
}

var speed_level := 0
var boost_level := 0
var ui_refresh_elapsed := 0.0
var session_elapsed := 0.0
var gained_since_refresh: Dictionary = {}
var activity_entries: Array[String] = []

var pages: TabContainer
var navigation_buttons: Array[Button] = []
var resource_amount_labels: Dictionary = {}
var resource_rate_labels: Dictionary = {}
var resource_gain_labels: Dictionary = {}
var resource_detail_labels: Dictionary = {}
var manual_buttons: Dictionary = {}
var upgrade_buttons: Dictionary = {}
var overview_labels: Dictionary = {}
var activity_log: RichTextLabel
var header_summary: Label
var main_click_button: Button
var click_feedback: Label
var dev_panel: PanelContainer
var dev_amount: LineEdit
var dev_resource: OptionButton


func _ready() -> void:
	for resource_id in RESOURCE_ORDER:
		gained_since_refresh[resource_id] = 0.0

	_build_interface()
	_add_activity("Bienvenue ! Chaque clic fait grandir votre atelier.", COLORS.success)
	_update_interface(false)
	call_deferred("_prepare_click_button")


func _process(delta: float) -> void:
	session_elapsed += delta
	for resource_id in RESOURCE_ORDER:
		var production := _production_rate(resource_id)
		if production > 0.0:
			_add_resource(resource_id, production * delta)

	ui_refresh_elapsed += delta
	if ui_refresh_elapsed >= 0.12:
		ui_refresh_elapsed = 0.0
		_update_interface(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and pages.current_tab == 0:
			_on_main_click()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F10:
			dev_panel.visible = not dev_panel.visible
			get_viewport().set_input_as_handled()


func _build_interface() -> void:
	_build_background()

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 28)
	outer_margin.add_theme_constant_override("margin_top", 22)
	outer_margin.add_theme_constant_override("margin_right", 28)
	outer_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(outer_margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	outer_margin.add_child(layout)

	layout.add_child(_build_header())
	layout.add_child(_build_navigation())

	pages = TabContainer.new()
	pages.tabs_visible = false
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	layout.add_child(pages)

	pages.add_child(_build_workshop_page())
	pages.set_tab_title(0, "Atelier")
	pages.add_child(_build_production_page())
	pages.set_tab_title(1, "Production")
	pages.add_child(_build_upgrades_page())
	pages.set_tab_title(2, "Améliorations")
	pages.current_tab = 0

	_build_dev_panel()


func _build_background() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	gradient.colors = PackedColorArray([
		Color("0b1020"),
		Color("151c35"),
		Color("10192e"),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1280
	texture.height = 720
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 1.0)
	background.texture = texture
	add_child(background)


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 68
	header.add_theme_constant_override("separation", 18)

	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", 1)
	header.add_child(brand)

	var title := _label("CLIKER / ATELIER", 28, COLORS.text)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.9))
	brand.add_child(title)
	brand.add_child(_label("Transformez chaque clic en une chaîne de production.", 15, COLORS.muted))

	header_summary = _label("", 16, COLORS.points)
	header_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(header_summary)
	return header


func _build_navigation() -> Control:
	var panel := _panel(COLORS.background_alt, Color("293452"), 14, 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var nav_group := ButtonGroup.new()
	var names := ["ATELIER", "PRODUCTION", "AMÉLIORATIONS"]
	var descriptions := ["Cliquer et récolter", "Suivre les gains", "Développer l’atelier"]
	for index in names.size():
		var button := Button.new()
		button.text = names[index] + "\n" + descriptions[index]
		button.toggle_mode = true
		button.button_group = nav_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		_style_nav_button(button)
		button.pressed.connect(_show_page.bind(index))
		row.add_child(button)
		navigation_buttons.append(button)

	navigation_buttons[0].button_pressed = true
	return panel


func _build_workshop_page() -> Control:
	var page := MarginContainer.new()
	page.name = "Atelier"
	page.add_theme_constant_override("margin_top", 2)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	page.add_child(columns)

	var action_column := VBoxContainer.new()
	action_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_column.size_flags_stretch_ratio = 1.7
	action_column.add_theme_constant_override("separation", 14)
	columns.add_child(action_column)

	var click_panel := _panel(Color("17233e"), COLORS.points, 22, 18)
	click_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_column.add_child(click_panel)

	var click_content := VBoxContainer.new()
	click_content.alignment = BoxContainer.ALIGNMENT_CENTER
	click_content.add_theme_constant_override("separation", 10)
	click_panel.add_child(click_content)

	var eyebrow := _label("SOURCE PRINCIPALE", 13, COLORS.points)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	click_content.add_child(eyebrow)

	main_click_button = Button.new()
	main_click_button.custom_minimum_size = Vector2(440, 190)
	main_click_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_click_button.text = "CLIQUER\n+1 point"
	main_click_button.tooltip_text = "Cliquez ou appuyez sur la barre d’espace"
	_style_action_button(main_click_button, COLORS.points, true)
	main_click_button.pressed.connect(_on_main_click)
	click_content.add_child(main_click_button)

	click_feedback = _label("Barre d’espace disponible", 15, COLORS.muted)
	click_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	click_content.add_child(click_feedback)

	var gather_panel := _panel(COLORS.panel, Color("34415f"), 18, 14)
	action_column.add_child(gather_panel)
	var gather_content := VBoxContainer.new()
	gather_content.add_theme_constant_override("separation", 10)
	gather_panel.add_child(gather_content)
	gather_content.add_child(_label("RÉCOLTES MANUELLES", 15, COLORS.text))

	var gather_grid := GridContainer.new()
	gather_grid.columns = 3
	gather_grid.add_theme_constant_override("h_separation", 10)
	gather_content.add_child(gather_grid)
	for resource_id in ["apples", "wood", "stone"]:
		var gather_button := Button.new()
		gather_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gather_button.custom_minimum_size = Vector2(0, 76)
		_style_action_button(gather_button, COLORS[resource_id])
		gather_button.pressed.connect(_on_resource_click.bind(resource_id))
		gather_grid.add_child(gather_button)
		manual_buttons[resource_id] = gather_button

	var live_panel := _panel(COLORS.panel, Color("34415f"), 20, 18)
	live_panel.custom_minimum_size.x = 355
	live_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_panel.size_flags_stretch_ratio = 1.0
	columns.add_child(live_panel)

	var live_content := VBoxContainer.new()
	live_content.add_theme_constant_override("separation", 12)
	live_panel.add_child(live_content)

	var live_title := HBoxContainer.new()
	live_content.add_child(live_title)
	var pulse := _label("●", 15, COLORS.success)
	pulse.custom_minimum_size.x = 22
	live_title.add_child(pulse)
	var live_heading := _label("FLUX EN DIRECT", 16, COLORS.text)
	live_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_title.add_child(live_heading)

	var quick_stats := VBoxContainer.new()
	quick_stats.add_theme_constant_override("separation", 8)
	live_content.add_child(quick_stats)
	for resource_id in RESOURCE_ORDER:
		var stat_row := HBoxContainer.new()
		stat_row.add_child(_label(str(resources[resource_id]["symbol"]) + "  " + str(resources[resource_id]["name"]), 15, COLORS[resource_id]))
		var value := _label("0", 16, COLORS.text)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stat_row.add_child(value)
		overview_labels[resource_id] = value
		quick_stats.add_child(stat_row)

	live_content.add_child(HSeparator.new())
	activity_log = RichTextLabel.new()
	activity_log.bbcode_enabled = true
	activity_log.fit_content = false
	activity_log.scroll_active = true
	activity_log.scroll_following = true
	activity_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	activity_log.add_theme_font_size_override("normal_font_size", 14)
	activity_log.add_theme_color_override("default_color", COLORS.muted)
	activity_log.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	live_content.add_child(activity_log)
	return page


func _build_production_page() -> Control:
	var page := VBoxContainer.new()
	page.name = "Production"
	page.add_theme_constant_override("separation", 14)

	var intro := HBoxContainer.new()
	intro.add_child(_label("PRODUCTION EN TEMPS RÉEL", 20, COLORS.text))
	var hint := _label("Les gains récents s’allument à chaque mise à jour.", 14, COLORS.muted)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	intro.add_child(hint)
	page.add_child(intro)

	var cards := GridContainer.new()
	cards.columns = 4
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	page.add_child(cards)

	for resource_id in RESOURCE_ORDER:
		cards.add_child(_build_resource_card(resource_id))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	page.add_child(footer)

	var rhythm_panel := _panel(COLORS.panel, Color("34415f"), 16, 14)
	rhythm_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(rhythm_panel)
	var rhythm := VBoxContainer.new()
	rhythm_panel.add_child(rhythm)
	rhythm.add_child(_label("RYTHME GLOBAL", 14, COLORS.warning))
	var rhythm_value := _label("", 18, COLORS.text)
	rhythm.add_child(rhythm_value)
	resource_detail_labels["global_speed"] = rhythm_value

	var goal_panel := _panel(COLORS.panel, Color("34415f"), 16, 14)
	goal_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(goal_panel)
	var goal := VBoxContainer.new()
	goal_panel.add_child(goal)
	goal.add_child(_label("PROCHAIN OBJECTIF", 14, COLORS.success))
	var goal_value := _label("", 18, COLORS.text)
	goal.add_child(goal_value)
	resource_detail_labels["next_goal"] = goal_value
	return page


func _build_resource_card(resource_id: String) -> Control:
	var accent: Color = COLORS[resource_id]
	var card := _panel(Color("19223c"), accent, 20, 18)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(210, 300)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var symbol := _label(str(resources[resource_id]["symbol"]), 34, accent)
	content.add_child(symbol)
	content.add_child(_label(str(resources[resource_id]["name"]).to_upper(), 15, COLORS.muted))

	var amount := _label("0", 30, COLORS.text)
	amount.size_flags_vertical = Control.SIZE_EXPAND_FILL
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(amount)
	resource_amount_labels[resource_id] = amount

	var gain := _label("Aucun gain récent", 14, COLORS.muted)
	content.add_child(gain)
	resource_gain_labels[resource_id] = gain

	content.add_child(HSeparator.new())
	var rate := _label("+0 / seconde", 16, accent)
	content.add_child(rate)
	resource_rate_labels[resource_id] = rate

	var detail := _label("", 13, COLORS.muted)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 42
	content.add_child(detail)
	resource_detail_labels[resource_id] = detail
	return card


func _build_upgrades_page() -> Control:
	var page := ScrollContainer.new()
	page.name = "Améliorations"
	page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	page.add_child(content)

	var heading := HBoxContainer.new()
	heading.add_child(_label("CENTRE D’AMÉLIORATIONS", 20, COLORS.text))
	var tip := _label("Les boutons deviennent lumineux dès que vous pouvez payer.", 14, COLORS.muted)
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(tip)
	content.add_child(heading)

	content.add_child(_build_upgrade_section("POINTS", "Renforcez le cœur du cliqueur.", "points", [
		["points_click", "Force du clic", Callable(self, "_buy_click_upgrade").bind("points")],
		["points_auto", "Auto-cliqueur", Callable(self, "_buy_auto_upgrade").bind("points")],
		["global_speed", "Cadence générale", Callable(self, "_buy_speed_upgrade")],
		["global_boost", "Amplificateur", Callable(self, "_buy_boost_upgrade")],
	]))

	content.add_child(_build_upgrade_section("POMMES", "Débloquez le verger puis automatisez la récolte.", "apples", [
		["apples_unlock", "Débloquer le verger", Callable(self, "_unlock_resource").bind("apples")],
		["apples_click", "Panier renforcé", Callable(self, "_buy_click_upgrade").bind("apples")],
		["apples_auto", "Jardinier", Callable(self, "_buy_auto_upgrade").bind("apples")],
	]))

	content.add_child(_build_upgrade_section("BOIS", "Ouvrez la scierie pour produire du bois.", "wood", [
		["wood_unlock", "Ouvrir la scierie", Callable(self, "_unlock_resource").bind("wood")],
		["wood_click", "Hache affûtée", Callable(self, "_buy_click_upgrade").bind("wood")],
		["wood_auto", "Bûcheron", Callable(self, "_buy_auto_upgrade").bind("wood")],
	]))

	content.add_child(_build_upgrade_section("PIERRE", "La carrière complète votre chaîne de production.", "stone", [
		["stone_unlock", "Ouvrir la carrière", Callable(self, "_unlock_resource").bind("stone")],
		["stone_click", "Pioche solide", Callable(self, "_buy_click_upgrade").bind("stone")],
		["stone_auto", "Mineur", Callable(self, "_buy_auto_upgrade").bind("stone")],
	]))

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8
	content.add_child(spacer)
	return page


func _build_upgrade_section(title: String, subtitle: String, resource_id: String, definitions: Array) -> Control:
	var section := _panel(Color("19223c"), COLORS[resource_id], 18, 15)
	var section_content := VBoxContainer.new()
	section_content.add_theme_constant_override("separation", 10)
	section.add_child(section_content)

	var heading := HBoxContainer.new()
	heading.add_child(_label(str(resources[resource_id]["symbol"]) + "  " + title, 17, COLORS[resource_id]))
	var sub := _label(subtitle, 13, COLORS.muted)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(sub)
	section_content.add_child(heading)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	section_content.add_child(grid)

	for definition in definitions:
		var key: String = definition[0]
		var button := Button.new()
		button.text = definition[1]
		button.custom_minimum_size = Vector2(380, 86)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = "Acheter cette amélioration"
		_style_upgrade_button(button, COLORS[resource_id])
		button.pressed.connect(definition[2])
		grid.add_child(button)
		upgrade_buttons[key] = button
	return section


func _build_dev_panel() -> void:
	dev_panel = _panel(Color("10182d"), COLORS.warning, 16, 16)
	dev_panel.visible = false
	dev_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dev_panel.position = Vector2(-390, 22)
	dev_panel.size = Vector2(360, 235)
	dev_panel.z_index = 20
	add_child(dev_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	dev_panel.add_child(content)
	content.add_child(_label("OUTILS DE TEST · F10", 16, COLORS.warning))
	content.add_child(_label("Ajoute une ressource pour tester la progression.", 13, COLORS.muted))

	dev_resource = OptionButton.new()
	for resource_id in RESOURCE_ORDER:
		dev_resource.add_item(str(resources[resource_id]["name"]))
	content.add_child(dev_resource)

	dev_amount = LineEdit.new()
	dev_amount.placeholder_text = "Montant positif"
	dev_amount.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	dev_amount.text_submitted.connect(_on_dev_submit)
	content.add_child(dev_amount)

	var give_button := Button.new()
	give_button.text = "AJOUTER"
	_style_action_button(give_button, COLORS.warning)
	give_button.pressed.connect(_give_dev_resource)
	content.add_child(give_button)


func _show_page(index: int) -> void:
	pages.current_tab = index
	for button_index in navigation_buttons.size():
		navigation_buttons[button_index].button_pressed = button_index == index


func _on_main_click() -> void:
	var amount: float = resources["points"]["per_click"]
	_add_resource("points", amount)
	_add_activity("Clic manuel : +%s point%s" % [_format_number(amount), "s" if amount > 1.0 else ""], COLORS.points)
	click_feedback.text = "+%s point%s" % [_format_number(amount), "s" if amount > 1.0 else ""]
	click_feedback.add_theme_color_override("font_color", COLORS.success)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(main_click_button, "scale", Vector2(0.965, 0.965), 0.055)
	tween.tween_property(main_click_button, "scale", Vector2.ONE, 0.11)
	_update_interface(false)


func _on_resource_click(resource_id: String) -> void:
	if not resources[resource_id]["unlocked"]:
		return
	var amount: float = resources[resource_id]["per_click"]
	_add_resource(resource_id, amount)
	_add_activity("Récolte : +%s %s" % [_format_number(amount), str(resources[resource_id]["name"]).to_lower()], COLORS[resource_id])
	_update_interface(false)


func _unlock_resource(resource_id: String) -> void:
	if resources[resource_id]["unlocked"]:
		return
	var cost := _unlock_cost(resource_id)
	if not _spend(cost):
		return
	resources[resource_id]["unlocked"] = true
	_add_activity("%s débloqué !" % str(resources[resource_id]["name"]), COLORS[resource_id])
	_update_interface(false)


func _buy_click_upgrade(resource_id: String) -> void:
	if not resources[resource_id]["unlocked"]:
		return
	var level: int = click_levels[resource_id]
	if level >= MAX_CLICK_LEVEL:
		return
	var cost := _click_upgrade_cost(resource_id, level)
	if not _spend(cost):
		return
	click_levels[resource_id] = level + 1
	resources[resource_id]["per_click"] = 1.0 + float(click_levels[resource_id])
	_add_activity("%s : clic amélioré au niveau %d." % [str(resources[resource_id]["name"]), click_levels[resource_id]], COLORS[resource_id])
	_update_interface(false)


func _buy_auto_upgrade(resource_id: String) -> void:
	if not resources[resource_id]["unlocked"]:
		return
	var level: int = resources[resource_id]["auto_level"]
	if level >= MAX_AUTO_LEVEL:
		return
	var cost := _auto_upgrade_cost(resource_id, level)
	if not _spend(cost):
		return
	var new_level := level + 1
	resources[resource_id]["auto_level"] = new_level
	if resource_id == "points" and AUTO_CLICK_MILESTONES.has(new_level):
		_add_activity("Auto-cliqueur niveau %d : palier de %s clics/s atteint !" % [new_level, _format_number(_points_auto_rate_for_level(new_level))], COLORS.success)
	else:
		_add_activity("%s : producteur automatique niveau %d." % [str(resources[resource_id]["name"]), new_level], COLORS[resource_id])
	_update_interface(false)


func _buy_speed_upgrade() -> void:
	if speed_level >= MAX_SPEED_LEVEL:
		return
	var cost := {"points": _clicker_upgrade_cost(150, speed_level, 1.9)}
	if not _spend(cost):
		return
	speed_level += 1
	var level_bonus := _speed_bonus_for_level(speed_level)
	if speed_level % 5 == 0:
		_add_activity("Palier cadence %d : +%d %% par niveau !" % [speed_level, int(roundf(level_bonus * 100.0))], COLORS.success)
	else:
		_add_activity("Cadence générale augmentée : x%.2f." % _speed_multiplier(), COLORS.warning)
	_update_interface(false)


func _buy_boost_upgrade() -> void:
	if boost_level >= MAX_BOOST_LEVEL:
		return
	var cost := {
		"points": _clicker_upgrade_cost(750, boost_level, 2.3),
		"apples": _scaled_value(25, boost_level, 1.8),
	}
	if not _spend(cost):
		return
	boost_level += 1
	_add_activity("Amplificateur niveau %d : toute la production accélère." % boost_level, COLORS.success)
	_update_interface(false)


func _add_resource(resource_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	resources[resource_id]["amount"] = float(resources[resource_id]["amount"]) + amount
	gained_since_refresh[resource_id] = float(gained_since_refresh[resource_id]) + amount


func _spend(cost: Dictionary) -> bool:
	if not _can_afford(cost):
		return false
	for resource_id in cost:
		resources[resource_id]["amount"] = maxf(0.0, float(resources[resource_id]["amount"]) - float(cost[resource_id]))
	return true


func _can_afford(cost: Dictionary) -> bool:
	for resource_id in cost:
		if float(resources[resource_id]["amount"]) + 0.0001 < float(cost[resource_id]):
			return false
	return true


func _production_rate(resource_id: String) -> float:
	if not resources[resource_id]["unlocked"]:
		return 0.0
	var base_rate := _base_automation_rate(resource_id)
	return base_rate * _speed_multiplier() * _boost_multiplier()


func _base_automation_rate(resource_id: String) -> float:
	var level: int = resources[resource_id]["auto_level"]
	var rate: float = float(level) * float(resources[resource_id]["auto_base"])
	if resource_id == "points":
		return _points_auto_rate_for_level(level)
	return rate


func _speed_multiplier() -> float:
	var multiplier := 1.0
	for level in range(1, speed_level + 1):
		multiplier += _speed_bonus_for_level(level)
	return multiplier


func _speed_bonus_for_level(level: int) -> float:
	if level >= 20:
		return 1.15
	if level >= 15:
		return 0.95
	if level >= 10:
		return 0.75
	if level >= 5:
		return 0.55
	return SPEED_BONUS_PER_LEVEL


func _points_auto_rate_for_level(level: int) -> float:
	if level <= 0:
		return 0.0
	var maximum_index := POINTS_AUTO_CLICKS_PER_SECOND.size() - 1
	if level <= maximum_index:
		return float(POINTS_AUTO_CLICKS_PER_SECOND[level])
	return float(POINTS_AUTO_CLICKS_PER_SECOND[maximum_index]) * pow(2.0, float(level - maximum_index))


func _boost_multiplier() -> float:
	return 1.0 + float(boost_level) * 0.25


func _unlock_cost(resource_id: String) -> Dictionary:
	match resource_id:
		"apples":
			return {"points": 250}
		"wood":
			return {"points": 1200, "apples": 80}
		"stone":
			return {"points": 4000, "apples": 200, "wood": 100}
	return {}


func _click_upgrade_cost(resource_id: String, level: int) -> Dictionary:
	match resource_id:
		"points":
			return {"points": _clicker_upgrade_cost(20, level, 1.52)}
		"apples":
			return {"points": _scaled_value(120, level, 1.58), "apples": _scaled_value(8, level, 1.45)}
		"wood":
			return {"points": _scaled_value(450, level, 1.58), "wood": _scaled_value(8, level, 1.45)}
		"stone":
			return {"points": _scaled_value(1500, level, 1.58), "stone": _scaled_value(8, level, 1.45)}
	return {}


func _auto_upgrade_cost(resource_id: String, level: int) -> Dictionary:
	match resource_id:
		"points":
			return {"points": _clicker_upgrade_cost(25, level, 1.62)}
		"apples":
			return {"points": _scaled_value(400, level, 1.62), "apples": _scaled_value(15, level, 1.5)}
		"wood":
			return {"points": _scaled_value(900, level, 1.62), "apples": _scaled_value(40, level, 1.5), "wood": _scaled_value(15, level, 1.5)}
		"stone":
			return {"points": _scaled_value(3000, level, 1.62), "wood": _scaled_value(75, level, 1.5), "stone": _scaled_value(20, level, 1.5)}
	return {}


func _scaled_value(base: int, level: int, growth: float) -> int:
	return int(ceil(float(base) * pow(growth, float(level))))


func _clicker_upgrade_cost(base: int, level: int, growth: float) -> int:
	return int(ceil(float(_scaled_value(base, level, growth)) * CLICKER_UPGRADE_COST_FACTOR))


func _update_interface(clear_recent_gains: bool) -> void:
	for resource_id in RESOURCE_ORDER:
		var unlocked: bool = resources[resource_id]["unlocked"]
		var amount: float = resources[resource_id]["amount"]
		var rate := _production_rate(resource_id)
		var recent: float = gained_since_refresh[resource_id]

		if overview_labels.has(resource_id):
			overview_labels[resource_id].text = _format_number(amount) if unlocked else "Verrouillé"
			overview_labels[resource_id].add_theme_color_override("font_color", COLORS.text if unlocked else COLORS.muted)

		if resource_amount_labels.has(resource_id):
			resource_amount_labels[resource_id].text = _format_number(amount) if unlocked else "—"
			resource_rate_labels[resource_id].text = "+%s / seconde" % _format_number(rate) if unlocked else "Production verrouillée"
			resource_detail_labels[resource_id].text = _resource_production_detail(resource_id) if unlocked else _unlock_hint(resource_id)

			if recent > 0.0001 and unlocked:
				resource_gain_labels[resource_id].text = "+%s récemment" % _format_number(recent)
				resource_gain_labels[resource_id].add_theme_color_override("font_color", COLORS.success)
			else:
				resource_gain_labels[resource_id].text = "En attente d’un gain"
				resource_gain_labels[resource_id].add_theme_color_override("font_color", COLORS.muted)

	if main_click_button:
		main_click_button.text = "CLIQUER\n+%s point%s" % [_format_number(resources["points"]["per_click"]), "s" if resources["points"]["per_click"] > 1.0 else ""]

	for resource_id in ["apples", "wood", "stone"]:
		_update_manual_button(resource_id)

	_update_upgrade_buttons()
	header_summary.text = "%s points  •  +%s/s" % [_format_number(resources["points"]["amount"]), _format_number(_production_rate("points"))]

	if resource_detail_labels.has("global_speed"):
		resource_detail_labels["global_speed"].text = "Cadence x%.2f  •  Amplification x%.2f" % [_speed_multiplier(), _boost_multiplier()]
		resource_detail_labels["next_goal"].text = _next_goal_text()

	if clear_recent_gains:
		for resource_id in RESOURCE_ORDER:
			gained_since_refresh[resource_id] = 0.0


func _update_manual_button(resource_id: String) -> void:
	var button: Button = manual_buttons[resource_id]
	if resources[resource_id]["unlocked"]:
		button.disabled = false
		button.text = "%s  %s\nRÉCOLTER +%s" % [resources[resource_id]["symbol"], str(resources[resource_id]["name"]).to_upper(), _format_number(resources[resource_id]["per_click"])]
		button.tooltip_text = "Récolter manuellement"
	else:
		button.disabled = true
		button.text = "%s  %s\nÀ DÉBLOQUER" % [resources[resource_id]["symbol"], str(resources[resource_id]["name"]).to_upper()]
		button.tooltip_text = _unlock_hint(resource_id)


func _update_upgrade_buttons() -> void:
	_update_level_button("points_click", "Force du clic", click_levels["points"], MAX_CLICK_LEVEL, _click_upgrade_cost("points", click_levels["points"]), "+1 point par clic", true)
	_update_level_button("points_auto", "Auto-cliqueur", resources["points"]["auto_level"], MAX_AUTO_LEVEL, _auto_upgrade_cost("points", resources["points"]["auto_level"]), _points_auto_upgrade_effect(), true)
	_update_level_button("global_speed", "Cadence générale", speed_level, MAX_SPEED_LEVEL, {"points": _clicker_upgrade_cost(150, speed_level, 1.9)}, _speed_upgrade_effect(), true)
	_update_level_button("global_boost", "Amplificateur", boost_level, MAX_BOOST_LEVEL, {"points": _clicker_upgrade_cost(750, boost_level, 2.3), "apples": _scaled_value(25, boost_level, 1.8)}, "+25 % de production", resources["apples"]["unlocked"])

	for resource_id in ["apples", "wood", "stone"]:
		var unlock_key: String = resource_id + "_unlock"
		var unlocked: bool = resources[resource_id]["unlocked"]
		var unlock_button: Button = upgrade_buttons[unlock_key]
		if unlocked:
			unlock_button.text = "%s DÉBLOQUÉ\nLa production est disponible" % str(resources[resource_id]["name"]).to_upper()
			unlock_button.disabled = true
		else:
			var unlock_cost := _unlock_cost(resource_id)
			unlock_button.text = "%s\nCoût : %s" % [_unlock_title(resource_id), _format_cost(unlock_cost)]
			unlock_button.disabled = not _can_afford(unlock_cost)

		_update_level_button(resource_id + "_click", _click_upgrade_title(resource_id), click_levels[resource_id], MAX_CLICK_LEVEL, _click_upgrade_cost(resource_id, click_levels[resource_id]), "+1 par clic", unlocked)
		_update_level_button(resource_id + "_auto", _auto_upgrade_title(resource_id), resources[resource_id]["auto_level"], MAX_AUTO_LEVEL, _auto_upgrade_cost(resource_id, resources[resource_id]["auto_level"]), "+%s/s" % _format_number(resources[resource_id]["auto_base"]), unlocked)


func _points_auto_upgrade_effect() -> String:
	var level: int = resources["points"]["auto_level"]
	if level >= MAX_AUTO_LEVEL:
		return "%s clics/s atteints" % _format_number(_points_auto_rate_for_level(level))
	var next_level := level + 1
	if AUTO_CLICK_MILESTONES.has(next_level):
		return "PALIER %d : %s clics/s" % [next_level, _format_number(_points_auto_rate_for_level(next_level))]
	return "Prochain niveau : %s clics/s" % _format_number(_points_auto_rate_for_level(next_level))


func _speed_upgrade_effect() -> String:
	var next_level := speed_level + 1
	var bonus_percent := int(roundf(_speed_bonus_for_level(next_level) * 100.0))
	if next_level % 5 == 0:
		return "PALIER %d : +%d %% de production" % [next_level, bonus_percent]
	return "+%d %% de production par niveau" % bonus_percent


func _resource_production_detail(resource_id: String) -> String:
	var level: int = resources[resource_id]["auto_level"]
	if resource_id == "points" and level > 0:
		return "Clic : +%s  •  Auto : Nv. %d · %s clics/s" % [_format_number(resources[resource_id]["per_click"]), level, _format_number(_points_auto_rate_for_level(level))]
	return "Clic : +%s  •  Automates : %d" % [_format_number(resources[resource_id]["per_click"]), level]


func _update_level_button(key: String, title: String, level: int, maximum: int, cost: Dictionary, effect: String, available: bool) -> void:
	var button: Button = upgrade_buttons[key]
	if not available:
		button.text = "%s\nVerrouillé pour le moment" % title
		button.disabled = true
		return
	if level >= maximum:
		button.text = "%s  •  NIVEAU MAX\n%s" % [title, effect]
		button.disabled = true
		return
	button.text = "%s  •  Nv. %d/%d\n%s  •  Coût : %s" % [title, level, maximum, effect, _format_cost(cost)]
	button.disabled = not _can_afford(cost)
	button.tooltip_text = "Disponible" if not button.disabled else "Ressources insuffisantes"


func _unlock_hint(resource_id: String) -> String:
	return "À débloquer dans Améliorations · %s" % _format_cost(_unlock_cost(resource_id))


func _unlock_title(resource_id: String) -> String:
	match resource_id:
		"apples": return "Débloquer le verger"
		"wood": return "Ouvrir la scierie"
		"stone": return "Ouvrir la carrière"
	return "Débloquer"


func _click_upgrade_title(resource_id: String) -> String:
	match resource_id:
		"apples": return "Panier renforcé"
		"wood": return "Hache affûtée"
		"stone": return "Pioche solide"
	return "Force du clic"


func _auto_upgrade_title(resource_id: String) -> String:
	match resource_id:
		"apples": return "Jardinier"
		"wood": return "Bûcheron"
		"stone": return "Mineur"
	return "Auto-cliqueur"


func _next_goal_text() -> String:
	if not resources["apples"]["unlocked"]:
		return "Débloquer les pommes · %s" % _format_cost(_unlock_cost("apples"))
	if not resources["wood"]["unlocked"]:
		return "Débloquer le bois · %s" % _format_cost(_unlock_cost("wood"))
	if not resources["stone"]["unlocked"]:
		return "Débloquer la pierre · %s" % _format_cost(_unlock_cost("stone"))
	return "Toutes les ressources sont ouvertes. Visez le niveau maximum !"


func _format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for resource_id in RESOURCE_ORDER:
		if cost.has(resource_id):
			parts.append("%s %s" % [_format_number(float(cost[resource_id])), str(resources[resource_id]["name"]).to_lower()])
	return " + ".join(parts)


func _format_number(value: float) -> String:
	if value >= 1000000000.0:
		return "%.2f Md" % (value / 1000000000.0)
	if value >= 1000000.0:
		return "%.2f M" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.2f k" % (value / 1000.0)
	if absf(value - roundf(value)) < 0.001:
		return str(int(roundf(value)))
	if value < 10.0:
		return "%.2f" % value
	return "%.1f" % value


func _add_activity(message: String, color: Color) -> void:
	var minutes := int(session_elapsed) / 60
	var seconds := int(session_elapsed) % 60
	var color_hex := color.to_html(false)
	activity_entries.push_front("[color=#6f7c9c]%02d:%02d[/color]  [color=#%s]%s[/color]" % [minutes, seconds, color_hex, message])
	if activity_entries.size() > 9:
		activity_entries.pop_back()
	if activity_log:
		activity_log.text = "\n\n".join(activity_entries)


func _prepare_click_button() -> void:
	main_click_button.pivot_offset = main_click_button.size * 0.5


func _on_dev_submit(_submitted_text: String) -> void:
	_give_dev_resource()


func _give_dev_resource() -> void:
	if not dev_amount.text.is_valid_float():
		dev_amount.placeholder_text = "Entrez un nombre valide"
		dev_amount.text = ""
		return
	var amount := dev_amount.text.to_float()
	if amount <= 0.0:
		dev_amount.placeholder_text = "Le montant doit être positif"
		dev_amount.text = ""
		return
	var resource_id := RESOURCE_ORDER[dev_resource.selected]
	_add_resource(resource_id, amount)
	_add_activity("Test : +%s %s" % [_format_number(amount), str(resources[resource_id]["name"]).to_lower()], COLORS.warning)
	dev_amount.text = ""
	dev_panel.visible = false
	_update_interface(false)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel(background: Color, border: Color, radius: int, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style_box(background, border, radius, 1, padding)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.2)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _style_box(background: Color, border: Color, radius: int, border_width: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


func _style_nav_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", COLORS.muted)
	button.add_theme_color_override("font_hover_color", COLORS.text)
	button.add_theme_color_override("font_pressed_color", COLORS.text)
	button.add_theme_stylebox_override("normal", _style_box(Color.TRANSPARENT, Color.TRANSPARENT, 10, 0, 8))
	button.add_theme_stylebox_override("hover", _style_box(Color("202b48"), Color("344564"), 10, 1, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("253a58"), COLORS.points, 10, 1, 8))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _style_action_button(button: Button, accent: Color, large := false) -> void:
	button.add_theme_font_size_override("font_size", 25 if large else 15)
	button.add_theme_color_override("font_color", Color("0c1425"))
	button.add_theme_color_override("font_hover_color", Color("08101f"))
	button.add_theme_color_override("font_pressed_color", Color("08101f"))
	button.add_theme_color_override("font_disabled_color", Color("75809a"))
	button.add_theme_stylebox_override("normal", _style_box(accent.darkened(0.08), accent.lightened(0.12), 18 if large else 12, 1, 12))
	button.add_theme_stylebox_override("hover", _style_box(accent.lightened(0.08), Color.WHITE, 18 if large else 12, 1, 12))
	button.add_theme_stylebox_override("pressed", _style_box(accent.darkened(0.18), accent, 18 if large else 12, 2, 12))
	button.add_theme_stylebox_override("disabled", _style_box(Color("222b43"), Color("37415b"), 18 if large else 12, 1, 12))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _style_upgrade_button(button: Button, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", COLORS.text)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("6f7a96"))
	button.add_theme_stylebox_override("normal", _style_box(Color("202a47"), accent.darkened(0.35), 12, 1, 14))
	button.add_theme_stylebox_override("hover", _style_box(Color("2a3758"), accent, 12, 2, 14))
	button.add_theme_stylebox_override("pressed", _style_box(Color("172039"), accent.lightened(0.15), 12, 2, 14))
	button.add_theme_stylebox_override("disabled", _style_box(Color("161e33"), Color("2b344b"), 12, 1, 14))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
