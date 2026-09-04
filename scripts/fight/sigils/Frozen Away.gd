extends SpawnDeathSigil


func new_form() -> Ruleset.CardData:
	return Global.get_card_by_name(get_config("defrost_form", "Opossum") as String)
