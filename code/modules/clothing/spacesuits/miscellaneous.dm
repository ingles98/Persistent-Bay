//Captain's Spacesuit
/obj/item/clothing/head/helmet/space/capspace
	name = "space helmet"
	icon_state = "capspace"
	item_state = "capspace"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Only for the most fashionable of military figureheads."
	flags_inv = HIDEFACE
	permeability_coefficient = 0.01
	armor  = list(
		DAM_BLUNT 	= 65,
		DAM_PIERCE 	= 55,
		DAM_CUT 	= 65,
		DAM_BULLET 	= 50,
		DAM_LASER 	= 50,
		DAM_ENERGY 	= 25,
		DAM_BURN 	= 40,
		DAM_BOMB 	= 50,
		DAM_EMP 	= 5,
		DAM_BIO 	= 100,
		DAM_RADS 	= 50,
		DAM_STUN 	= 2)

//Captain's space suit This is not the proper path but I don't currently know enough about how this all works to mess with it.
/obj/item/clothing/suit/armor/captain
	name = "Captain's armor"
	desc = "A bulky, heavy-duty piece of exclusive corporate armor. YOU are in charge!"
	icon_state = "caparmor"
	item_state_slots = list(
		slot_l_hand_str = "capspacesuit",
		slot_r_hand_str = "capspacesuit",
	)
	w_class = ITEM_SIZE_HUGE
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0
	item_flags = ITEM_FLAG_STOPPRESSUREDAMAGE
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS
	allowed = list(/obj/item/weapon/tank/emergency, /obj/item/device/flashlight,/obj/item/weapon/gun/energy, /obj/item/weapon/gun/projectile, /obj/item/ammo_magazine, /obj/item/ammo_casing, /obj/item/weapon/melee/baton,/obj/item/weapon/handcuffs)
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT|HIDETAIL
	cold_protection = UPPER_TORSO | LOWER_TORSO | LEGS | FEET | ARMS | HANDS
	min_cold_protection_temperature = SPACE_SUIT_MIN_COLD_PROTECTION_TEMPERATURE
	siemens_coefficient = 0.7
	armor  = list(
		DAM_BLUNT 	= 65,
		DAM_PIERCE 	= 55,
		DAM_CUT 	= 65,
		DAM_BULLET 	= 50,
		DAM_LASER 	= 50,
		DAM_ENERGY 	= 25,
		DAM_BURN 	= 45,
		DAM_BOMB 	= 50,
		DAM_EMP 	= 5,
		DAM_BIO 	= 100,
		DAM_RADS 	= 50,
		DAM_STUN 	= 2)

/obj/item/clothing/suit/armor/captain/New()
	..()
	slowdown_per_slot[slot_wear_suit] = 1.5

//Deathsquad suit
/obj/item/clothing/head/helmet/space/deathsquad
	name = "deathsquad helmet"
	desc = "That's not red paint. That's real blood."
	icon_state = "deathsquad"
	item_state_slots = list(
		slot_l_hand_str = "syndicate-helm-black-red",
		slot_r_hand_str = "syndicate-helm-black-red",
		)
	item_flags = ITEM_FLAG_STOPPRESSUREDAMAGE | ITEM_FLAG_THICKMATERIAL
	flags_inv = BLOCKHAIR
	siemens_coefficient = 0.6
	armor  = list(
		DAM_BLUNT 	= 65,
		DAM_PIERCE 	= 55,
		DAM_CUT 	= 65,
		DAM_BULLET 	= 55,
		DAM_LASER 	= 35,
		DAM_ENERGY 	= 20,
		DAM_BURN 	= 15,
		DAM_BOMB 	= 30,
		DAM_EMP 	= 5,
		DAM_BIO 	= 100,
		DAM_RADS 	= 60,
		DAM_STUN 	= 1)

//Space santa outfit suit
/obj/item/clothing/head/helmet/space/santahat
	name = "Santa's hat"
	desc = "Ho ho ho. Merrry X-mas!"
	icon_state = "santahat"
	item_state = "santahat"
	item_flags = ITEM_FLAG_STOPPRESSUREDAMAGE
	flags_inv = BLOCKHAIR
	body_parts_covered = HEAD

/obj/item/clothing/suit/space/santa
	name = "Santa's suit"
	desc = "Festive!"
	icon_state = "santa"
	item_flags = ITEM_FLAG_STOPPRESSUREDAMAGE
	allowed = list(/obj/item) //for stuffing exta special presents

/obj/item/clothing/suit/space/santa/New()
	..()
	slowdown_per_slot[slot_wear_suit] = 0

//Space pirate outfit
/obj/item/clothing/head/helmet/pirate
	name = "pirate hat"
	desc = "Yarr."
	icon_state = "pirate"
	item_state = "pirate"
	flags_inv = BLOCKHAIR
	body_parts_covered = 0
	siemens_coefficient = 0.9
	armor  = list(
		DAM_BLUNT 	= 60,
		DAM_PIERCE 	= 50,
		DAM_CUT 	= 60,
		DAM_BULLET 	= 50,
		DAM_LASER 	= 30,
		DAM_ENERGY 	= 15,
		DAM_BURN 	= 15,
		DAM_BOMB 	= 30,
		DAM_EMP 	= 0,
		DAM_BIO 	= 30,
		DAM_RADS 	= 30,
		DAM_STUN 	= 0)

/obj/item/clothing/suit/pirate
	name = "pirate coat"
	desc = "Yarr."
	icon_state = "pirate"
	w_class = ITEM_SIZE_NORMAL
	allowed = list(/obj/item/weapon/gun,/obj/item/ammo_magazine,/obj/item/ammo_casing,/obj/item/weapon/melee/baton,/obj/item/weapon/handcuffs,/obj/item/weapon/tank/emergency)
	siemens_coefficient = 0.9
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS
	armor  = list(
		DAM_BLUNT 	= 60,
		DAM_PIERCE 	= 50,
		DAM_CUT 	= 60,
		DAM_BULLET 	= 50,
		DAM_LASER 	= 30,
		DAM_ENERGY 	= 15,
		DAM_BURN 	= 15,
		DAM_BOMB 	= 30,
		DAM_EMP 	= 0,
		DAM_BIO 	= 30,
		DAM_RADS 	= 30,
		DAM_STUN 	= 1)

/obj/item/clothing/suit/space/pirate/New()
	..()
	slowdown_per_slot[slot_wear_suit] = 0
