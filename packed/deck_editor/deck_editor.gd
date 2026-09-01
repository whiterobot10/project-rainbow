class_name DeckEditor
extends PanelContainer

var deck_builder_card := preload("res://prefab/card/card.tscn")

@onready var main_deck: DeckList = %MainDeckContainer
@onready var side_deck: DeckList = %SideDeckContainer
@onready var sideboard_deck: DeckList = %SideboardContainer
@onready var selected_deck: DeckList = main_deck

var selected_icon := "Squirrel.png"
## the [Variant] can be either [SideDeck] or [SideDeckCategory]
var side_deck_options: Array[Variant] = []
var category_options: Array[Ruleset.SideDeck] = []
var selected_category_name := ""
var selected_side_deck: Ruleset.SideDeck

var have_side_deck := true

const DECK_SCHEMA: Dictionary[String, Dictionary] = {
	name = {types = [TYPE_STRING], default = "New Decl"},
	ruleset = {types = [TYPE_STRING], default = "Missing Ruleset"},
	icon = {types = [TYPE_STRING], default = "Squirrel.png"},
	main = {types = [TYPE_DICTIONARY], key_type = TYPE_STRING, value_type = TYPE_INT},
	sideboard = {types = [TYPE_DICTIONARY], key_type = TYPE_STRING, value_type = TYPE_INT},
	side =
	{
		types = [TYPE_DICTIONARY],
		schema =
		{
			name = {types = [TYPE_STRING], default = ""},
			category = {types = [TYPE_STRING], default = ""},
			deck = {types = [TYPE_DICTIONARY], key_type = TYPE_STRING, value_type = TYPE_INT}
		}
	}
}

var _cost_filters: Dictionary[String, Callable] = {
	blood = func(c: Card) -> bool: return c.costs.blood > 0,
	bone = func(c: Card) -> bool: return c.costs.bone > 0,
	energy = func(c: Card) -> bool: return c.costs.energy > 0,
	cell = func(c: Card) -> bool: return c.costs.cell > 0,
	green = func(c: Card) -> bool: return c.costs.mox.green > 0,
	orange = func(c: Card) -> bool: return c.costs.mox.orange > 0,
	blue = func(c: Card) -> bool: return c.costs.mox.blue > 0,
}
var filters: Dictionary[String, Callable] = _cost_filters.duplicate()
var enabled_filters: Dictionary[FilterButton.FilterGroup, Array] = {
	FilterButton.FilterGroup.COST: [],
	FilterButton.FilterGroup.RARITY: [],
	FilterButton.FilterGroup.TRAIT: [],
	FilterButton.FilterGroup.TEMPLE: [],
	FilterButton.FilterGroup.TRIBE: []
}

var filters_btn: Array[FilterButton] = []


func _ready() -> void:
	Global.ruleset_changed.connect(_ruleset_changed)
	var btn_group := ButtonGroup.new()
	for portrait in DirAccess.get_files_at("res://asset/portraits/"):
		if not portrait.ends_with(".png"):
			continue
		var texture: Texture2D = load("res://asset/portraits/%s" % portrait)
		if texture.get_size() != Vector2(41, 28):
			continue
		var btn := Button.new()
		btn.icon = texture
		btn.button_group = btn_group
		btn.toggle_mode = true
		btn.theme_type_variation = "IconSelectButton"
		btn.name = portrait.trim_suffix(".png")
		btn.pressed.connect(_on_icon_selected.bind(texture, portrait))
		%DeckIconContainer.add_child(btn)


func load_deck(json: Dictionary) -> void:
	Global.validate_schema(json, DECK_SCHEMA)
	%DeckName.text = json.name
	%DeckNameEdit.text = json.name
	%DeckIcon.texture = load("res://asset/portraits".path_join(json.icon as String))
	selected_icon = json.icon
	for child: Button in %DeckIconContainer.get_children():
		if child.name == json.icon.trim_suffix(".png"):
			child.button_pressed = true
			break
	main_deck.clear()
	side_deck.clear()
	sideboard_deck.clear()
	# HACK: This dict help with type conversion cus godot fucking hate it bro
	var dict: Dictionary[String, int]
	dict.assign(json.main as Dictionary)
	main_deck.load_deck(dict)
	if have_side_deck:
		var raw_side: Variant = Global.ruleset.side_decks.get(json.side.name, null)
		var idx := side_deck_options.find(raw_side)
		if idx == -1:
			idx = 0
		%SideOption.select(idx)
		_on_side_option_item_selected(idx)
		if raw_side is Ruleset.SideDeckCategory:
			idx = category_options.find(raw_side.decks[json.side.category])
			if idx == -1:
				idx = 0
			%CatOption.select(idx)
			_on_cat_option_item_selected(idx)
		if selected_side_deck.type == Ruleset.SideDeck.Type.DRAFT:
			dict.assign(json.side.get("deck", {}) as Dictionary)
			for card_name: String in dict.keys():
				if card_name not in selected_side_deck.cards:
					dict.erase(card_name)
			side_deck.load_deck(dict)
		dict.assign(json.sideboard as Dictionary)
		sideboard_deck.load_deck(dict)
	_on_tab_container_tab_changed(0)
	_update_card_count()
	_update_card_list()


