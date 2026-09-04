class_name Ruleset
extends Object


## Settings for candle/lives.
class CandlesSettings:
	## The amount of candles each player start with.
	var amount: int
	## The name of the card that snuffing candle will produce. If not provided the candle cannot be
	## snuff.
	var smoke: String

	func _init(candles_config: Dictionary) -> void:
		amount = candles_config.amount
		smoke = candles_config.smoke


## General settings for the ruleset.
class RulesetSettings:
	## Minimum deck size
	var deck_size_min: int
	## Wherever to enable the backrow, this currently does not work.
	var enable_backrow: bool
	## Candles settings, refer to [CandlesSettings].
	var candles_settings: CandlesSettings

	func _init(settings_config: Dictionary) -> void:
		deck_size_min = settings_config.deck_size_min
		enable_backrow = settings_config.enable_backrow
		candles_settings = CandlesSettings.new(settings_config.candles as Dictionary)


## Rarity config/data.
class Rarity:
	class Decoration:
		var card: Texture2D
		var listing_full: Texture2D
		var listing_compact: Texture2D

	## The name of the rarity
	var name: String
	## The max allowed copy of this card belonging to this rarity in the main deck
	var max_main: int
	## The max allowed copy of this card belonging to this rarity in the side deck
	var max_side: int
	## The icon to use for this rarity
	var icon: Texture2D
	var decoration: Decoration
	## The display name override for this rarity. If not provided the display name will be
	## [member name] capitalized.
	var display_name: String

	static var COMMON_RARITY: Rarity = _basic_config("common", 4, 10, false)
	static var RARE_RARITY: Rarity = _basic_config("rare", 1, 1, true)

	func _init(rarity_name: String, rarity_config: Dictionary) -> void:
		name = rarity_name
		max_main = rarity_config.max.main
		max_side = rarity_config.max.side

		var icon_path := "res://asset".path_join(rarity_config.icon as String)
		if rarity_config.icon.is_empty():
			icon_path = "res://asset/rarities/icon/%s.png" % rarity_name
		if not FileAccess.file_exists(icon_path):
			icon_path = "res://asset/rarities/icon/MISSING.png"
		icon = load(icon_path)

		decoration = Decoration.new()
		var decor_type := {
			card = "card/%s.png",
			listing_full = "listing/%s_full.png",
			listing_compact = "listing/%s_compact.png",
		}
		for key: String in decor_type.keys():
			var val: Variant = rarity_config.decoration[key]
			if val == null:
				decoration.set(key, null)
			else:
				var path := "res://asset".path_join(val as String)
				if val.is_empty():
					path = "res://asset/rarities/decoration".path_join(
						decor_type[key] as String % rarity_name
					)
				if not FileAccess.file_exists(path):
					decoration.set(key, null)
					continue
				decoration.set(key, load(path))

		display_name = rarity_config.name
		if display_name.is_empty():
			display_name = name.capitalize()

	static func _basic_config(
		rarity_name: String, main: int, side: int, have_decoration := false
	) -> Rarity:
		@warning_ignore("incompatible_ternary")
		var decor_val: Variant = "" if have_decoration else null
		return Rarity.new(
			rarity_name,
			{
				name = "",
				icon = "",
				decoration =
				{card = decor_val, listing_full = decor_val, listing_compact = decor_val},
				max = {main = main, side = side}
			}
		)


class Temple:
	var name: String
	var icon: Texture2D
	var frame: Dictionary[String, Texture2D]
	var display_name: String

	static var BEAST := _basic_config("beast")
	static var UNDEAD := _basic_config("undead")
	static var TECHNOLOGY := _basic_config("technology")
	static var MAGICK := _basic_config("magick")

	func _init(temple_name: String, temple_config: Dictionary) -> void:
		name = temple_name
		var icon_path := "res://asset".path_join(temple_config.icon as String)
		if temple_config.icon.is_empty():
			icon_path = "res://asset/temples/%s.png" % temple_name
		if not FileAccess.file_exists(icon_path):
			icon_path = "res://asset/temples/MISSING.png"
		icon = load(icon_path)
		for rarity: String in (temple_config.frame as Dictionary).keys():
			frame[rarity] = load("res://asset".path_join(temple_config.frame[rarity] as String))

		display_name = temple_config.name
		if display_name.is_empty():
			display_name = name.capitalize()

	static func _basic_config(temple_name: String) -> Temple:
		return Temple.new(
			temple_name,
			{
				name = "",
				icon = "",
				frame = {rare = "frame/rare/%s.png" % temple_name, common = "frame/common.png"}
			}
		)


