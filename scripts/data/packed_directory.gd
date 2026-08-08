class_name PackedDirectory
extends RefCounted
## Normalises filenames returned by DirAccess in editor and exported PCKs.
##
## Text resources are visible as `name.tres` in the editor, but may be
## represented as `name.tres.remap` after export. ResourceLoader still expects
## the original `name.tres` path and transparently follows the remap.

static func resource_name(file_name: String, extension: String = ".tres") -> String:
	if file_name.ends_with(extension):
		return file_name
	if file_name.ends_with(extension + ".remap"):
		return file_name.trim_suffix(".remap")
	return ""