func _ruleset_changed(ruleset: Ruleset) -> void:
	Global.clear_children(%CardList)
	for card_data: Ruleset.CardData in ruleset.cards.values():
		var db_card: Card = deck_builder_card.instantiate()
		db_card.card_data = card_data
		db_card.is_db_card = true
		db_card.pressed.connect(_on_card_selected.bind(db_card))
		%CardList.add_child(db_card)
	_update_card_list()
	_update_filters_ui(ruleset)

	if ruleset.side_decks.is_empty():
		have_side_deck = false
		%DeckTabContainer.set_tab_disabled(1, true)
		%SideSizeLabel.visible = false
	else:
		%SideOption.clear()
		for deck: Variant in ruleset.side_decks.values():
			%SideOption.add_item(deck.display_name)
			side_deck_options.append(deck)
		selected_deck = side_deck
		_on_side_option_item_selected(0)
		%DeckTabContainer.tab_changed.emit(0)


func _update_card_list() -> void:
	%CardList.visible = false
	for card: Card in %CardList.get_children():
		if card.visible:
			%CardList.visible = true
			break
	%CardListLabel.visible = not %CardList.visible
	for card: Card in %CardList.get_children():
		if card.banned_overlay != null and card.banned_overlay.visible:
			%CardList.move_child(card, -1)


func _update_filters_ui(ruleset: Ruleset) -> void:
	# generate the new filter list
	filters.clear()
	filters_btn.clear()
	for group: Array in enabled_filters.values():
		group.clear()
	var containers: Array[GridContainer] = [
		%RarityFiltersContainer,
		%TraitFiltersContainer,
		%TempleFiltersContainer,
		%TribeFiltersContainer
	]
	for container in containers:
		Global.clear_children(container)
	filters = _cost_filters.duplicate()

	for rarity: Ruleset.Rarity in ruleset.rarities.values():
		filters[rarity.name] = func(c: Card) -> bool: return c.rarity == rarity
		%RarityFiltersContainer.add_child(
			_new_filter_btn(
				rarity.icon, rarity.display_name, rarity.name, FilterButton.FilterGroup.RARITY
			)
		)
	# trait is keyword so trait_ it is :(
	for trait_: Ruleset.Trait in ruleset.traits.values():
		filters[trait_.name] = func(c: Card) -> bool: return trait_ in c.traits
		%TraitFiltersContainer.add_child(
			_new_filter_btn(
				trait_.icon, trait_.display_name, trait_.name, FilterButton.FilterGroup.TRAIT
			)
		)

	for temple: Ruleset.Temple in ruleset.temples.values():
		filters[temple.name] = func(c: Card) -> bool: return c.temple == temple
		%TempleFiltersContainer.add_child(
			_new_filter_btn(
				temple.icon, temple.display_name, temple.name, FilterButton.FilterGroup.TEMPLE
			)
		)

	for tribe: Ruleset.Tribe in ruleset.tribes.values():
		filters[tribe.name] = func(c: Card) -> bool: return tribe in c.tribes
		%TribeFiltersContainer.add_child(
			_new_filter_btn(
				tribe.icon, tribe.display_name, tribe.name, FilterButton.FilterGroup.TRIBE
			)
		)


func _update_card_count() -> void:
	var main_size := Global.sum(main_deck.deck.values())
	var side_size := Global.sum(side_deck.deck.values())
	var main_size_min := Global.ruleset.settings.deck_size_min
	%MainSizeLabel.text = (
		"Main: %s%s%s/%s+ Cards"
		% [
			"[color=#82051e]" if main_size < main_size_min else "",
			main_size,
			"[/color]" if main_size < main_size_min else "",
			main_size_min
		]
	)
	if have_side_deck:
		%SideSizeLabel.text = (
			("Side: %s/%s Cards" % [side_size, selected_side_deck.max_size])
			if selected_side_deck.type == Ruleset.SideDeck.Type.DRAFT
			else ("Side: %s Cards" % side_size)
		)


func update_filters() -> void:
	for card: Card in %CardList.get_children():
		var name_keep: bool = (
			%NameFilter.text.is_empty() or %NameFilter.text.to_lower() in card.card_name.to_lower()
		)

		var apply_filter := func(f: String) -> bool: return filters[f].call(card)
		var identity := func(b: bool) -> bool: return b

		var filters_results := enabled_filters.values().map(
			func(fs: Array) -> bool:
				return true if fs.is_empty() else fs.map(apply_filter).any(identity)
		)

		card.visible = filters_results.all(identity) and name_keep
	_update_card_list()


