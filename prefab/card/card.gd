class_name Card
extends Button

var active_button := preload("res://prefab/card/active_button.tscn")

enum Zone {
	HAND,
	OPP_HAND,
	BOARD,
	GRAVEYARD,
	EXILE,
	LIMBO,
}
const PUBLIC_ZONE = [Zone.BOARD, Zone.GRAVEYARD, Zone.EXILE]

signal active_pressed(sigil_idx: int)


class Costs:
	class Mox:
		var green := 0
		var orange := 0
		var blue := 0

		func add(mox: Mox) -> void:
			green += mox.green
			orange += mox.orange
			blue += mox.blue

		func as_dict() -> Dictionary[String, int]:
			return {green = green, orange = orange, blue = blue}

		func is_empty() -> bool:
			return green == 0 and orange == 0 and blue == 0

		static func g(amount := 1) -> Mox:
			var m := Mox.new()
			m.green = amount
			return m

		static func o(amount := 1) -> Mox:
			var m := Mox.new()
			m.orange = amount
			return m

		static func b(amount := 1) -> Mox:
			var m := Mox.new()
			m.blue = amount
			return m

		static func gob(green_amount := 1, orange_amount := 1, blue_amount := 1) -> Mox:
			var m := Mox.new()
			m.green = green_amount
			m.orange = orange_amount
			m.blue = blue_amount
			return m

	var blood: int = 0
	var bone: int = 0
	var energy: int = 0
	var cell: int = 0
	var mox: Mox = Mox.new()

	func as_dict() -> Dictionary:
		return Global.as_dict_generator(
			self,
			func(prop: String, value: Variant) -> Dictionary:
				if prop == "mox":
					return (value as Variant).as_dict()
				return {}
		)

	func get_sort_key() -> Array:
		var color_count := 0

		if mox.green > 0:
			color_count += 1
		if mox.orange > 0:
			color_count += 1
		if mox.blue > 0:
			color_count += 1

		var t := [
			blood,
			bone,
			energy,
			cell,
			[
				color_count,
				int(mox.green == 0),
				int(mox.orange == 0),
				int(mox.blue == 0),
				mox.green,
				mox.orange,
				mox.blue
			]
		]
		t.reverse()
		return t

	func is_less(other: Costs) -> bool:
		return get_sort_key() < other.get_sort_key()


var is_db_card := false:
	set(new):
		is_db_card = new
		redraw_card()

var card_data: Ruleset.CardData:
	set(new_data):
		parse_data(new_data)
		card_data = new_data
		redraw_card()

var zone := Zone.LIMBO:
	set(new):
		zone = new
		visible = zone != Zone.LIMBO
		%CostContainer.visible = zone != Zone.BOARD
		redraw_card()
var id := Global.gen_id()

## Buff for the attack value coming from non slot sources.
var attack_buf: int = 0:
	set(new):
		attack_buf = new
		_update_buf()
## Buff for the attack value coming from the slot the card is on
var slot_attack_buf: int = 0:
	set(new):
		slot_attack_buf = new
		_update_buf()


## Syncronize [member attack] by combining [member attack_buf], [member slot_attack_buf],
## [member card_data] and buff from special attack
func _update_buf() -> void:
	attack = (
		card_data.attack
		+ slot_attack_buf
		+ attack_buf
		+ (
			0
			if (_special_attack == null or not _special_attack._should_be_active())
			else _special_attack.attack_value()
		)
	)


# These are just extracted out of the card_data for type safety
## The attack of the card, if you want to temporarily buff the card use [member attack_buf] or
## [member slot_attack_buf]
var attack: int:
	set(new):
		attack = new
		redraw_card()
## The special attack name on the card. If you want to get the actual [SpecialAttack] object, use
## [member _special_attack]
var special_attack: String:
	set(new):
		special_attack = new
		redraw_card()
var _special_attack: SpecialAttack
## The health of the card
var health: int:
	set(new):
		health = new
		redraw_card()
## The list of sigils name on the card. If you want to get the list of actual [Sigil] objects, use
## [member _sigils]
var sigils: Array[String]:
	set(new):
		sigils = new
		redraw_card()
