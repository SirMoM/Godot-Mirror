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
		if !(config_dict.get(input) is Array):
			errors.append("[Error] Invalid 'output' type. Use a String.")
		if !config_dict.has(input):
			errors.append("[Error] Missing the input.")
		if !(config_dict.get(input) is Array):
			errors.append("[Error] Invalid 'input' type. Use a Array of paths.")
		else:
		var paths: Array = config_dict.get(input)
		var file := File.new()
		for path in paths:
			if !file.file_exists(path):
				errors.append("[Error] The path: "+ path +" inside the 'input' array does not exist!.")
		
		if config_dict.keys().size() > 2:
			errors.append("[Warn ] More than two fields present")
	else:
		errors.append("[Error] "+ json_errors)
	return errors
