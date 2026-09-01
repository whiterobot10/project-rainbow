class_name RulesetSelector

extends PanelContainer

var ruleset_button := preload("res://prefab/ruleset_button/ruleset_btn.tscn")

var first_time := true
var selected_ruleset: Dictionary
var installed_rulesets: PackedStringArray


class RulesetIcon:
	var name: String
	var description: String
	var url: String
	var icon: String
	var installed: bool

	@warning_ignore("untyped_declaration")
	func _init(json: Dictionary):
		name = json.name
		description = json.description
		url = json.url
		icon = json.portrait
		installed = json.installed
		# TODO: unhardcode this
		if name.begins_with("IMF Standard"):
			icon = "res://asset/ruleset_icon/scales.png"
		elif name.begins_with("IMF Eternal"):
			icon = "res://asset/ruleset_icon/hourglass.png"
		elif name.begins_with("IMF Vanilla"):
			icon = "res://asset/ruleset_icon/vanilla.png"
		elif name.begins_with("Mr.Egg's Goofy"):
			icon = "res://asset/ruleset_icon/egg.png"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	installed_rulesets = DirAccess.open(Global.rulesets_path).get_files()
	$HTTPRequest.request_completed.connect(_on_request_complete)
	$HTTPRequest.request(
		"https://raw.githubusercontent.com/107zxz/inscr-onln-ruleset/refs/heads/main/featured.json"
	)
	for file in installed_rulesets:
		var f := FileAccess.open(Global.rulesets_path.path_join(file), FileAccess.READ)
		var ruleset := JSON.parse_string(f.get_as_text()) as Dictionary
		f.close()
		var ruleset_name: String
		var ruleset_portrait: String
		if "schema" in ruleset:
			Global.validate_schema(ruleset, Ruleset.RULESET_SCHEMA)
			ruleset_name = ruleset.name
			ruleset_portrait = "res://asset".path_join(ruleset.icon as String)
		else:
			ruleset_name = ruleset.ruleset
			ruleset_portrait = "res://asset/ruleset_icon/simple.png"
		add_ruleset(
			RulesetIcon.new(
				{
					name = ruleset_name,
					description = ruleset.description,
					portrait = ruleset_portrait,
					url = "",
					installed = _is_installed(ruleset_name)
				}
			)
		)


func add_ruleset(ruleset: RulesetIcon) -> void:
	var button: RulesetButton = ruleset_button.instantiate()
	button.ruleset = ruleset
	button.horvered.connect(_on_button_horvered)
	button.mouse_exited.connect(_on_button_unhorvered)
	button.selected.connect(_on_button_selected)
	%RulesetList.add_child(button)


func _on_request_complete(
	_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	# TODO implement error handling
	# return
	var response: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	if first_time:
		for ruleset: Dictionary in response.rulesets:
			if _is_installed(ruleset.name):
				continue
			ruleset.installed = false
			add_ruleset(RulesetIcon.new(ruleset))
		first_time = false
		_on_button_unhorvered()
		return
	var file := FileAccess.open(
		Global.rulesets_path.path_join("%s.json" % response.ruleset), FileAccess.WRITE
	)
	file.store_string(JSON.stringify(response))
	file.close()
	selected_ruleset = response


func _on_button_horvered(name_: String, description: String) -> void:
	%RulesetName.text = name_
	%RulesetDescription.text = description


func _on_button_unhorvered() -> void:
	_on_button_horvered("Select a ruleset", "Select a ruleset to start playing")


func _on_button_selected(ruleset: RulesetIcon) -> void:
	if not ruleset.installed:
		$HTTPRequest.request(ruleset.url)
		await $HTTPRequest.request_completed
	else:
		var file := FileAccess.open("user://rulesets/%s.json" % ruleset.name, FileAccess.READ)
		selected_ruleset = JSON.parse_string(file.get_as_text())
		file.close()
	Global.ruleset = RulesetParser.parse_ruleset(selected_ruleset)
	visible = false


static func _is_installed(ruleset_name: Variant) -> bool:
	if typeof(ruleset_name) != TYPE_STRING:
		return false
	return FileAccess.file_exists("user://rulesets/%s.json" % ruleset_name)
