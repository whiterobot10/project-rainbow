class_name StartTurnAction
extends Action

var player_id: String


static func action_type() -> Type:
	return Type.START_TURN


func _init(pid: String) -> void:
	player_id = pid


func resolve(fight_manager: FightManager) -> void:
	fight_manager.is_active = Global.uuid == player_id
	fight_manager._push_action(RefreshEnergyAction.new(fight_manager.active_id()))
	fight_manager._push_action(ChangeCellsAction.new(1, fight_manager.active_id()))
	await fight_manager._activate_hooks(func(hook: ActionHook) -> void: hook.on_turn_start(player_id))


func as_dict() -> Dictionary:
	return {type = action_type(), player_id = player_id}


static func from_dict(dict: Dictionary) -> Action:
	return EndTurnAction.new(dict.player_id as String)
