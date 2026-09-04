extends SpecialAttack


func attack_value() -> int:
	var slot := fight_manager.board_manager.get_slot(oppose_pos(get_pos()))
	if slot.is_empty():
		return 0
	return slot.card.attack
