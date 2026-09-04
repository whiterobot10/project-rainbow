extends Sigil

func damage_buff() -> int:
	return get_config("annoying_buff", 1) as int


func static_ability(is_reset: bool) -> void:
	
	var slot := fight_manager.board_manager.get_slot(oppose_pos(get_pos()))

	if is_reset:
		slot.attack_buf = max(0, slot.attack_buf - damage_buff())
	else:
		slot.attack_buf += damage_buff()
