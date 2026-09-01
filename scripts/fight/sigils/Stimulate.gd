extends Sigil


func energy_cost() -> int:
	return get_config("stimulate_energy_cost", 3)


func attack_buff() -> int:
	return get_config("stimulate_attack_buff", 1)


func health_buff() -> int:
	return get_config("stimulate_health_buff", 1)


func is_active_sigil() -> bool:
	return true


func is_disable() -> bool:
	return fight_manager.my_data.energy < energy_cost()


func on_sigil_activate(
	card: Card, sigil: Sigil, _source_id: String, _source_type: Action.IDType
) -> void:
	if card != attached_card or sigil != self:
		return

	add_action(ChangeEnergyAction.new(-energy_cost(), controller_id()))
	change_stats(attached_card.id, attack_buff(), health_buff())
