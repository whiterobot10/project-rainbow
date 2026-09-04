class_name ChangeCellsAction
extends Action

var amount: int
var player_id: String
var give_energy: bool


static func action_type() -> Type:
	return Action.Type.CHANGE_CELLS


func _init(a: int, pid: String, ge: bool = true) -> void:
	amount = a
	player_id = pid
	give_energy = ge


func resolve(fight_manager: FightManager) -> void:
	var data := fight_manager.get_data(player_id)
	data.cells += amount
	if give_energy:
		data.energy = min(data.energy + amount, data.cells)
	await fight_manager._activate_sigils(
		func(hook: ActionHook) -> void: hook.on_cell_changed(amount, player_id)
	)


func as_dict() -> Dictionary:
	return {type = action_type(), amount = amount, player_id = player_id, give_energy = give_energy}


static func from_dict(dict: Dictionary) -> Action:
	return ChangeCellsAction.new(dict.amount as int, dict.player_id as String, dict.give_energy as bool)
