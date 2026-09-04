class_name PreCardStrikeAction
extends Action

var striker_id: String
var pos: Vector2i
## Wherever this will strike directly to face disregarding everything
var to_face: bool


static func action_type() -> Type:
	return Type.PRE_CARD_STRIKE


func _init(sid: String, p: Vector2i, tf := false) -> void:
	striker_id = sid
	pos = p
	to_face = tf


func resolve(fight_manager: FightManager) -> void:
	var striker := fight_manager.card_manager.get_card_by_id(striker_id)
	var victim_slot := fight_manager.board_manager.get_slot(pos)
	if victim_slot == null:
		push_warning("Nuh uh no striking into non-existence slot >:(")
		fight_manager._no_activation()
		return
	if striker.attack == 0:
		fight_manager._no_activation()
		return
	fight_manager._push_action(CardStrikeAction.new(striker_id, pos, to_face))
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: return hook.pre_card_strike(striker, victim_slot, to_face)
	)


func as_dict() -> Dictionary:
	return {
		type = action_type(),
		pos = {x = pos.x, y = pos.y},
		striker_id = striker_id,
		to_face = to_face
	}


static func from_dict(dict: Dictionary) -> Action:
	return CardStrikeAction.new(
		dict.striker_id as String,
		Vector2i(dict.pos.x as int, dict.pos.y as int),
		dict.to_face as int
	)
