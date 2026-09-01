extends PanelContainer

@export var FIGHT: Control

var code: String
var players: Dictionary[String, ConnectionManager.Player]
var host_uuid: String

var player_listing := preload("res://prefab/player_listing/player_listing.tscn")

var deck_options: Array[Dictionary] = []


func _ready() -> void:
	ConnectionManager.room_created.connect(_on_room_created)
	ConnectionManager.room_joined.connect(_on_room_joined)
	ConnectionManager.player_joined.connect(_on_player_joined)
	ConnectionManager.player_left.connect(_on_player_left)
	ConnectionManager.room_closed.connect(_on_room_closed)
	ConnectionManager.recieved_packet.connect(_on_packet_recieved)


func add_player(player: ConnectionManager.Player) -> void:
	players[player.uuid] = player
	var listing: PlayerListing = player_listing.instantiate()
	listing.player_name = player.name
	listing.pfp = player.pfp
	listing.is_host = player.uuid == host_uuid
	listing.name = player.uuid
	%PlayerList.add_child(listing)
	if player.uuid == host_uuid:
		%PlayerList.move_child(listing, 1)  # not zero because of the heading


func _on_room_created(room_code: String) -> void:
	code = room_code
	Global.is_host = true
	host_uuid = Global.uuid
	add_player(ConnectionManager.Player.new(Global.player_name, Global.pfp, Global.uuid))
	_load_deck_option()


func _on_room_joined(players_: Array[ConnectionManager.Player], host_uuid_: String) -> void:
	host_uuid = host_uuid_
	for player in players_:
		add_player(player)
	add_player(ConnectionManager.Player.new(Global.player_name, Global.pfp, Global.uuid))
	_load_deck_option()


func _on_room_closed() -> void:
	for n in %PlayerList.get_children():
		%PlayerList.remove_child(n)
		n.queue_free()
	visible = false


func _on_player_joined(player: ConnectionManager.Player) -> void:
	add_player(player)


func _on_player_left(uuid: String) -> void:
	players.erase(uuid)
	for listing in %PlayerList.get_children():
		if listing.name == uuid:
			%PlayerList.remove_child(listing)
			listing.queue_free()


func _on_room_code_pressed() -> void:
	if %RoomCode.text != code:
		%RoomCode.text = code
	else:
		%RoomCode.text = "VIEW CODE"


func _on_copy_code_btn_pressed() -> void:
	DisplayServer.clipboard_set(code)


func _on_end_btn_pressed() -> void:
	visible = false
	if ConnectionManager.is_host:
		ConnectionManager.close_room()
		_on_room_closed()
	else:
		ConnectionManager.leave_room()
		_on_room_closed()


func _on_start_btn_pressed() -> void:
	if Global.is_host:
		var starting_player := 0
		ConnectionManager.send(ConnectionManager.GameMessage.START_GAME, {start = starting_player})
		visible = false
		FIGHT.is_active = starting_player == 0
		# HACK: Janky rn fix it when spectator or multiple player is implemented
		FIGHT.opp_id = players.keys().filter(func(s: String) -> bool: return s != Global.uuid)[0]
		FIGHT._start_fight(deck_options[%DeckOption.get_selected_id()])


func _on_packet_recieved(packet: Dictionary) -> void:
	if packet.type != ConnectionManager.GameMessage.START_GAME:
		return

	visible = false
	FIGHT.is_active = 1 - packet.start == 0
	# HACK: Janky rn fix it when spectator or multiple player is implemented
	FIGHT.opp_id = players.keys().filter(func(s: String) -> bool: return s != Global.uuid)[0]

	FIGHT._start_fight(deck_options[%DeckOption.get_selected_id()])


func _load_deck_option() -> void:
	%DeckOption.clear()
	for deck_file_name in DirAccess.get_files_at(Global.decks_path):
		if not deck_file_name.ends_with(".json"):
			continue
		var file := FileAccess.open(Global.decks_path.path_join(deck_file_name), FileAccess.READ)
		var res: Variant = JSON.parse_string(file.get_as_text())
		if res == null:
			continue
		var deck_dict := res as Dictionary
		Global.validate_schema(deck_dict, DeckEditor.DECK_SCHEMA)
		%DeckOption.add_icon_item(
			load("res://asset/portraits".path_join(deck_dict.icon as String)), deck_dict.name
		)
		deck_options.append(deck_dict)