class Tribe:
	var name: String
	var icon: Texture2D
	var display_name: String

	static var AVIAN := _basic_config("avian")
	static var CANINE := _basic_config("canine")
	static var HOOVED := _basic_config("hooved")
	static var INSECT := _basic_config("insect")
	static var REPTILE := _basic_config("reptile")
	static var CRUSTACEAN := _basic_config("crustacean")
	static var PISCINE := _basic_config("piscine")
	static var GEMS := _basic_config("gems")

	func _init(tribe_name: String, tribe_config: Dictionary) -> void:
		name = tribe_name
		var icon_path := "res://asset".path_join(tribe_config.icon as String)
		if tribe_config.icon.is_empty():
			icon_path = "res://asset/tribes/%s.png" % tribe_name
		if not FileAccess.file_exists(icon_path):
			icon_path = "res://asset/tribes/MISSING.png"
		icon = load(icon_path)

		display_name = tribe_config.name
		if display_name == null or display_name.is_empty():
			display_name = name.capitalize()

	static func _basic_config(tribe_name: String) -> Tribe:
		return Tribe.new(tribe_name, {name = "", icon = ""})


## Metadata for cards. This is a general class uses for tribes, traits.
class Trait:
	## Name of the trait.
	var name: String
	## The icon to use for this trait.
	var icon: Texture2D
	## The display name override for this trait. If not provided the display name will be
	## [member name] capitalized.
	var display_name: String
	## Wherever this trait should be hidden
	var is_hidden: bool

	static var UNHAMMERABLE := _basic_config("unhammerable")
	static var BLOODLESS := _basic_config("bloodless")
	static var BONELESS := _basic_config("boneless")
	static var ANT := _basic_config("ant")

	func _init(trait_name: String, trait_config: Dictionary) -> void:
		name = trait_name
		var icon_path := "res://asset".path_join(trait_config.icon as String)
		if trait_config.icon.is_empty():
			icon_path = "res://asset/traits/%s.png" % trait_name
		if not FileAccess.file_exists(icon_path):
			icon_path = "res://asset/traits/MISSING.png"
		icon = load(icon_path)

		is_hidden = trait_config.hidden

		display_name = trait_config.name
		if display_name == null or display_name.is_empty():
			display_name = name.capitalize()

	static func _basic_config(trait_name: String) -> Trait:
		return Trait.new(trait_name, {name = "", icon = "", hidden = false})


