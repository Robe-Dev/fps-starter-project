extends Resource

class_name Weapon_Resource

@export var Weapon_Name: String
@export var Equip_Anim: String
@export var Unequip_Anim: String
@export var Discard_Anim : String

@export var Durability : float
@export var Wear_Per_Use: float

enum Weapon_Slot{
	Primary,
	Secondary,
	Teritary,
	Quternary,
	Quinary
}

@export var slot : Weapon_Slot;
