extends Node3D

signal Apply_Damage
signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_point: Marker3D = $Bullet_Point

var holster : bool

var current_weapon : Weapon_Resource = null

var weapon_stack = []

var weapon_indicator : int = 0

var next_weapon : String

var weapon_list = {}

@export var weapon_resources : Array[Weapon_Resource]

@export var start_weapons : Array[String]

enum {NULL, HITSCAN, PROJECTILE}

func _ready() -> void:
	initialize(start_weapons)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_next"):
		weapon_indicator = min(weapon_indicator+1, weapon_stack.size()-1)
		unequip(weapon_stack[weapon_indicator])
	
	if event.is_action_pressed("weapon_previous"):
		weapon_indicator = max(weapon_indicator-1, 0)
		unequip(weapon_stack[weapon_indicator])
	
	if event.is_action_pressed("fire_1"):
		fire_1()
	
	if event.is_action_pressed("action_4"):
		reload()

func  initialize(_start_weapons: Array) -> void:
	
	for weapon in weapon_resources:
		weapon_list[weapon.Weapon_Name] = weapon
	for i in _start_weapons:
		weapon_stack.push_back(i)
	
	current_weapon = weapon_list[weapon_stack[0]]
	emit_signal("Update_Weapon_Stack", weapon_stack)
	equip()

func equip() -> void:
	animation_player.queue(current_weapon.Equip_Anim)
	emit_signal("Weapon_Changed", current_weapon.Weapon_Name)
	if current_weapon is Firearm_Resource:
		var firearm := current_weapon as Firearm_Resource
		emit_signal("Update_Ammo", [firearm.Current_Ammo, firearm.Reserve_Ammo])

func unequip(_next_weapon : String) -> void:
	if _next_weapon != current_weapon.Weapon_Name:
		if animation_player.get_current_animation() != current_weapon.Unequip_Anim:
			animation_player.play(current_weapon.Unequip_Anim)
			next_weapon = _next_weapon

func change_weapon(weapon_name : String) -> void:
	current_weapon = weapon_list[weapon_name]
	next_weapon = ""
	equip()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == current_weapon.Unequip_Anim and !holster:
		change_weapon(next_weapon)
	
	if current_weapon is Firearm_Resource:
		var firearm := current_weapon as Firearm_Resource
		if anim_name == firearm.Shoot_Anim and firearm.Weapon_Fire_Mode == Firearm_Resource.Fire_Mode.Auto:
			if Input.is_action_pressed("fire_1"):
				fire_1()

func fire_1():
	if current_weapon is Firearm_Resource:
		var firearm := current_weapon as Firearm_Resource
		if firearm.Current_Ammo > 0:
			if !animation_player.is_playing():
				animation_player.play(firearm.Shoot_Anim)
				firearm.Current_Ammo -= 1
				emit_signal("Update_Ammo", [firearm.Current_Ammo, firearm.Reserve_Ammo])
				var camera_collision = get_camera_collision(firearm.Weapon_Range)
				match current_weapon.Bullet_Type:
					NULL:
						print("Weapon Type Not Chosen")
					HITSCAN:
						#pass
						hit_scan_collision(camera_collision, firearm.Damage)
					PROJECTILE:
						pass
		else :
			reload()
	else :
		emit_signal("Update_Ammo", "")

func reload():
	if current_weapon is Firearm_Resource:
		var firearm := current_weapon as Firearm_Resource
		if firearm.Current_Ammo == firearm.Magazine:
			return
		elif !animation_player.is_playing():
			if firearm.Reserve_Ammo > 0:
				animation_player.play(firearm.Reload_Anim)
				var reload_amount = min(firearm.Magazine - firearm.Current_Ammo, firearm.Magazine, firearm.Reserve_Ammo)
				
				firearm.Current_Ammo = firearm.Current_Ammo + reload_amount
				firearm.Reserve_Ammo = firearm.Reserve_Ammo - reload_amount
				
				emit_signal("Update_Ammo", [firearm.Current_Ammo, firearm.Reserve_Ammo])
			else :
				if !firearm.Out_Of_Ammo_Anim.is_empty():
					animation_player.play(firearm.Out_Of_Ammo_Anim)

func get_camera_collision(range : float) -> Vector3:
	var camera : Camera3D = get_viewport().get_camera_3d()
	var viewport : Vector2 = get_viewport().get_size()
	
	var ray_origin : Vector3 = camera.project_ray_origin(viewport/2)
	var ray_end : Vector3 = ray_origin + camera.project_ray_normal(viewport/2) * range
		
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
		
	if not intersection.is_empty():
		var col_point : Vector3 = intersection.position
		return col_point
	else:
		return ray_end

func hit_scan_collision(collision_point : Vector3, damage : float):
	var bullet_direction : Vector3 = (collision_point - bullet_point.get_global_transform().origin).normalized()
	var new_intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, collision_point + bullet_direction)
	
	var bullet_collision = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	if bullet_collision:
		if bullet_collision.collider is RigidBody3D:
			var hit_position = bullet_collision.position - bullet_collision.collider.get_global_transform().origin
			bullet_collision.collider.apply_impulse((bullet_direction * damage * 0.0625), hit_position)
		#Apply Damage
