extends CharacterBody3D

@export_category("Camera")
@export var max_look_angle : float = 90.0
@export var mouse_sensitivity : float = 0.1
@export var controller_sensitivity : float = 2.25

@export_category("Movement")
@export var normal_speed : float = 5.0
@export var jump_velocity : float = 4.5

@export_category("Collision")
@export var collision_height : float = 2.0
@export var approximate_mass : float = 80.0

@onready var yaw: Node3D = $Yaw
@onready var pitch: Node3D = $Yaw/Pitch

var current_speed : float
var in_menu : bool

func _input(event: InputEvent) -> void:
	# Handle camera look input from mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw.rotate_y(deg_to_rad(-event.relative.x) * mouse_sensitivity)
		pitch.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -max_look_angle, max_look_angle)

func _process(delta: float) -> void:
	# Update movemeent speed 
	current_speed = normal_speed
	
	# Handle camera look input from joypad
	var look_inputs := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	yaw.rotation_degrees.y -= look_inputs.x * controller_sensitivity
	pitch.rotation_degrees.x -= look_inputs.y * controller_sensitivity
	pitch.rotation_degrees.x = clamp(pitch.rotation_degrees.x, -max_look_angle, max_look_angle)
	
	# Set cursor mouse mode
	if in_menu and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif !in_menu and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Physics process
# Push rigidbody3d with applied velocity..
func push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0.0, velocity_diff_in_push_dir)
			var mass_ratio = min(1.0, approximate_mass / c.get_collider().mass)
			if mass_ratio < 0.25:
				continue
			push_dir.y = 0
			var push_force = mass_ratio * 0.5
			c.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - c.get_collider().global_position)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("action_1") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "fwd", "bwd")
	var direction := (yaw.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	push_away_rigid_bodies()
	move_and_slide()
