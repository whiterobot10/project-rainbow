class_name ActivateSigilAction
extends Action

## The card to activate the sigil on
var card_id: String
## The sigil index in the card sigil list to activate
var sigil_idx: int
var source_id: String
var source_type: Action.IDType


static func action_type() -> Type:
	return Type.ACTIVATE_SIGILS


func _init(cid: String, sidx: int, sid: String, st: Action.IDType) -> void:
	card_id = cid
	sigil_idx = sidx
	source_id = sid
	source_type = st


func resolve(fight_manager: FightManager) -> void:
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	if card == null:
		push_warning("Can't activate sigil on non-existence card")
		return
	var active_sigil: Sigil = card._sigils.get(sigil_idx)
	if active_sigil == null:
		push_warning("Can't activate out of bound sigil on card")
		return
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void:
			hook.on_sigil_activate(card, active_sigil, source_id, source_type)
	)


func as_dict() -> Dictionary:
	return {
		type = action_type(),
		card_id = card_id,
		sigil_idx = sigil_idx,
		source_id = source_id,
		source_type = source_type
	}


static func from_dict(dict: Dictionary) -> Action:
	return ActivateSigilAction.new(
		dict.card_id as String,
		dict.sigil_idx as int,
		dict.source_id as String,
		dict.source_type as Action.IDType
	)
