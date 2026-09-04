class_name CombatAction
extends Action

var player_id: String


static func action_type() -> Type:
	return Type.COMBAT


func _init(pid: String) -> void:
	player_id = pid


func resolve(fight_manager: FightManager) -> void:
	fight_manager.in_combat = true
	await fight_manager._activate_hooks(func(hook: ActionHook) -> void: hook.on_combat_start())
	fight_manager._push_action(EndCombatAction.new(player_id))
	var t := fight_manager.board_manager.get_active_row(player_id == Global.uuid)
	t.reverse()
	for slot in t:
		if slot.card != null:
			fight_manager._push_action(CardAttackAction.new(slot.card.id))


func as_dict() -> Dictionary:
	return {type = action_type(), player_id = player_id}


static func from_dict(dict: Dictionary) -> Action:
	return CombatAction.new(dict.player_id as String)
