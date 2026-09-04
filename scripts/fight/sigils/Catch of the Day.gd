extends Sigil

func fish_data() -> Ruleset.CardData:
	var bad_fish := get_config("bad_fish_card", "Bad Fish") as String
	var more_fish := get_config("more_fish_card", "More Fish") as String
	var good_fish := get_config("good_fish_card", "Good Fish") as String
	var random_float := randf()
		
	if random_float < get_config("bad_fish_rng", 0.5) as float:
		return Global.get_card_by_name(bad_fish as String)
		
	elif random_float < get_config("more_fish_rng", 0.75) as float:
		return Global.get_card_by_name(more_fish as String)
		
	else:
		return Global.get_card_by_name(good_fish as String)


func on_card_perished(card: Card) -> void:
	
	if card != attached_card:
		return

	create_and_add_token(fish_data(), controller_id(), attached_card.id)