func _new_filter_btn(
	icon: Texture2D,
	display_name: String,
	filter_name: String,
	filter_group: FilterButton.FilterGroup
) -> FilterButton:
	var btn := FilterButton.new()
	btn.icon = icon
	btn.text = display_name
	btn.filter_name = filter_name
	btn.filter_group = filter_group
	btn.deck_editor = self
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters_btn.append(btn)
	return btn


func _on_card_selected(card: Card) -> void:
	if selected_deck == side_deck:
		if (
			side_deck.deck.get(card.card_name, 0) >= card.rarity.max_side
			or Global.sum(side_deck.deck.values()) >= selected_side_deck.max_size
		):
			return
	else:
		if selected_deck.deck.get(card.card_name, 0) >= card.rarity.max_main:
			return
	_add_card(card.card_data)


func _add_card(card_data: Ruleset.CardData, manual := true) -> void:
	var rarity := Global.ruleset.rarities[card_data.rarity]
	var max_amount: int
	if selected_deck == side_deck:
		var side_size := Global.sum(side_deck.deck.values())
		max_amount = min(rarity.max_side, selected_side_deck.max_size - side_size)
	else:
		max_amount = rarity.max_main
	if not manual:
		max_amount = 1
	selected_deck.add_card(card_data, max_amount if Input.is_key_pressed(KEY_SHIFT) else 1)
	_update_card_count()


func _on_side_option_item_selected(index: int) -> void:
	# cleanse everything no matter what
	side_deck.clear()
	%CatOptContainer.visible = false
	%CatOption.clear()
	selected_category_name = ""
	for card: Card in %CardList.get_children():
		card.visible = false

	var option: Variant = side_deck_options[index]
	if option is Ruleset.SideDeck:
		selected_side_deck = option as Ruleset.SideDeck
		_process_side_deck()
		return

	var category := option as Ruleset.SideDeckCategory
	%CatOptContainer.visible = true
	for deck: Ruleset.SideDeck in category.decks.values():
		%CatOption.add_item(deck.display_name)
		category_options.append(deck)
	selected_category_name = category.name
	_on_cat_option_item_selected(0)


func _on_cat_option_item_selected(index: int) -> void:
	# cleanse everything no matter what
	side_deck.clear()
	selected_side_deck = category_options[index]
	for card: Card in %CardList.get_children():
		card.visible = false
	_process_side_deck()


func _process_side_deck() -> void:
	match selected_side_deck.type:
		Ruleset.SideDeck.Type.CONSTRUCTED:
			side_deck.allow_remove = false
			side_deck.load_deck(selected_side_deck.get_frequency())
		Ruleset.SideDeck.Type.DRAFT:
			side_deck.allow_remove = true
			for card: Card in %CardList.get_children():
				card.visible = true
				card.banned_overlay.visible = card.card_name not in selected_side_deck.cards
			_update_card_list()
	_update_card_count()


func _on_name_filter_text_changed(_new_text: String) -> void:
	update_filters()


func _on_tab_container_tab_changed(tab: int) -> void:
	for card: Card in %CardList.get_children():
		if tab == 1:
			if selected_side_deck.type == Ruleset.SideDeck.Type.CONSTRUCTED:
				card.visible = false
			else:
				card.visible = true
				card.banned_overlay.visible = card.card_name not in selected_side_deck.cards
		else:
			card.visible = true
			card.banned_overlay.visible = card.card_data.banned
	_update_card_list()
	_on_clear_filter_pressed()
	match tab:
		0:
			selected_deck = main_deck
		1:
			selected_deck = side_deck
		2:
			selected_deck = sideboard_deck


func _on_clear_filter_pressed() -> void:
	for group: Array in enabled_filters.values():
		group.clear()
	for btn in filters_btn:
		btn.button_pressed = false
		btn._on_toggled(false)
	for btn in %CostsFiltersContainer.get_children():
		if btn is not FilterButton:
			continue
		btn.button_pressed = false
		btn._on_toggled(false)


func _on_icon_selected(texture: Texture2D, icon_name: String) -> void:
	selected_icon = icon_name
	%DeckIcon.texture = texture


func _on_deck_name_changed(new_text: String) -> void:
	%DeckName.text = new_text


func _on_save_exit_btn_pressed() -> void:
	var deck_json := {
		ruleset = Global.ruleset.name,
		name = %DeckName.text,
		icon = selected_icon,
		main = main_deck.deck,
		sideboard = sideboard_deck.deck
	}
	var side := {}

	if have_side_deck:
		side = {name = selected_side_deck.name}
		match selected_side_deck.type:
			Ruleset.SideDeck.Type.CONSTRUCTED:
				pass
			Ruleset.SideDeck.Type.DRAFT:
				side.deck = side_deck.deck
			_:
				push_warning("This side deck type does not support saving")
		if not selected_category_name.is_empty():
			side.name = selected_category_name
			side.category = selected_side_deck.name
	deck_json.side = side
	var file := FileAccess.open(
		Global.decks_path.path_join("%s.json" % %DeckName.text), FileAccess.WRITE
	)
	file.store_string(JSON.stringify(deck_json))
	file.close()
	visible = false
