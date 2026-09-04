class_name RefreshEnergyAction
extends Action

var player_id: String


static func action_type() -> Type:
	return Type.REFRESH_ENERGY


func _init(pid: String) -> void:
	player_id = pid


func resolve(fight_manager: FightManager) -> void:
	var data := fight_manager.get_data(player_id)
	data.energy = data.cells
	await fight_manager._activate_hooks(func(hook: ActionHook) -> void: hook.on_energy_refresh(player_id))


func as_dict() -> Dictionary:
	return {type = action_type(), player_id = player_id}


static func from_dict(dict: Dictionary) -> Action:
	return RefreshEnergyAction.new(dict.player_id as String)