class CardData:
	const SCHEMA: Dictionary[String, Dictionary] = {
		name = {types = [TYPE_STRING], default = "MISSING"},
		attack = {types = [TYPE_INT], default = 0},
		special_attack = {types = [TYPE_STRING], default = ""},
		health = {types = [TYPE_INT], default = 1},
		sigils = {types = [TYPE_ARRAY], sub_type = TYPE_STRING, default = []},
		rarity = {types = [TYPE_STRING], default = "common"},
		traits = {types = [TYPE_ARRAY], sub_type = TYPE_STRING, default = []},
		temple = {types = [TYPE_STRING], default = "beast"},
		tribes = {types = [TYPE_ARRAY], sub_type = TYPE_STRING, default = []},
		costs =
		{
			types = [TYPE_DICTIONARY],
			schema =
			{
				blood = {types = [TYPE_INT], default = 0},
				bone = {types = [TYPE_INT], default = 0},
				energy = {types = [TYPE_INT], default = 0},
				cell = {types = [TYPE_INT], default = 0},
				mox =
				{
					types = [TYPE_ARRAY, TYPE_DICTIONARY],
					sub_type = TYPE_STRING,
					schema =
					{
						orange = {types = [TYPE_INT], default = 0},
						blue = {types = [TYPE_INT], default = 0},
						green = {types = [TYPE_INT], default = 0},
					},
					default = []
				}
			},
		},
		tokens = {types = [TYPE_ARRAY], sub_type = TYPE_STRING, default = []},
		# TYPE_MAX is used for variant type
		metadata = {types = [TYPE_DICTIONARY], key_type = TYPE_STRING, value_TYPE = TYPE_MAX},
		banned = {types = [TYPE_BOOL], default = false}
	}
	var name: String
	var attack: int
	var special_attack: String
	var health: Variant
	var sigils: Array[String]
	var rarity: String
	var traits: Array[String]
	var temple: String
	var tribes: Array[String]
	var costs: Card.Costs
	var tokens: Array[String]
	var metadata: Dictionary

	var banned: bool

	func as_dict() -> Dictionary:
		return Global.as_dict_generator(
			self,
			func(prop: String, value: Variant) -> Dictionary:
				if prop == "costs":
					return (value as Card.Costs).as_dict()
				return {}
		)

	func _init(dict: Dictionary) -> void:
		Global.validate_schema(dict, SCHEMA)
		for prop in SCHEMA:
			if prop == "costs":
				costs = Card.Costs.new()
				costs.blood = dict.costs.blood
				costs.bone = dict.costs.bone
				costs.energy = dict.costs.energy
				costs.cell = dict.costs.cell
				if typeof(dict.costs.mox) == TYPE_ARRAY:
					var mox_array: Array[String]
					mox_array.assign(dict.costs.mox as Array)
					costs.mox.green = mox_array.count("green")
					costs.mox.orange = mox_array.count("orange")
					costs.mox.blue = mox_array.count("blue")
				elif typeof(dict.costs.mox) == TYPE_DICTIONARY:
					var mox_dict: Dictionary[String, int]
					mox_dict.assign(dict.costs.mox as Dictionary)
					costs.mox.green = mox_dict.green
					costs.mox.orange = mox_dict.orange
					costs.mox.blue = mox_dict.blue
				continue
			# Godot hate "unsafe" type cast
			if typeof(dict[prop]) == TYPE_ARRAY:
				get(prop).assign(dict[prop])
				continue
			set(prop, dict[prop])

	func duplicate() -> CardData:
		return CardData.new(as_dict().duplicate())


class SideDeck:
	enum Type {
		CONSTRUCTED,
		DRAFT,
	}

	var type: Type
	var name: String
	var display_name: String
	## If the [member type] is [Type.CONSTRUCTED] then this will be the preset side deck to load in.
	## If the [member type] is [Type.DRAFT] then this will be the list of card available to be
	## drafted.
	var cards: Array[String]
	## Only define if [member type] is [Type.DRAFT], the maximum size of the side deck.
	var max_size: int

	func _init(side_deck_name: String, side_deck_config: Dictionary) -> void:
		name = side_deck_name

		match side_deck_config.type:
			"constructed":
				type = Type.CONSTRUCTED
				for dict: Dictionary in side_deck_config.cards as Array:
					for i in dict.amount as int:
						cards.append(dict.card)
			"draft":
				type = Type.DRAFT
				cards.assign(side_deck_config.draftable_cards as Array)
				max_size = side_deck_config.max_size

		display_name = side_deck_config.name
		if display_name == null or display_name.is_empty():
			display_name = name.capitalize()

	## Return [member card] as a frequency list.
	func get_frequency() -> Dictionary[String, int]:
		var out: Dictionary[String, int] = {}
		for card in cards:
			if card in out:
				out[card] += 1
			else:
				out[card] = 1
		return out


class SideDeckCategory:
	var name: String
	var display_name: String
	var decks: Dictionary[String, SideDeck]

	func _init(category_name: String, category_config: Dictionary) -> void:
		name = category_name

		for deck_name: String in (category_config.decks as Dictionary).keys():
			decks[deck_name] = SideDeck.new(
				deck_name, category_config.decks[deck_name] as Dictionary
			)

		display_name = category_config.name
		if display_name == null or display_name.is_empty():
			display_name = name.capitalize()


