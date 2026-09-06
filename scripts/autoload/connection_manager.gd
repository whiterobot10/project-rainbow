extends Node
## This class take care of handling the network for you <3.
## Don't socket request and what not manually instead use this

## Signal that fires when the room creation request is fullfilled by the sever, `room_code` is the
## code assigned by the server
signal room_created(room_code: String)
## Signal thta fires when the room is joined
signal room_joined(players: Array, host_uuid: String)
signal room_closed

signal client_connected(uuid: String)
signal player_joined(player: Player)

signal player_left(uuid: String)
signal recieved_packet(packet: Dictionary)

enum ErrCode { ROOM_NOT_FOUND }

# Packet type to send to the server
const CREATE_ROOM = "create_room"
const JOIN_ROOM = "join_room"
const CLOSE_ROOM = "close_room"
const LEAVE_ROOM = "leave_room"

# Packet type recieved from the server
const ROOM_CREATED = "room_created"
const ROOM_JOINED = "room_joined"
const ROOM_CLOSED = "room_closed"

const PLAYER_LEFT = "player_left"
const PLAYER_JOIN = "player_join"

const CLIENT_CONNECTED = "client_connected"

const ERR = "error"

enum GameMessage { START_GAME, NEW_CARD, ACTIONS, REPLACEMENTS, TARGET_ACQUIRED }

var last_packet: Dictionary
var socket := WebSocketPeer.new()
var room_code: String
var is_host := false

var _already_close_loading := false


class Player:
	var name: String
	var pfp: String
	var uuid: String

	@warning_ignore("untyped_declaration")
	func _init(n: String, p: String, u: String):
		name = n
		pfp = p
		uuid = u

	static func from_packet(packet: Array) -> Array[Player]:
		var out: Array[Player] = []
		for p: Dictionary in packet:
			out.push_back(Player.new(p.name as String, p.pfp as String, p.uuid as String))

		return out


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	socket.connect_to_url("ws://127.0.0.1:42069")


func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_CONNECTING:
			Global.show_loading("Connecting to server...")
	if state == WebSocketPeer.STATE_OPEN:
		if not _already_close_loading:
			Global.hide_popup()
			_already_close_loading = true
		while socket.get_available_packet_count():
			var packet: Dictionary = JSON.parse_string(socket.get_packet().get_string_from_ascii())
			_handle_packet(packet)
			last_packet = packet
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code := socket.get_close_code()
		var reason := socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		(
			Global
			. show_error(
				"Can't connect to server.\nThe server could be down or your internet is broken.\nTry Restarting?"
			)
		)
		set_process(false)  # Stop processing.


func _handle_packet(packet: Dictionary) -> void:
	if typeof(packet.type) == TYPE_STRING:
		if packet.type == CLIENT_CONNECTED:
			Global.uuid = packet.uuid
			client_connected.emit(packet.uuid)
		elif packet.type == ROOM_CREATED:
			room_code = packet.room_code
			room_created.emit(room_code)
		elif packet.type == ROOM_JOINED:
			room_joined.emit(Player.from_packet(packet.players as Array), packet.host_uuid)
		elif packet.type == ROOM_CLOSED:
			room_closed.emit()
		elif packet.type == PLAYER_LEFT:
			player_left.emit(packet.player_uuid)
		elif packet.type == PLAYER_JOIN:
			var player: Dictionary = packet.player
			player_joined.emit(
				Player.new(player.name as String, player.pfp as String, player.uuid as String)
			)
		return
	recieved_packet.emit(packet)


func create_room() -> String:
	send(CREATE_ROOM, {name = Global.player_name, pfp = Global.pfp})
	is_host = true
	await room_created
	return room_code


func join_room(code: String) -> void:
	if code == room_code:
		return
	is_host = false
	room_code = code
	send(JOIN_ROOM, {room_code = code, name = Global.player_name, pfp = Global.pfp})


func close_room() -> void:
	send(CLOSE_ROOM)
	is_host = false


func leave_room() -> void:
	send(LEAVE_ROOM)
	room_code = ""


func send(type: Variant, data := {}) -> void:
	data.type = type
	socket.send_text(JSON.stringify(data))
