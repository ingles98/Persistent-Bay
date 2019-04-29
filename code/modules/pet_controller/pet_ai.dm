/mob/living/simple_animal
	var/datum/pet_controller/pet_controller

/mob/living/simple_animal/cat/New()
	..()
	pet_controller = new(my_mob = src)

/datum/pet_controller/
	should_save = 1

	var/list/affinity = new()
	var/age = 0 //The age as in TICKS. This is so we actually know the amount of Life() processes this animal has had.

	var/max_owners = 1
	var/list/owners = new()

	var/mob/living/simple_animal/my_mob

	var/passive_affinity_range = 4
	var/passive_affinity_gain = 0.4
	var/passive_affinity_loss = 0.005
	var/passive_affinity_cooldown = 10 SECONDS
	var/passive_affinity_onCooldown = FALSE

	var/active_affinity_gain = 25
	var/active_affinity_gain_cooldown = 1 MINUTES
	var/active_affinity_onCooldown = FALSE

	var/hostile_active_affinity_loss = 50
	var/hostile_active_affinity_loss_bonusMultiplier = 5	  //"bonus" is equal to the damage dealt to the mob in this context

	var/updateOwnership_onCooldown = FALSE
	var/updateOwnership_cooldown = 60 SECONDS

/datum/pet_controller/New(var/mob/living/simple_animal/my_mob)
	if (! istype(my_mob) )
		qdel(src)
		return 0
	src.my_mob = my_mob
	return 1

/datum/pet_controller/proc/getHighestAffinity(var/list/affinity = src.affinity)
	var/list/highest_affinity = list("name" = null, "affinity" = null)
	for (var/name in affinity)
		if (affinity[name] > highest_affinity["affinity"] || !highest_affinity["name"] || !highest_affinity["affinity"])
			highest_affinity["name"] = name
			highest_affinity["affinity"] = affinity[name]
	return highest_affinity

/datum/pet_controller/proc/incrementAffinity(var/name, var/delta)
	if (!affinity[name])
		affinity[name] = delta
		return
	affinity[name] = affinity[name] + delta

/datum/pet_controller/proc/handle_nearbyAffinity()
	for(var/mob/living/carbon/human/A in view(passive_affinity_range, src.my_mob) )
		if (A.client)
			incrementAffinity(A.real_name, passive_affinity_gain + passive_affinity_loss)

/datum/pet_controller/proc/handle_gradualAffinityLoss()
	for(var/name in src.affinity)
		incrementAffinity(name, -passive_affinity_loss)
	
/datum/pet_controller/proc/updateOwnership()
	src.owners.Cut()
	var/max = src.max_owners
	if (length(src.affinity) < max)
		max = length(src.affinity)
	if (max < 1)
		return FALSE
	var/list/affinity = src.affinity.Copy()
	for (var/x = 1, x <= max, x++)
		var/list/highest_affinity_owner = getHighestAffinity(affinity)
		if (!highest_affinity_owner["name"])
			return FALSE
		affinity -= highest_affinity_owner["name"]
		src.owners += highest_affinity_owner["name"]

/datum/pet_controller/proc/onFriendlyAct(var/mob/living/carbon/human/M)
	if (!istype(M) || my_mob.stat == DEAD || active_affinity_onCooldown)
		return FALSE

	active_affinity_onCooldown = TRUE
	spawn(active_affinity_gain_cooldown)
		active_affinity_onCooldown = FALSE

	incrementAffinity(M.real_name, active_affinity_gain)

/datum/pet_controller/proc/onHostileAct(var/mob/living/carbon/human/M, var/bonus = 0)
	if (!istype(M) || my_mob.stat == DEAD)
		return FALSE
	incrementAffinity(M.real_name, -(hostile_active_affinity_loss + bonus*hostile_active_affinity_loss_bonusMultiplier) )

/datum/pet_controller/proc/update()
	age++

	if (!passive_affinity_onCooldown)
		passive_affinity_onCooldown = TRUE
		spawn(passive_affinity_cooldown)
			passive_affinity_onCooldown = FALSE
		handle_nearbyAffinity()
		handle_gradualAffinityLoss()

	if (!updateOwnership_onCooldown)
		updateOwnership_onCooldown = TRUE
		spawn(updateOwnership_cooldown)
			updateOwnership_onCooldown = FALSE
		updateOwnership()