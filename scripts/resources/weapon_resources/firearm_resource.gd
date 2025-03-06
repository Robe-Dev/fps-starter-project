extends Weapon_Resource

class_name Firearm_Resource

@export var Shoot_Anim : String
@export var Reload_Anim : String
@export var Out_Of_Ammo_Anim : String

@export var Current_Ammo : int
@export var Reserve_Ammo: int
@export var Magazine: int

enum Fire_Mode{
	Auto,
	Burst,
	Semi
}

@export var Weapon_Fire_Mode: Fire_Mode = Fire_Mode.Auto
