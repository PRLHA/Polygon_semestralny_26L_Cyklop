extends RayCast3D
class_name RaycastWheel

@export var spring_strength : float = 100.0
@export var spring_damping : float = 2.0
@export var rest_distance : float = 0.5
@export var over_extend : float = 0.0
@export var wheel_radius : float = 0.4
@export var is_motor : bool = false
@export var is_left_side : bool = false

@onready var wheel_position : Node3D = get_child(0)
@export var offset_bone_id : int
@export var rotation_bone_id : int
