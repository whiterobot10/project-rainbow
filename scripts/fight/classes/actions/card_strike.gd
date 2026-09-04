class_name CardStrikeAction
extends Action

var striker_id: String
var pos: Vector2i
## Wherever this will strike directly to face disregarding everything
var to_face: bool


static func action_type() -> Type:
	return Type.CARD_STRIKE


func _init(sid: String, p: Vector2i, tf := false) -> void:
	striker_id = sid
	pos = p
	to_face = tf


func resolve(fight_manager: FightManager) -> void:
	var striker := fight_manager.card_manager.get_card_by_id(striker_id)
	if striker == null:
		return
	var victim_slot := fight_manager.board_manager.get_slot(pos)
	if victim_slot == null:
		push_warning("Nuh uh no striking into non-existence slot >:(")
		fight_manager._no_activation()
		return
	if striker.attack == 0:
		fight_manager._no_activation()
		return
	if victim_slot.is_empty() or to_face:
		fight_manager._push_action(
			TipScaleAction.new(
				striker.attack * (-1 if victim_slot.pos.y == BoardManager.Row.MINE else 1)
			)
		)
	else:
		fight_manager._push_action(
			DamageCard.new(victim_slot.card.id, striker.attack, IDType.CARD, striker.id)
		)
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_card_strike(striker, pos, to_face)
	)


func as_dict() -> Dictionary:
	return {
		type = action_type(),
		striker_id = striker_id,
		pos = {x = pos.x, y = pos.y},
		to_face = to_face
	}


static func from_dict(dict: Dictionary) -> Action:
	return CardStrikeAction.new(
		dict.striker_id as String,
		Vector2i(dict.pos.x as int, dict.pos.y as int),
		dict.to_face as int
	)
