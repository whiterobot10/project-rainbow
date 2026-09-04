@abstract class_name SpecialAttack
extends ActionHook

## The fight manager that is current "active".
## Just a reference to the fightmanager so you can access like the board, hand,
## play card and general utils offer by the fight manager.
var fight_manager: FightManager
## The card this sigil is attached to.
var attached_card: Card

@abstract func attack_value() -> int


func active_in_hand() -> bool:
	return false


func _should_be_active() -> bool:
	return (
		attached_card.zone == Card.Zone.BOARD
		or (attached_card.zone == Card.Zone.HAND and active_in_hand())
	)


## Can return [code]""[/code] (empty string) if the card is not on the board
func controller_id(pos := Vector2i.MIN) -> String:
	if pos == Vector2i.MIN:
		if attached_card.zone != Card.Zone.BOARD:
			return ""
		pos = fight_manager.board_manager.get_card_pos(attached_card.id)
	return (Global.uuid as String) if pos.y == BoardManager.Row.MINE else fight_manager.opp_id


## Get the positon of the card on the board. [param card_id] default to [member attached_card]'s id
func get_pos(card_id := "") -> Vector2i:
	if card_id.is_empty():
		card_id = attached_card.id
	return fight_manager.board_manager.get_card_pos(card_id)


func oppose_pos(pos: Vector2i) -> Vector2i:
	return BoardManager.oppose_pos(pos)


func get_config(config_name: String, default: Variant) -> Variant:
	var config: Variant = attached_card.card_data.metadata.get(config_name)
	if typeof(config) != typeof(default):
		return default
	return config
