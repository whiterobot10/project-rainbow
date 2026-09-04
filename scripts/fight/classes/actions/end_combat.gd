class_name EndCombatAction
extends Action

var player_id: String


static func action_type() -> Type:
	return Type.COMBAT


func _init(pid: String) -> void:
	player_id = pid


func resolve(fight_manager: FightManager) -> void:
	fight_manager.in_combat = false
	await fight_manager._activate_hooks(func(hook: ActionHook) -> void: hook.on_combat_end())


func as_dict() -> Dictionary:
	return {type = action_type(), player_id = player_id}


static func from_dict(dict: Dictionary) -> Action:
	return CombatAction.new(dict.player_id as String)
