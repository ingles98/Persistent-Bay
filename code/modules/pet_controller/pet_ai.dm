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
    message_admins("checking nearby humanz lamo [passive_affinity_range]")
    for(var/mob/living/carbon/human/A in view(passive_affinity_range, src.my_mob) )
        message_admins("HUMAN FOUND")
        if (A.client)
            message_admins("HUMAN FOUND w/client")
            incrementAffinity(A.real_name, passive_affinity_gain + passive_affinity_loss)

/datum/pet_controller/proc/handle_gradualAffinityLoss()
    for(var/name in src.affinity)
        incrementAffinity(name, -passive_affinity_loss)

/datum/pet_controller/proc/updateOwnership()
    var/max_owners = src.max_owners
    if (length(src.affinity) < max_owners)
        max_owners = length(src.affinity)
    if (max_owners < 1)
        return FALSE
    var/list/affinity = src.affinity.Copy()
    src.owners = new()
    for (var/i = 1, i <= max_owners)
        var/list/highest_affinity_owner = getHighestAffinity(affinity)
        if (!highest_affinity_owner["name"])
            return FALSE
        affinity -= highest_affinity_owner["name"]
        src.owners += highest_affinity_owner["name"]

/datum/pet_controller/proc/onFriendlyTouch(var/mob/living/carbon/human/M)
    if (!istype(M))
        return FALSE
    if (active_affinity_onCooldown)
        return FALSE

    active_affinity_onCooldown = TRUE
    spawn(active_affinity_gain_cooldown)
        active_affinity_onCooldown = FALSE

    incrementAffinity(M.real_name, active_affinity_gain)

/datum/pet_controller/proc/update()
    age++
    if (!passive_affinity_onCooldown)
        passive_affinity_onCooldown = TRUE
        spawn(passive_affinity_cooldown)
            passive_affinity_onCooldown = FALSE
        handle_nearbyAffinity()
        handle_gradualAffinityLoss()
    updateOwnership()