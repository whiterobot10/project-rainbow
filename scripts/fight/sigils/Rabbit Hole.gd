extends DrawFriendSigil


func friend_data() -> Ruleset.CardData:
	return Global.get_card_by_name(get_config("rabbit_card", "Rabbit") as String)
