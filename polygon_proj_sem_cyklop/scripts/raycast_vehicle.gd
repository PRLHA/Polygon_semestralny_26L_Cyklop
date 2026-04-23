extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var acceleration : float = 600.0
@export var max_speed : float = 20.0

@export var acceleration_curve : Curve

@export var center_of_mass_offset_during_airtime : float = 0.5
@export var tire_trurn_speed : float = 2.0
@export var tire_max_turn_degrees : float = 25.0

var forward_backward : float = 0.0
var left_right : float = 0.0

func _physics_process(delta: float) -> void:
	_simple_wheel_rotation(delta)
	var grounded := false
	for wheel in wheels:
		wheel.force_raycast_update()
		if wheel.is_colliding():
			grounded = true
		_do_single_wheel_suspension(wheel)
		_do_single_wheel_acceleration(wheel, delta)
		_do_single_wheel_traction(wheel, delta)
	
	if grounded:
		center_of_mass = Vector3.ZERO + Vector3.DOWN*1
		#center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		#center_of_mass = Vector3.DOWN * center_of_mass_offset_during_airtime
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * center_of_mass_offset_during_airtime

func _process(delta: float) -> void:
	input_loop()

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func input_loop():
	forward_backward = Input.get_axis("m_brake", "m_front")
	left_right = Input.get_axis("m_right", "m_left")

func _do_single_wheel_suspension(ray: RaycastWheel) -> void:
	if ray.is_colliding():
		ray.target_position.y = -(ray.rest_distance + ray.wheel_radius + ray.over_extend)
		var contact := ray.get_collision_point()
		var spring_up_direction := ray.global_transform.basis.y
		
		var spring_len := ray.global_position.distance_to(contact) - ray.wheel_radius
		#evaluate optimization
		# concider using a curve instead, cuz distance is expencive
		
		var offset := ray.rest_distance - spring_len
		
		ray.wheel_mesh.position.y = -spring_len
		
		var spring_force := ray.spring_strength * offset
		
		var world_vel := _get_point_velocity(contact)
		var relative_vel := spring_up_direction.dot(world_vel)
		var spring_damp_force := ray.spring_damping * relative_vel
		
		var spring_vector := (spring_force - spring_damp_force) * ray.get_collision_normal()
		
		var force_point_offset := contact - global_position
		apply_force(spring_vector, force_point_offset)
		
		DebugDraw3D.draw_arrow(contact, contact + spring_vector/mass, Color.LIME, 0.05)

func _do_single_wheel_acceleration(ray: RaycastWheel, delta: float) -> void:
	var forward_dir := ray.global_basis.x
	var velocity := forward_dir.dot(linear_velocity) #MOVE OUTSIDE AND CHACHE
	ray.wheel_mesh.rotate_z((-velocity * delta) / ray.wheel_radius)
	#velocity = abs(velocity)
	
	if ray.is_colliding():
		var contact := ray.wheel_mesh.global_position
		
		contact = ray.wheel_mesh.global_position
		var force_pos := contact - global_position
		
		if ray.is_motor and forward_backward != 0:
			var speed_ratio := velocity/max_speed
			var acceleration_percentage := acceleration_curve.sample_baked(abs(speed_ratio))
			var force_vector := forward_dir * acceleration * acceleration_percentage * forward_backward
			apply_force(force_vector, force_pos)
			DebugDraw3D.draw_arrow(contact, contact + force_vector/mass, Color.RED, 0.25)

func  _do_single_wheel_traction(ray : RaycastWheel, delta : float) -> void:
	if not ray.is_colliding():
		return
	var steer_side_dir := ray.global_basis.z
	var tire_vel := _get_point_velocity(ray.wheel_mesh.global_position)
	var steering_z_vel := steer_side_dir.dot(tire_vel)
	var z_traction := 1.0
	
	var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") #cache this
	
	var z_force : Vector3 = (-steer_side_dir * steering_z_vel * #how do i breakline?
		z_traction * (mass*gravity/wheels.size())) #cache this
	
	var force_pos := ray.wheel_mesh.global_position - global_position
	
	apply_force(z_force, force_pos)
	DebugDraw3D.draw_arrow(ray.wheel_mesh.global_position, ray.wheel_mesh.global_position
		 + z_force/mass, Color.YELLOW, 0.25)

func _simple_wheel_rotation(delta : float) -> void:
	
	if left_right:
		$WheelFL.rotation.y = clampf($WheelFL.rotation.y + left_right*tire_trurn_speed * delta, 
			deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
		$WheelFR.rotation.y = clampf($WheelFR.rotation.y + left_right*tire_trurn_speed * delta, 
			deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
	else:
		$WheelFL.rotation.y = move_toward($WheelFL.rotation.y, 0, tire_trurn_speed * delta)
		$WheelFR.rotation.y = move_toward($WheelFR.rotation.y, 0, tire_trurn_speed * delta)
