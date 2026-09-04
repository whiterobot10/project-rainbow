class_name TransformCardAction
extends Action

var card_id: String
var card_data: Ruleset.CardData


static func action_type() -> Type:
	return Type.TRANSFORM_CARD


func _init(cid: String, cd: Ruleset.CardData) -> void:
	card_id = cid
	card_data = cd


func resolve(fight_manager: FightManager) -> void:
	var card := fight_manager.card_manager.get_card_by_id(card_id)
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void: hook.on_card_transformed(card, card_data)
	)
	var damage_taken := card.card_data.health as int - card.health
	card.card_data = card_data
	card.health -= damage_taken


func as_dict() -> Dictionary:
	return {type = action_type(), card_id = card_id, card_data = card_data}


static func from_dict(dict: Dictionary) -> Action:
	return TransformCardAction.new(dict.card_id as String, dict.card_data as Ruleset.CardData)
