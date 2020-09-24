class_name JsonValidator
extends Node

const input := "input"
const output := "output"

static func validate_config_json(json_as_string: String)->Array:
	var errors := []
	
	var json_errors := validate_json(json_as_string)
	if json_errors.empty():
		var config_dict: Dictionary = parse_json(json_as_string)
		
		if !config_dict.has(output):
			errors.append("[Error] Missing the output.")
		elif !(config_dict.get(output) is String):
			errors.append("[Error] Invalid 'output' type. Use a String.")
		else:
			if !_extern_dir_exists(config_dict.get(output)):
				errors.append("[Warn ] The 'outout' path: "+ config_dict.get(output) +" does not exist!")
		
		if !config_dict.has(input):
			errors.append("[Error] Missing the input.")
		elif !(config_dict.get(input) is Array and not config_dict.get(input).empty()):
			errors.append("[Error] Invalid 'input' type. Use a Array of paths.")
		else:
			var paths: Array = config_dict.get(input)
			for path in paths:
				if !_extern_dir_exists(path):
					errors.append("[Error] The path: "+ path +" inside the 'input' array does not exist!")
		
		if config_dict.keys().size() > 2:
			errors.append("[Warn ] More than two fields present")
	else:
		errors.append("[Invalid] "+ json_errors)
	errors.sort()
	errors.invert()
	return errors

static func _extern_dir_exists(path: String)->bool:
	var dir_2_check = Directory.new()
	var result = dir_2_check.open(path)
	if result != OK:
		return false
	else:
		return true
	
