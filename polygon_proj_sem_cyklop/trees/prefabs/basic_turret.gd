extends Node3D

@export var rotateSpeedDegrees : float = 25.0
@export var elevateSpeedDegrees : float = 25.0
@export var rotationTarget : Node3D
@export var minElevationDegrees : float = 5.0
@export var maxElevationDegrees : float = 25.0

@onready var minElevation : float = deg_to_rad(minElevationDegrees)
@onready var maxElevation : float = deg_to_rad(maxElevationDegrees)
@onready var rotateSpeed := deg_to_rad(rotateSpeedDegrees)
@onready var elevateSpeed := deg_to_rad(elevateSpeedDegrees)
@onready var AxisY := $AxisY
@onready var AxisZ := $AxisY/AxisZ
@onready var Flash = $AxisY/AxisZ/Recoil/FlashCylinder
@onready var MuzzleFlash = $AxisY/AxisZ/Recoil/MuzzleFlash as GPUParticles3D
@onready var MuzzleCone = $AxisY/AxisZ/Recoil/MuzzleCone as GPUParticles3D
@onready var AudioPlayer = $AudioStreamPlayer3D as AudioStreamPlayer3D
@onready var Recoil = $AxisY/AxisZ/Recoil
@onready var Reload = $Reload as Timer
@onready var MuzzleTimer = $AxisY/AxisZ/Recoil/MuzzleFlsah as Timer


func _process(delta: float) -> void:
	handle_firing()

func _physics_process(delta: float) -> void:
	if rotationTarget == null:
		return
	rotate_and_elevate(delta, rotationTarget.global_position)
	Recoil.position.x = lerp(Recoil.position.x, 0.0, 5*delta)

func rotate_and_elevate(delta: float, current_target: Vector3) -> void:
	var rotation_targ : Vector3 = get_projected(current_target - AxisY.global_position, AxisY.global_basis.y)
	
	rotation_targ = rotation_targ + AxisY.global_position
	var y_angle : float = get_angle_to(AxisY.global_position, rotation_targ, AxisY.global_basis.x)
	var rotation_sign : float = -sign(AxisY.to_local(current_target).z)
	var final_y : float = rotation_sign * min(rotateSpeed*delta, y_angle)
	AxisY.rotate_y(final_y)
	
	var elevation_targ : Vector3 = get_projected(current_target - AxisZ.global_position, AxisZ.global_basis.z)
	
	elevation_targ = elevation_targ + AxisZ.global_position
	var z_angle : float = get_angle_to(AxisZ.global_position, elevation_targ, AxisZ.global_basis.x)
	var elevation_sign : float = sign(AxisZ.to_local(current_target).y)
	var final_z : float = elevation_sign * min(elevateSpeed*delta, z_angle)
	AxisZ.rotate_z(final_z)
	
	AxisZ.rotation.z = clamp(
		AxisZ.rotation.z,
		-minElevation, maxElevation
	)

func get_projected(pos: Vector3, normal: Vector3) -> Vector3:
	normal = normal.normalized()
	var projection : Vector3 = (pos.dot(normal) / normal.dot(normal)) * normal
	return pos - projection

func get_angle_to(seeker_pos: Vector3, target_pos: Vector3, facing_dir: Vector3) -> float:
	var dir_to = seeker_pos.direction_to(target_pos)
	facing_dir = facing_dir.normalized()
	dir_to = dir_to.normalized()
	return acos(facing_dir.dot(dir_to))

#func _input(event: InputEvent) -> void:
func handle_firing()->void:
	if Input.is_action_pressed("fire"):# event.is_action_pressed("fire"):
		if Reload.is_stopped():
			MuzzleFlash.emitting = true
			MuzzleCone.emitting = true
			Flash.rotation.x = randf()*deg_to_rad(360)
			Recoil.position.x = -0.5
			Reload.start()
			Flash.visible = true
			MuzzleTimer.start()
			AudioPlayer.play(0)


func _on_muzzle_flsah_timeout() -> void:
	Flash.visible = false
