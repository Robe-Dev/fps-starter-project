extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree

# State variable
var state: String = "patrol"

# Patrol points
@export var patrol_points: Array[Marker3D]
var current_patrol_index: int = 0

# Follow parameters
@export var in_reach_distance: float = 5.0
@export var speed: float = 2.5
@export var detection_radius: float = 15.0
@export var field_of_view_angle: float = 225.0  # Field of view angle in degrees

@export var approximate_mass : float = 80.0

# Reference to targets
var targets: Array = []
var target_direction : Vector3

var movement : float = 0.0
var tween = false
var root_velocity : Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize targets from the group "targets"
	targets = get_tree().get_nodes_in_group("team1")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match state:
		"patrol":
			patrol(delta)
			check_for_targets()
		"follow":
			follow(delta)
			check_for_targets()
	
	look_at_target(delta)
	
	velocity = root_velocity
	
	push_away_rigid_bodies()
	move_and_slide()

func set_root_motion_animation(delta : float, movement_amount : float) -> void:
	if target_direction.length() > 0:
		movement = lerp(movement, movement_amount, 3.75 * delta)
		if tween:
			tween.kill()
			tween = 0
		animation_tree.set("parameters/movement/blend_position", movement)
	else :
		if not tween:
			tween = create_tween().bind_node(self)
			var t = movement
			tween.tween_property(self, "movement", 0.0, t).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
		animation_tree.set("parameters/movement/blend_position", movement)
	
	root_velocity = global_basis * animation_tree.get_root_motion_position() / delta * 0.25

func patrol(delta: float):
	if patrol_points.size() <= 0:
		velocity = Vector3.ZERO
		return
	
	var target = patrol_points[current_patrol_index]
	navigation_agent_3d.target_position = target.global_position
	target_direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
	
	set_root_motion_animation(delta, .5)
	
	# Check if reached the patrol point
	if global_transform.origin.distance_to(target.global_position) < 1.0 and patrol_points.size() > 1:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func follow(delta: float):
	if targets.size() <= 0:
		return
	
	var closest_target = null
	var closest_distance = INF
	
	for target in targets:
		var distance = global_transform.origin.distance_to(target.global_transform.origin)
		if distance < closest_distance and is_target_in_fov(target) and is_target_visible(target):
			closest_distance = distance
			closest_target = target
		else :
			state = "patrol"
		
	if closest_target: 
		if closest_distance < detection_radius:
			navigation_agent_3d.target_position = closest_target.global_position
			target_direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
			set_root_motion_animation(delta, 1.0)
			print("gate 1")
		else :
			state = "patrol"
	else:
		state = "patrol"  # Switch back to patrol if no targets are close

func check_for_targets():
	for target in targets:
		if global_transform.origin.distance_to(target.global_transform.origin) < detection_radius and is_target_in_fov(target) and is_target_visible(target):
			state = "follow"
			return
		
	if state == "follow":
		state = "patrol"

func is_target_in_fov(target: Node3D) -> bool:
	var direction_to_target = (target.global_transform.origin - global_transform.origin).normalized()
	var forward_direction = transform.basis.z.normalized()  # Assuming the front of the AI is along the negative Z axis

	var angle_to_target = rad_to_deg(acos(forward_direction.dot(direction_to_target)))

	return angle_to_target <= field_of_view_angle / 2.0

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

func look_at_target(delta : float) -> void:
		if target_direction.length() > 0:
			rotation.y = lerp_angle(rotation.y, atan2(target_direction.x, target_direction.z), delta * 3.75)

# Check if the target is visible using a raycast
func is_target_visible(target: Node3D) -> bool:
	var from_position = global_transform.origin + Vector3.UP * 1.5
	var to_position = target.global_transform.origin + Vector3.UP * 1.5
	
	# Perform a raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from_position, to_position)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	# If the ray hits something, check if it's the target
	if result:
		var collider = result.collider
		# If the collider is the target, it means the target is visible
		if collider == target:
			return true
		else:
			return false  # An obstacle is blocking the view
	return true  # No obstacles, target is visible