static var RULESET_SCHEMA: Dictionary[String, Dictionary] = {
	name = {types = [TYPE_STRING], default = "Placeholder ruleset name"},
	description = {types = [TYPE_STRING], default = "Placeholder description"},
	icon = {types = [TYPE_STRING], default = "ruleset_icon/MISSING.png"},
	settings =
	{
		types = [TYPE_DICTIONARY],
		schema =
		{
			deck_size_min = {types = [TYPE_INT], default = 30},
			enable_backrow = {types = [TYPE_BOOL], default = false},
			candles =
			{
				types = [TYPE_DICTIONARY],
				schema =
				{
					amount = {types = [TYPE_INT], default = 2},
					smoke = {types = [TYPE_STRING], default = "Greater Smoke"}
				}
			}
		}
	},
	rarities =
	{
		types = [TYPE_DICTIONARY],
		key_type = TYPE_STRING,
		value_type = TYPE_DICTIONARY,
		schema =
		{
			default = {types = [TYPE_BOOL], default = false},
			max =
			{
				types = [TYPE_DICTIONARY],
				schema =
				{main = {types = [TYPE_INT], default = 1}, side = {types = [TYPE_INT], default = 1}}
			},
			icon = {types = [TYPE_STRING], default = ""},
			decoration =
			{
				types = [TYPE_DICTIONARY],
				schema =
				{
					card = {types = [TYPE_STRING], default = null},
					listing_full = {types = [TYPE_STRING], default = null},
					listing_compact = {types = [TYPE_STRING], default = null},
				}
			},
			name = {types = [TYPE_STRING], default = ""}
		}
	},
	traits =
	{
		types = [TYPE_DICTIONARY],
		key_type = TYPE_STRING,
		value_type = TYPE_DICTIONARY,
		schema =
		{
			icon = {types = [TYPE_STRING], default = ""},
			name = {types = [TYPE_STRING], default = ""},
			hidden = {types = [TYPE_BOOL], default = false}
		}
	},
	temples =
	{
		types = [TYPE_DICTIONARY],
		key_type = TYPE_STRING,
		value_type = TYPE_DICTIONARY,
		schema =
		{
			icon = {types = [TYPE_STRING], default = ""},
			name = {types = [TYPE_STRING], default = ""},
			frame = {types = [TYPE_DICTIONARY], key_type = TYPE_STRING, value_type = TYPE_STRING},
		}
	},
	tribes =
	{
		types = [TYPE_DICTIONARY],
		key_type = TYPE_STRING,
		value_type = TYPE_DICTIONARY,
		schema =
		{icon = {types = [TYPE_STRING], default = ""}, name = {types = [TYPE_STRING], default = ""}}
	},
	cards =
	{
		types = [TYPE_DICTIONARY],
		key_type = TYPE_STRING,
		value_type = TYPE_DICTIONARY,
		schema = CardData.SCHEMA,
		default = {}
	},
	side_decks =
	{
		types = [TYPE_DICTIONARY],
		key_type = TYPE_STRING,
		value_type = TYPE_DICTIONARY,
		schema =
		{
			# These exist for all side deck type
			name = {types = [TYPE_STRING]},
			type = {types = [TYPE_STRING]},
			# only for constructed
			cards =
			{
				types = [TYPE_ARRAY],
				sub_type = TYPE_DICTIONARY,
				schema = {card = {types = [TYPE_STRING]}, amount = {types = [TYPE_INT]}}
			},
			# only for draft
			draftable_cards = {types = [TYPE_ARRAY], sub_type = TYPE_STRING},
			# only for category
			decks =
			{
				types = [TYPE_DICTIONARY],
				key_type = TYPE_STRING,
				value_type = TYPE_DICTIONARY,
				schema =
				{
					name = {types = [TYPE_STRING]},
					type = {types = [TYPE_STRING]},
					cards =
					{
						types = [TYPE_ARRAY],
						sub_type = TYPE_DICTIONARY,
						schema = {card = {types = [TYPE_STRING]}, amount = {types = [TYPE_INT]}}
					},
					draftable_cards = {types = [TYPE_ARRAY], sub_type = TYPE_STRING},
				}
			}
		}
	}
	# TODO: Implement sigils description and custom sigils
}

