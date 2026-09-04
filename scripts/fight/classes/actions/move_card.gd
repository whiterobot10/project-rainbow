class_name MoveCardAction
extends Action

var card_id: String
var pos: Vector2i


static func action_type() -> Type:
	return Type.MOVE_CARD


func _init(cid: String, p: Vector2i) -> void:
	card_id = cid
	pos = p


func resolve(fight_manager: FightManager) -> void:
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	if card.zone != Card.Zone.BOARD:
		push_warning("Cannot move card that isn't on the board. Try using play card instead")
		fight_manager._no_activation()
		return
	var from_slot := fight_manager.board_manager.get_slot_with_card(card_id)
	var to_slot := fight_manager.board_manager.get_slot(pos)
	if to_slot.card != null:
		push_warning("Cannot move card into non-empty slot.")
		fight_manager._no_activation()
		return
	from_slot.card = null
	to_slot.card = card
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_card_moved(card, from_slot, to_slot)
	)


func as_dict() -> Dictionary:
	return {type = action_type(), card_id = card_id, pos = {x = pos.x, y = pos.y}}


static func from_dict(dict: Dictionary) -> Action:
	return MoveCardAction.new(
		dict.card_id as String, Vector2i(dict.pos.x as int, dict.pos.y as int)
	)
