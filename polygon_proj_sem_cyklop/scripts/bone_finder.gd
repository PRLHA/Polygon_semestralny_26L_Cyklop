@tool
extends Node3D

@export var bone_to_find : String
@export var search : bool = false
@onready var skeleton = $"../wheel_chassis/Armature/Skeleton3D"

func _process(delta: float) -> void:
	if search:
		var id = skeleton.find_bone(bone_to_find)
		print("bone id is - " + str(id))
		search = false
