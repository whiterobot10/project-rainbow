extends SpawnDeathSigil

func new_form() -> Ruleset.CardData:
	return Global.get_card_by_name(get_config("ruby_card", "Ruby Mox") as String)
