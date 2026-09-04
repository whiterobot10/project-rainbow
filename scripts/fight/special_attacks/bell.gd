extends SpecialAttack


func attack_value() -> int:
	return fight_manager.board_manager.columns - get_pos().x
