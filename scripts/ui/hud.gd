extends Control

@export var current_weapon : Label
@export var ammo_count : Label
@export var weapon_stack : Label

func _on_inventory_update_ammo(Ammo) -> void:
	ammo_count.set_text(str(Ammo[0])+" / "+str(Ammo[1]))

func _on_inventory_update_weapon_stack(Weapon_Stack) -> void:
	weapon_stack.set_text("")
	for i in Weapon_Stack:
		weapon_stack.text += "\n" + i

func _on_inventory_weapon_changed(Weapon_Name) -> void:
	current_weapon.set_text(Weapon_Name)
