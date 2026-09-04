class_name CardsManager
extends Control

@onready var fight_manager: FightManager = $".."

const CARD_PREFAB: PackedScene = preload("res://prefab/card/card.tscn")

var _cards: Dictionary[String, Card]

signal card_changed_zone(card: Card, from: Card.Zone, to: Card.Zone)


func _ready() -> void:
	ConnectionManager.recieved_packet.connect(_on_recieved_packet)


func _on_recieved_packet(packet: Dictionary) -> void:
	if packet.type != ConnectionManager.GameMessage.NEW_CARD or packet.card.id in _cards:
		return

	add_card(
		Ruleset.CardData.new(packet.card.data as Dictionary),
		packet.card.zone as int,
		packet.card.id as String
	)


func add_card(card_data: Ruleset.CardData, zone: Card.Zone, id := "") -> Card:
	var card: Card = CARD_PREFAB.instantiate()
	add_child(card)
	card.card_data = card_data
	if not id.is_empty():
		card.id = id
	for sigil_idx: int in len(card._sigils):
		var sigil := card._sigils[sigil_idx]
		sigil.fight_manager = fight_manager
	if card._special_attack != null:
		card._special_attack.fight_manager = fight_manager
	card.active_pressed.connect(
		func(sigil_idx: int) -> void: fight_manager._on_active_pressed(card, sigil_idx)
	)
	_cards[card.id] = card
	move_card(card.id, zone)
	return card


func move_card(card_id: String, zone: Card.Zone) -> void:
	var card := get_card_by_id(card_id)
	var from := card.zone
	card.zone = zone
	card_changed_zone.emit(card, from, zone)
	if from == zone:
		return
	if zone in Card.PUBLIC_ZONE:
		ConnectionManager.send(ConnectionManager.GameMessage.NEW_CARD, {card = card.as_dict()})


func sync_id() -> void:
	var t: Dictionary[String, Card] = {}
	for card: Card in get_children():
		t[card.id] = card
	_cards = t


## May return [code]null[/code] is the card does not exist
func get_card_by_id(id: String) -> Card:
	if id not in _cards:
		return null
	var card := _cards[id]
	return card


func get_cards_by_zone(zone: Card.Zone) -> Array[Card]:
	var out: Array[Card] = []
	for child: Card in get_children():
		if child.zone == zone:
			out.append(child)
	return out


func clean_card() -> void:
	for card_id in _cards:
		if _cards[card_id].zone == Card.Zone.LIMBO:
			remove_child(_cards[card_id])
			_cards[card_id].queue_free()
			_cards.erase(card_id)


func _on_fight_stack_resolved() -> void:
	clean_card()
