extends Sigil

func leader_buff() -> int:
	return get_config("leader_buff", 1) as int

func static_ability(is_reset: bool) -> void:
	var neighbour_slot := get_neighbour_slot(false)
	for slot in neighbour_slot:
		if is_reset:
			slot.attack_buf = max(0, slot.attack_buf - leader_buff())
		else:
			slot.attack_buf += leader_buff()
