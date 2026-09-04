class_name SacrificeCardAction
extends Action

var card_id: String


static func action_type() -> Type:
	return Action.Type.SACRIFICE_CARD


func _init(cid: String) -> void:
	card_id = cid


func resolve(fight_manager: FightManager) -> void:
	fight_manager._push_action(KillCardAction.new(card_id))
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	await fight_manager._activate_hooks(func(hook: ActionHook) -> void: hook.on_card_sacrificed(card))


func as_dict() -> Dictionary:
	return {type = action_type(), card_id = card_id}


static func from_dict(dict: Dictionary) -> Action:
	return SacrificeCardAction.new(dict.card_id as String)
