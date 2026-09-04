class_name TipScaleAction
extends Action

## The amount to tip the scale by. Positive mean to me and negative to them
var amount: int


static func action_type() -> Type:
	return Type.TIP_SCALE


func _init(a: int) -> void:
	amount = a


func resolve(fight_manager: FightManager) -> void:
	if amount == 0:
		return
	fight_manager.scale_position += amount
	if fight_manager.scale_position <= -5:
		fight_manager.lose_game()
	await fight_manager._activate_hooks(func(hook: ActionHook) -> void: hook.on_scale_tipped(amount))


func as_dict() -> Dictionary:
	return {type = action_type(), amount = amount}


static func from_dict(dict: Dictionary) -> Action:
	return TipScaleAction.new(dict.amount as int)
