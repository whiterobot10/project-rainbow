class_name DamageCard
extends Action

var victim_id: String
var amount: int
var attacker_type: IDType
var attacker_id: String


static func action_type() -> Type:
	return Type.DAMAGE_CARD


func _init(vid: String, a: int, at: IDType, aid: String) -> void:
	amount = a
	victim_id = vid
	attacker_type = at
	attacker_id = aid


func resolve(fight_manager: FightManager) -> void:
	var victim := fight_manager.card_manager.get_card_by_id(victim_id)
	victim.health -= amount
	await fight_manager._activate_hooks(
		func(hook: ActionHook) -> void:
			hook.on_card_damaged(victim, amount, attacker_type, attacker_id)
	)
	if victim.health <= 0:
		fight_manager._push_action(KillCardAction.new(victim_id))


func as_dict() -> Dictionary:
	return {
		type = action_type(),
		victim_id = victim_id,
		amount = amount,
		attacker_type = attacker_type,
		attacker_id = attacker_id
	}


static func from_dict(dict: Dictionary) -> Action:
	return DamageCard.new(
		dict.victim_id as String,
		dict.amount as int,
		dict.attack_type as IDType,
		dict.attacker_id as String
	)
