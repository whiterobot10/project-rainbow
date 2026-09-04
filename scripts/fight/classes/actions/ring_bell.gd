class_name RingBellAction
extends Action

## The player that rung the bell.
var player_id: String


static func action_type() -> Type:
	return Type.RING_BELL


func _init(pid: String) -> void:
	player_id = pid


func resolve(fight_manager: FightManager) -> void:
	fight_manager._push_action(EndTurnAction.new(player_id))
	fight_manager._push_action(CombatAction.new(player_id))
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_bell_rung(player_id)
	)


func as_dict() -> Dictionary:
	return {type = action_type(), player_id = player_id}


static func from_dict(dict: Dictionary) -> Action:
	return RingBellAction.new(dict.player_id as String)
