extends DrawFriendSigil


func friend_data() -> Ruleset.CardData:
	return Global.get_card_by_name(get_config("ant_card", "Worker Ant") as String)
