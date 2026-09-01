extends Node

## Global scope, contain constant or globally use variable, also have a bunch of utility
## that might be helpful

signal _show_popup(txt: String, type: PopupType, closeable: bool)
signal _show_loading(txt: String)
signal _hide_popup

signal ruleset_changed(ruleset: Ruleset)

enum PopupType { ERR, INFO, WARN }

const CARD_SIZE := Vector2(73.0, 93.0)
const SCREEN_SIZE := Vector2(758.0, 495.0)
const VERSION := "v0.0.1"

var player_name := "NO_NAME"
var pfp := "res://asset/portraits/Stoat.png"
var uuid: StringName
var is_host := false

var ruleset: Ruleset:
	get:
		return ruleset
	set(val):
		ruleset = val
		ruleset_changed.emit(val)

var enable_backrow := false

var rulesets_path := "user://rulesets"
var decks_path := "user://decks"


func _ready() -> void:
	_make_if_not_found(rulesets_path)
	_make_if_not_found(decks_path)


func _make_if_not_found(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		push_warning("%s not found creating it..." % path)
		DirAccess.make_dir_absolute(path)
	pass


func quadratic_bezier(start: Vector2, end: Vector2, mid: Vector2) -> Callable:
	return func(t: float) -> Array:
		var q0 := start.lerp(mid, t)
		var q1 := mid.lerp(end, t)

		return [q0.lerp(q1, t), (q1 - q0).angle()]


func sum(array: Array) -> int:
	if array.is_empty():
		return 0
	return array.reduce(func(acc: int, val: int) -> int: return acc + val, 0)


func compare_card(a: Ruleset.CardData, b: Ruleset.CardData) -> bool:
	if a.costs.is_less(b.costs):
		return true

	if b.costs.is_less(a.costs):
		return false

	return a.name < b.name


func show_error(txt: String) -> void:
	_show_popup.emit(txt, PopupType.ERR, true)


func show_info(txt: String, closeable: bool) -> void:
	_show_popup.emit(txt, PopupType.INFO, closeable)


func show_loading(txt: String) -> void:
	_show_loading.emit(txt)


func hide_popup() -> void:
	_hide_popup.emit()


func gen_id() -> String:
	return String.num_uint64(floor(randf() * 1e9) as int, 16)


func get_card_by_name(card_name: String) -> Ruleset.CardData:
	return ruleset.cards[card_name] if card_name in ruleset.cards else Ruleset.CardData.new({})


func as_dict_generator(
	data: Variant, exception := func(_prop: String, _value: Variant) -> Dictionary: return {}
) -> Dictionary:
	var dict := {}
	for prop: String in (
		data
		. get_property_list()
		. filter(func(d: Dictionary) -> bool: return d.usage & PROPERTY_USAGE_SCRIPT_VARIABLE > 0)
		. map(func(d: Dictionary) -> String: return d.name)
	):
		var t: Dictionary = exception.call(prop, data.get(prop))
		dict[prop] = data.get(prop) if t.is_empty() else t
	return dict


## This modify the original data in place.
# TODO: This code is pretty stinky improve it eventually
func validate_schema(
	data: Dictionary, schema: Dictionary[String, Dictionary], show_warning := false
) -> void:
	@warning_ignore("shadowed_global_identifier", "confusable_local_usage")
	var push_warning := push_warning if show_warning else func(_x: String) -> void: pass
	for prop: String in schema:
		var s := schema[prop]
		# If it is suppose to be dictionary, validate the entry using the schema
		# if the entry is missing assume dictionary and generate the default using the schema
		if (
			TYPE_DICTIONARY in s.types
			and (prop not in data or typeof(data[prop]) == TYPE_DICTIONARY)
		):
			if prop not in data and "default" in s:
				data[prop] = s.default
				continue

			var dict: Dictionary = data[prop] if prop in data else {}
			var ds: Dictionary[String, Dictionary]
			ds.assign(s.schema as Dictionary if "schema" in s else {})
			# If the schema mention a key_type check all the key if they match the key_type and
			# check if all the value match the value_type. If value_type is TYPE_DICTIONARY,
			# validate them using the schema
			if "key_type" in s:
				for key: Variant in dict.keys():
					if typeof(key) != s.key_type:
						push_warning.call(
							"Dictionary entry does not have the correct key type, removing it"
						)
						continue
					var value: Variant = dict[key]
					if typeof(value) != s.value_type and s.value_type != TYPE_MAX:
						push_warning.call(
							"Dictionary value does not have the correct value type, removing it"
						)
					if s.value_type == TYPE_DICTIONARY:
						validate_schema(value as Dictionary, ds)
			else:
				validate_schema(dict, ds)
			data[prop] = dict
			continue

		# This would never trigger for Dictionary so it is safe for dict not to have default
		if prop not in data:
			push_warning.call('Data missing "%s" component using default: %s' % [prop, s.default])
			data[prop] = s.default
			continue
		if typeof(data[prop]) not in s.types and TYPE_MAX not in s.types:
			push_warning.call(
				'Data\'s "%s" component is of the wrong type, using default: %s' % [prop, s.default]
			)

		if typeof(data[prop]) == TYPE_ARRAY and TYPE_ARRAY in s.types:
			var array: Array = data[prop]
			for i: int in range(array.size() - 1):
				if typeof(array[i]) == TYPE_DICTIONARY and s.sub_type == TYPE_DICTIONARY:
					var ds: Dictionary[String, Dictionary]
					ds.assign(s.schema as Dictionary)
					validate_schema(array[i] as Dictionary, ds)
					continue
				if typeof(array[i]) != s.sub_type and s.sub_type != TYPE_MAX:
					push_warning.call(
						'A value inside of data\'s "%s" is of the wrong type, removing it'
					)
					array.erase(array[i])


## Remove all children of a parent node.
func clear_children(parent: Node, free_child := true) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		if free_child:
			child.queue_free()
