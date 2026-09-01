extends PanelContainer

@export var DECK_EDITOR: Control

var deck_listing := preload("res://prefab/deck_listing/deck_listing.tscn")
var selected_listing: DeckListing


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.ruleset_changed.connect(_on_ruleset_changed)
	var watcher := DirectoryWatcher.new()
	watcher.add_scan_directory("user://decks")
	watcher.scan_delay = 1
	watcher.files_created.connect(_fs_changed)
	watcher.files_deleted.connect(_fs_changed)
	watcher.files_modified.connect(_fs_changed)
	add_child(watcher)


func _fs_changed(_files: PackedStringArray) -> void:
	_on_ruleset_changed(Global.ruleset)


func _on_ruleset_changed(_ruleset: Ruleset) -> void:
	if Global.ruleset == null:
		return
	Global.clear_children(%DeckListingContainer)
	for file_name in DirAccess.get_files_at(Global.decks_path):
		if not file_name.ends_with(".json"):
			continue
		var file := FileAccess.open(Global.decks_path.path_join(file_name), FileAccess.READ)
		var dict: Variant = JSON.parse_string(file.get_as_text())
		if dict != null:
			_add_deck(dict as Dictionary)
		file.close()


func _add_deck(deck_dict: Dictionary) -> void:
	Global.validate_schema(deck_dict, DeckEditor.DECK_SCHEMA)
	var listing: DeckListing = deck_listing.instantiate()
	listing.deck_dict = deck_dict

	listing.deck_name = deck_dict.name
	listing.deck_icon = load("res://asset/portraits".path_join(deck_dict.icon as String))
	if deck_dict.ruleset != Global.ruleset.name:
		listing.wrong_ruleset = true
	else:
		listing.main.assign(deck_dict.main as Dictionary)
		if Global.ruleset.side_decks.is_empty():
			%SideDeckTitle.visible = false
			%SideDeckList.visible = false
		else:
			%SideDeckTitle.visible = true
			%SideDeckList.visible = true
			var raw_side: Variant = Global.ruleset.side_decks.get(deck_dict.side.name, null)
			if raw_side == null:
				raw_side = Global.ruleset.side_decks.values()[0]
			var side_deck: Ruleset.SideDeck
			if raw_side is Ruleset.SideDeckCategory:
				side_deck = (raw_side as Ruleset.SideDeckCategory).decks[deck_dict.side.category]
			else:
				side_deck = raw_side
			match side_deck.type:
				Ruleset.SideDeck.Type.CONSTRUCTED:
					listing.side.assign(side_deck.get_frequency())
				Ruleset.SideDeck.Type.DRAFT:
					listing.side.assign(deck_dict.side.deck as Dictionary)
					listing.is_side_draft = true
					listing.side_max = side_deck.max_size
		listing.sideboard.assign(deck_dict.sideboard as Dictionary)

	listing.mouse_entered.connect(_on_listing_hovered.bind(listing))
	listing.pressed.connect(_on_listing_pressed.bind(listing))

	listing.on_duplicated.connect(_fs_changed.bind([]))
	listing.on_copied.connect(_fs_changed.bind([]))
	listing.on_deleted.connect(_fs_changed.bind([]))
	%DeckListingContainer.add_child(listing)


func _on_listing_hovered(listing: DeckListing) -> void:
	if listing.wrong_ruleset:
		%DeckList.visible = false
		%WrongRulesetLabel.visible = true
		%WrongRulesetLabel.text = (
			"This deck was created using %s, but you have %s loaded. Loading this deck could cause problems."
			% [listing.deck_dict.ruleset, Global.ruleset.name]
		)
		return

	%DeckList.visible = true
	%WrongRulesetLabel.visible = false

	var decks: Dictionary[DeckList, Dictionary] = {
		%MainDeckList: listing.main, %SideDeckList: listing.side, %SideboardList: listing.sideboard
	}

	for deck in decks:
		deck.clear()
		deck.load_deck(decks[deck])
		if deck.get_child_count() <= 0:
			var label := Label.new()
			label.text = "-- EMPTY --"
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			deck.add_child(label)


func _on_listing_pressed(listing: DeckListing) -> void:
	if listing.wrong_ruleset:
		%WrongWarninglabel.text = (
			"This deck was created using %s, but you have %s loaded. Loading this deck could cause problems. If you still want to load and edit this deck, please make a backup"
			% [listing.deck_dict.ruleset, Global.ruleset.name]
		)
		$PopupBlocker.visible = true
		selected_listing = listing
		return

	DECK_EDITOR.visible = true
	DECK_EDITOR.load_deck(listing.deck_dict)


func _on_bk_btn_pressed() -> void:
	var og_deck := FileAccess.open(
		Global.decks_path.path_join("%s.json" % selected_listing.deck_name), FileAccess.WRITE_READ
	)
	var bk_deck := FileAccess.open(
		Global.decks_path.path_join("%s Backup.json" % selected_listing.deck_name), FileAccess.WRITE
	)
	var bk_data := selected_listing.deck_dict.duplicate_deep()
	bk_data.name = "%s Backup" % selected_listing.deck_name
	bk_deck.store_string(JSON.stringify(bk_data))
	bk_deck.close()
	selected_listing.deck_dict.ruleset = Global.ruleset.name
	og_deck.store_string(JSON.stringify(selected_listing.deck_dict))
	og_deck.close()
	_on_load_btn_pressed()


func _on_load_btn_pressed() -> void:
	DECK_EDITOR.visible = true
	DECK_EDITOR.load_deck(selected_listing.deck_dict)
	$PopupBlocker.visible = false


func _on_cancel_btn_pressed() -> void:
	$PopupBlocker.visible = false


func _on_add_deck_btn_pressed() -> void:
	var side_dict := {}
	if not Global.ruleset.side_decks.is_empty():
		var side_deck: Variant = Global.ruleset.side_decks.values()[0]
		if side_deck is Ruleset.SideDeckCategory:
			side_dict.name = side_deck.name
			side_deck = side_deck.decks.values()[0]
			side_dict.category = side_deck.name
		else:
			side_dict.name = side_deck.name

		if side_deck.type == Ruleset.SideDeck.Type.DRAFT:
			side_dict.deck = {}

	DECK_EDITOR.load_deck(
		{
			name = "New Deck",
			icon = "Squirrel.png",
			main = {},
			ruleset = Global.ruleset.name,
			side = side_dict,
			sideboard = {}
		}
	)
	DECK_EDITOR.visible = true


func _on_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var dict: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if dict == null:
		Global.show_error("Deck can't be loaded due to invalid json")
		return
	Global.validate_schema(dict as Dictionary, DeckEditor.DECK_SCHEMA)
	var deck_file := FileAccess.open(
		Global.decks_path.path_join(dict.name as String + ".json"), FileAccess.WRITE
	)
	var deck_dict := JSON.stringify(dict)
	deck_file.store_string(deck_dict)