## The list of actual [Sigil] object on the card. If you want to get the list of names use
## [member sigils]
var _sigils: Array[Sigil]
var rarity: Ruleset.Rarity
## Trait of the card, these don't have any gameplay effect but instead they are checked by
## sigils and or cost.
var traits: Array[Ruleset.Trait]
var temple: Ruleset.Temple:
	set(new):
		temple = new
		redraw_card()
var tribes: Array[Ruleset.Tribe]:
	set(new):
		tribes = new
		redraw_card()
var costs: Costs:
	set(new):
		costs = new
		redraw_card()
var tokens: Array[String]
var card_name: String:
	set(new):
		card_name = new
		redraw_card()

var parsing_data := false

@onready var sac_marker: TextureRect = $SacMarker
@onready var submerge_overlay: TextureRect = $SubmergeOverlay
@onready var banned_overlay: TextureRect = $BanOverlay


func blood_value() -> int:
	var t := 0
	for sigil: Sigil in _sigils:
		t += sigil.blood_value()
	return t if t != 0 else 1


func mox_value() -> Costs.Mox:
	var m := Costs.Mox.new()
	for sigil: Sigil in _sigils:
		m.add(sigil.mox_value())
	return m


## Parse and assign infomation in [param data]
func parse_data(data: Ruleset.CardData, show_warning := false) -> void:
	@warning_ignore("confusable_local_usage", "shadowed_global_identifier")
	var push_warning := push_warning if show_warning else func(_x: String) -> void: pass
	parsing_data = true
	sigils.clear()
	_sigils.clear()

	attack = data.attack
	health = data.health

	special_attack = data.special_attack
	if not special_attack.is_empty():
		var script_path := "res://scripts/fight/special_attacks/%s.gd" % special_attack
		if not FileAccess.file_exists(script_path):
			push_warning.call(
				(
					'Special Attack script can\'t be found for "%s" so using missing script instead'
					% special_attack
				)
			)
			script_path = "res://scripts/fight/special_attacks/MISSING.gd"
		_special_attack = load(script_path).new()
		_special_attack.attached_card = self

		var icon_path := "res://asset/special_attacks/%s.png" % special_attack
		if not FileAccess.file_exists(icon_path):
			push_warning.call(
				(
					'Special Attack icon can\'t be found for "%s" so using missing texture instead'
					% special_attack
				)
			)
			icon_path = "res://asset/special_attacks/MISSING.png"
		_special_attack.texture = load(icon_path)

	for sigil: String in data.sigils:
		# Figuring out where the script is
		var script_path := "res://scripts/fight/sigils/%s.gd" % sigil
		if not FileAccess.file_exists(script_path):
			push_warning.call(
				'Sigil script can\'t be found for "%s" so using missing script instead' % sigil
			)
			script_path = "res://scripts/fight/sigils/MISSING.gd"
		var s: Sigil = load(script_path).new()
		s.attached_card = self

		# Now the texture
		var sigil_path := "res://asset/sigils/%s.png" % sigil
		if not FileAccess.file_exists(sigil_path):
			push_warning.call(
				'Sigil icon can\'t be found for "%s" so using missing texture instead' % sigil
			)
			sigil_path = "res://asset/sigils/MISSING.png"
		s.texture = load(sigil_path)
		sigils.append(sigil)
		_sigils.append(s)

	rarity = Global.ruleset.rarities[data.rarity]
	traits.assign(
		data.traits.map(func(t: String) -> Ruleset.Trait: return Global.ruleset.traits[t])
	)
	temple = Global.ruleset.temples[data.temple]
	tribes.assign(
		data.tribes.map(func(t: String) -> Ruleset.Tribe: return Global.ruleset.tribes[t])
	)

	costs = data.costs
	tokens = data.tokens
	card_name = data.name
	parsing_data = false


