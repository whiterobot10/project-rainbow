class_name IMFRuleset
extends Ruleset


func _init(ruleset: Dictionary) -> void:
	name = ruleset.ruleset
	description = ruleset.description
	icon = load("res://asset/ruleset_icon/simple.png")
	settings = (
		RulesetSettings
		. new(
			{
				deck_size_min = ruleset.deck_size_min,
				enable_backrow = false,
				candles =
				{
					amount = ruleset.num_candles,
					smoke = "Greater Smoke" if ruleset.allow_snuffing_candles else "",
				}
			}
		)
	)

	for card: Dictionary in ruleset.cards:
		var old_data := card

		@warning_ignore("shadowed_variable_base_class")
		var traits := []
		if "nohammer" in old_data:
			traits.append("unhammerable")
		if "nosac" in old_data:
			traits.append("bloodless")
		if "sigils" in old_data and "Boneless" in old_data.sigils:
			traits.append("boneless")

		var temple := "beast"
		if "blood_cost" in old_data:
			temple = "beast"
		elif "bone_cost" in old_data:
			temple = "undead"
		elif "energy_cost" in old_data:
			temple = "technology"
		elif "mox_cost" in old_data:
			temple = "magick"

		var tokens := []
		var metadata := {}
		var token_fields := ["evolution", "left_half", "right_hand"]
		for field: String in token_fields:
			if field in old_data:
				tokens.append(old_data[field])
		if "evolution" in old_data and "sigil" in old_data:
			if "Fledgling" in old_data.sigils:
				metadata.evolve_form = old_data.evolution
			elif "Frozen Away" in old_data.sigils:
				metadata.defrost_form = old_data.evolution
			elif "Transformer" in old_data.sigils:
				metadata.transform_form = old_data.evolution
		# various int conversion are due to json defaulting to float
		cards[card.name] = (CardData.new(
			{
				name = old_data.name,
				attack =
				old_data.atkspecial if "atkspecial" in old_data else (old_data.attack as int),
				health = old_data.health,
				sigils =
				(
					old_data.sigils.filter(
						func(sigil: String) -> bool: return sigil not in ["Depleting", "Boneless"]
					)
					if "sigils" in old_data
					else []
				),
				rarity = "rare" if "rare" in old_data else "common",
				traits = traits,
				temple = temple,
				tribes = [],
				# TODO: implement this
				# portrait = old_data
				# description = old_data.description
				costs =
				{
					blood = (old_data.blood_cost as int) if "blood_cost" in old_data else 0,
					bone = (old_data.bone_cost as int) if "bone_cost" in old_data else 0,
					energy = (old_data.energy_cost as int) if "energy_cost" in old_data else 0,
					cell = 2 if "sigils" in old_data and "Depleting" in old_data.sigils else 0,
					mox =
					(
						old_data.mox_cost.map(func(m: String) -> String: return m.to_lower())
						if "mox_cost" in old_data
						else []
					)
				},
				tokens = tokens,
				metadata = metadata,
				banned = "banned" in old_data
			}
		))
	side_decks.clear()

	for side_deck_name: String in (ruleset.side_decks as Dictionary).keys():
		var data := ruleset.side_decks[side_deck_name] as Dictionary
		if data.type == "single":
			side_decks[side_deck_name] = SideDeck.new(
				side_deck_name,
				{
					name = side_deck_name,
					type = "constructed",
					cards = [{card = data.card, amount = data.count}]
				}
			)
		elif data.type == "single_cat":
			var single_dict: Dictionary[String, Dictionary] = {}
			for deck_name: String in (data.cards as Dictionary).keys():
				var single_data := data.cards[deck_name] as Dictionary
				single_dict[deck_name] = {
					name = deck_name,
					type = "constructed",
					cards = [{card = single_data.card, amount = single_data.count}]
				}
			side_decks[side_deck_name] = SideDeckCategory.new(
				side_deck_name, {name = side_deck_name, decks = single_dict}
			)
		elif data.type == "draft":
			side_decks[side_deck_name] = SideDeck.new(
				side_deck_name,
				{
					name = side_deck_name,
					type = "draft",
					draftable_cards = data.cards,
					max_size = data.count
				}
			)
