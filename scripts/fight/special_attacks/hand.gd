extends SpecialAttack


func attack_value() -> int:
	return fight_manager.get_data(controller_id()).hand_size