func redraw_card() -> void:
	# don't redraw while parsing card so that we don;t spam the log
	if parsing_data:
		return
	$SacMarker.visible = false
	$BanOverlay.visible = card_data.banned and is_db_card
	%Name.text = card_name

	var portrait_path := "res://asset/portraits/%s.png" % card_name
	if FileAccess.file_exists(portrait_path):
		%Portrait.texture = load(portrait_path)
	else:
		push_warning(
			'Portrait can\'t be found for "%s" so using missing texture instead' % card_name
		)
		%Portrait.texture = load("res://asset/portraits/MISSING.png")

	%Frame.texture = temple.frame[rarity.name]

	%RarityDecoration.texture = rarity.decoration.card

	%Temple.texture = temple.icon

	for n in %TribesContainer.get_children():
		%TribesContainer.remove_child(n)
		n.queue_free()
	for tribe in tribes:
		var t := TextureRect.new()
		t.texture = tribe.icon
		%TribesContainer.add_child(t)

	for n in %SigilsContainer.get_children():
		%SigilsContainer.remove_child(n)
		if n is TextureButton:
			n.remove_child(n.get_child(0))
			n.queue_free()
	for sigil_idx in len(_sigils):
		var sigil := _sigils[sigil_idx]
		%SigilsContainer.add_child(sigil)
		if sigil.is_active_sigil():
			var btn := active_button.instantiate()
			%SigilsContainer.add_child(btn)
			sigil.reparent(btn)
			btn.disabled = sigil.fight_manager != null and sigil.is_disable()
			btn.connect("pressed", func() -> void: active_pressed.emit(sigil_idx))

	var sp_atk_rest_pos := Vector2(-1, 4)
	Global.clear_children(%Attack, false)
	%Attack.text = ""
	if _special_attack != null:
		%Attack.add_child(_special_attack)
		_special_attack.position = sp_atk_rest_pos
		_special_attack.self_modulate = Color.WHITE

		if _special_attack._should_be_active():
			_special_attack.position += Vector2.UP * 8
			_special_attack.self_modulate.a = 0.5

	if _special_attack == null or _special_attack.position != sp_atk_rest_pos:
		%Attack.text = str(attack)
		if attack > card_data.attack:
			%Attack.add_theme_color_override(&"font_color", Color("007c00"))
		elif attack < card_data.attack:
			%Attack.add_theme_color_override(&"font_color", Color("82051e"))
		else:
			%Attack.add_theme_color_override(&"font_color", Color("000000"))

	%Health.text = str(health)
	for n in %CostContainer.get_children():
		%CostContainer.remove_child(n)
		n.queue_free()

	for n in cost_string(costs):
		%CostContainer.add_child(n)


@warning_ignore("shadowed_variable")
static func cost_string(costs: Costs) -> Array[HBoxContainer]:
	var out: Array[HBoxContainer] = []
	if costs.bone != 0:
		out.append(num_cost_icon("res://asset/cost/bone.png", costs.bone as int))
	if costs.blood != 0:
		out.append(num_cost_icon("res://asset/cost/blood.png", costs.blood as int))
	if costs.energy != 0:
		out.append(num_cost_icon("res://asset/cost/energy.png", costs.energy as int))
	if costs.cell != 0:
		out.append(num_cost_icon("res://asset/cost/cell.png", costs.cell as int))

	if not costs.mox.is_empty():
		out.append(mox_cost_icon(costs.mox))
	return out


static func num_cost_icon(cost_icon: String, amount: int) -> HBoxContainer:
	var cost := HBoxContainer.new()
	cost.add_theme_constant_override("separation", -1)
	@warning_ignore("shadowed_variable_base_class")
	var icon := TextureRect.new()
	icon.texture = load(cost_icon)
	cost.add_child(icon)
	for d: String in str(amount):
		var digit := TextureRect.new()
		digit.texture = load("res://asset/cost/number/%s.png" % d)
		digit.stretch_mode = TextureRect.STRETCH_KEEP
		digit.size_flags_vertical = Control.SIZE_SHRINK_END
		cost.add_child(digit)
	return cost


static func mox_cost_icon(mox: Costs.Mox) -> HBoxContainer:
	var cost := HBoxContainer.new()
	cost.add_theme_constant_override("separation", -5)
	for i in range(mox.green):
		var t := TextureRect.new()
		t.texture = load("res://asset/cost/mox/green.png")
		cost.add_child(t)
	for i in range(mox.orange):
		var t := TextureRect.new()
		t.texture = load("res://asset/cost/mox/orange.png")
		cost.add_child(t)
	for i in range(mox.blue):
		var t := TextureRect.new()
		t.texture = load("res://asset/cost/mox/blue.png")
		cost.add_child(t)
	for c in cost.get_children().size():
		cost.get_child(c).z_index = cost.get_child_count() - c
	return cost


func as_dict() -> Dictionary:
	return {data = card_data.as_dict(), id = id, zone = zone}
