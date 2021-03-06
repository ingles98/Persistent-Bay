/****************************************************
				INTERNAL ORGANS DEFINES
****************************************************/
/obj/item/organ/internal
	var/dead_icon // Icon to use when the organ has died.
	var/surface_accessible = FALSE
	var/relative_size = 25   // Relative size of the organ. Roughly % of space they take in the target projection :D
	var/list/will_assist_languages = list()
	var/list/datum/language/assists_languages = list()
	var/min_bruised_damage = 10       // Damage before considered bruised
	var/scarred = 0	// To what degree this organ is scarred
	var/scarring_effect = 3	// How much durability a scar will remove

/obj/item/organ/internal/New(var/mob/living/carbon/holder)
	if(max_health)
		min_bruised_damage = Floor(max_health / 4)
	..()
	if(istype(holder))
		holder.internal_organs |= src

		var/mob/living/carbon/human/H = holder
		if(istype(H))
			var/obj/item/organ/external/E = H.get_organ(parent_organ)
			if(!E)
				CRASH("[src] spawned in [holder] without a parent organ: [parent_organ].")
			E.internal_organs |= src
			E.cavity_max_w_class = max(E.cavity_max_w_class, w_class)

/obj/item/organ/internal/after_load()
	var/mob/living/carbon/human/H = loc
	if(istype(H))
		var/obj/item/organ/external/E = H.get_organ(parent_organ)
		E.cavity_max_w_class = max(E.cavity_max_w_class, w_class)
	..()
/obj/item/organ/internal/Destroy()
	if(owner)
		owner.internal_organs.Remove(src)
		owner.internal_organs_by_name[organ_tag] = null
		owner.internal_organs_by_name -= organ_tag
		while(null in owner.internal_organs)
			owner.internal_organs -= null
		var/obj/item/organ/external/E = owner.organs_by_name[parent_organ]
		if(istype(E)) E.internal_organs -= src
	return ..()

/obj/item/organ/internal/set_dna(var/datum/dna/new_dna)
	..()
	if(species && species.organs_icon)
		icon = species.organs_icon

//disconnected the organ from it's owner but does not remove it, instead it becomes an implant that can be removed with implant surgery
//TODO move this to organ/internal once the FPB port comes through
/obj/item/organ/proc/cut_away(var/mob/living/user)
	var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
	if(istype(parent)) //TODO ensure that we don't have to check this.
		removed(user, 0)
		parent.implants += src

/obj/item/organ/internal/removed(var/mob/living/user, var/drop_organ=1, var/detach=1)
	if(owner)
		owner.internal_organs_by_name[organ_tag] = null
		owner.internal_organs_by_name -= organ_tag
		owner.internal_organs_by_name -= null
		owner.internal_organs -= src

		if(detach)
			var/obj/item/organ/external/affected = owner.get_organ(parent_organ)
			if(affected)
				affected.internal_organs -= src
				status |= ORGAN_CUT_AWAY
	..()

/obj/item/organ/internal/replaced(var/mob/living/carbon/human/target, var/obj/item/organ/external/affected)

	if(!istype(target))
		return 0

	if(status & ORGAN_CUT_AWAY)
		return 0 //organs don't work very well in the body when they aren't properly attached

	// robotic organs emulate behavior of the equivalent flesh organ of the species
	if(robotic >= ORGAN_ROBOT || !species)
		species = target.species

	..()

	STOP_PROCESSING(SSobj, src)
	target.internal_organs |= src
	affected.internal_organs |= src
	target.internal_organs_by_name[organ_tag] = src
	return 1

/obj/item/organ/internal/die()
	..()
	if((status & ORGAN_DEAD) && dead_icon)
		icon_state = dead_icon

/obj/item/organ/internal/remove_rejuv()
	if(owner)
		owner.internal_organs -= src
		owner.internal_organs_by_name[organ_tag] = null
		owner.internal_organs_by_name -= organ_tag
		while(null in owner.internal_organs)
			owner.internal_organs -= null
		var/obj/item/organ/external/E = owner.organs_by_name[parent_organ]
		if(istype(E)) E.internal_organs -= src
	..()

/obj/item/organ/internal/is_usable()
	return ..() && !is_broken()

/obj/item/organ/internal/robotize()
	..()
	min_bruised_damage += 5
	min_broken_damage += 10

/obj/item/organ/internal/proc/getToxLoss()
	if(isrobotic())
		return get_damages() * 0.5
	return get_damages()

/obj/item/organ/internal/proc/bruise()
	if(get_damages() < min_bruised_damage)
		rem_health(min_bruised_damage - get_damages())

/obj/item/organ/internal/proc/is_bruised()
	return get_damages() >= min_bruised_damage

/obj/item/organ/internal/proc/isinplace()
	return (owner && parent_organ && owner.get_organ(parent_organ))

/obj/item/organ/internal/take_damage(damage, damagetype, armorbypass, damsrc, var/silent=0)
	if(isrobotic())
		damage = (damage * 0.8)
	else if(!silent && isinplace() && can_feel_pain() && (damage > min_bruised_damage/2 || prob(10)) )
		var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
		var/degree = ""
		if(is_bruised())
			degree = " a lot"
		else if((max_health - health) < min_bruised_damage/2)
			degree = " a bit"
		owner.custom_pain("Something inside your [parent.name] hurts[degree].", damage, affecting = parent)
	return ..(damage, damagetype, armorbypass, damsrc)

/obj/item/organ/internal/proc/get_visible_state()
	if(health <= 0)
		. = "bits and pieces of a destroyed "
	else if(is_broken())
		. = "broken "
	else if(is_bruised())
		. = "badly damaged "
	else if(get_damages() > 5)
		. = "damaged "
	else if(scarred == 1)
		. = "slightly scarred "
	else if(scarred == 2)
		. = "scarred "
	else if(scarred == 3)
		. = "heavily scarred "
	if(status & ORGAN_DEAD)
		if(can_recover())
			. = "decaying [.]"
		else
			. = "necrotic [.]"
	. = "[.][name]"

/obj/item/organ/internal/Process()
	..()
	handle_regeneration()

// Organs will heal very minor damage on their own without much work
// As long as no toxins are present in the system
/obj/item/organ/internal/proc/handle_regeneration()
	if(!isdamaged() || isrobotic() || !owner || owner.chem_effects[CE_TOXIN])
		return
	if(get_damages() < min_bruised_damage) // If it's not even bruised, it will just heal very slowly.
		heal_damage(0.01)
	else if(is_bruised()) // If it is bruised, it will heal a little faster, but it will scar if it's not aided by medication or surgery
	//	if(((damage - 0.02) < (min_bruised_damage)) && (scarred < 3))
	//		scarred++
	//		max_damage -= scarring_effect
	//		min_broken_damage -= scarring_effect
		heal_damage(0.02)

/obj/item/organ/internal/emp_act(severity)
	..()
//	if(severity > 1 && scarred <3) // A strong enough EMP can mess up your robotic organs permanantly
//		scarred++

/obj/item/organ/internal/examine(mob/user)
	if(!..(user, 1))
		return 0

	to_chat(user, "<span class='neutral'>You examine the [get_visible_state()].</span>")
	return 1
// Shows the damage of the organ when examined.
