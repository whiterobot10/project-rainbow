class_name ChangeEnergyAction
extends Action

var amount: int
var player_id: String


static func action_type() -> Type:
	return Action.Type.CHANGE_ENERGY


func _init(a: int, pid: String) -> void:
	amount = a
	player_id = pid


func resolve(fight_manager: FightManager) -> void:
	var data := fight_manager.get_data(player_id)
	data.energy += amount
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_energy_changed(amount, player_id)
	)


func as_dict() -> Dictionary:
	return {type = action_type(), amount = amount, player_id = player_id}


static func from_dict(dict: Dictionary) -> Action:
	return ChangeEnergyAction.new(dict.amount as int, dict.player_id as String)