var name: String
var description: String
var icon: Texture2D
var settings: RulesetSettings
var rarities: Dictionary[String, Rarity] = {
	common = Rarity.COMMON_RARITY, rare = Rarity.RARE_RARITY
}
var default_rarity: Rarity = Rarity.COMMON_RARITY
var traits: Dictionary[String, Trait] = {
	unhammerable = Trait.UNHAMMERABLE,
	bloodless = Trait.BLOODLESS,
	boneless = Trait.BONELESS,
	ant = Trait.ANT,
}
var temples: Dictionary[String, Temple] = {
	beast = Temple.BEAST,
	undead = Temple.UNDEAD,
	technology = Temple.TECHNOLOGY,
	magick = Temple.MAGICK
}
var tribes: Dictionary[String, Tribe] = {
	avian = Tribe.AVIAN,
	canine = Tribe.CANINE,
	hooved = Tribe.HOOVED,
	insect = Tribe.INSECT,
	reptile = Tribe.REPTILE,
	crustacean = Tribe.CRUSTACEAN,
	piscine = Tribe.PISCINE,
	gems = Tribe.GEMS,
}
var cards: Dictionary[String, CardData]
# TODO: Implement side deck later
# The [Variant] can be either a [code]Dictionary[String, SideDeckCategory][/code] for category side deck
# or just a [SideDeck] for normal deck
var side_decks: Dictionary[String, Variant] = {
	squirrels =
	SideDeck.new(
		"squirrels",
		{name = "10 Squirrels", type = "constructed", cards = [{card = "Squirrel", amount = 10}]}
	)
}


func _init(ruleset: Dictionary) -> void:
	Global.validate_schema(ruleset, RULESET_SCHEMA)
	name = ruleset.name
	description = ruleset.description
	icon = load("res://asset".path_join(ruleset.icon as String))
	settings = RulesetSettings.new(ruleset.settings as Dictionary)

	for rarity_name: String in (ruleset.rarities as Dictionary).keys():
		rarities[rarity_name] = Rarity.new(rarity_name, ruleset.rarities[rarity_name] as Dictionary)

	for trait_name: String in (ruleset.traits as Dictionary).keys():
		traits[trait_name] = Trait.new(trait_name, ruleset.traits[trait_name] as Dictionary)

	for temple_name: String in (ruleset.temples as Dictionary).keys():
		temples[temple_name] = Temple.new(temple_name, ruleset.temples[temple_name] as Dictionary)

	for card_name: String in (ruleset.cards as Dictionary).keys():
		cards[card_name] = CardData.new(ruleset.cards[card_name] as Dictionary)

	for side_deck_name: String in (ruleset.side_decks as Dictionary).keys():
		var data := ruleset.side_decks[side_deck_name] as Dictionary
		if data.type == "category":
			side_decks[side_deck_name] = SideDeckCategory.new(side_deck_name, data)
		else:
			side_decks[side_deck_name] = SideDeck.new(side_deck_name, data)


# Resolve a side deck dictionary to a list of card data
func resolve_side_deck(side_dict: Dictionary) -> Array[CardData]:
	var raw_side: Variant = side_decks[side_dict.name]
	var side_deck: SideDeck
	if raw_side is SideDeckCategory:
		side_deck = raw_side[side_dict.category]
	else:
		side_deck = raw_side

	var out: Array[CardData] = []
	match side_deck.type:
		SideDeck.Type.CONSTRUCTED:
			out.assign(side_deck.cards.map(func(n: String) -> CardData: return cards[n]))
		SideDeck.Type.DRAFT:
			for card_name: String in (side_dict.deck as Dictionary).keys():
				if card_name not in side_deck.cards:
					push_warning("Illegal card found in drafted side deck skipping...")
					continue
				for i in side_dict.deck[card_name] as int:
					out.append(cards[card_name])

	return out
