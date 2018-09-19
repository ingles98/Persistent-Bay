//Just like the airlock controllers, except it doesn't use radio, and actually works.

#define STATE_IDLE			 0
#define STATE_PREPARE		 1
#define STATE_DEPRESSURIZE	 2
#define STATE_PRESSURIZE	 3

#define TARGET_NONE			 0
#define TARGET_INOPEN		-1
#define TARGET_OUTOPEN		-2

/obj/item/frame/airlock_controller_norad // The frame
    name = "Airlock Controller"
    desc = "Used for building airlock controllers."
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_control_off"
	refund_amt = 2
	build_machine_type = /obj/machinery/airlock_controller_norad

/obj/machinery/airlock_controller_norad
    name = "Airlock Controller"
    desc = "A controller for automatic air cycling."
    icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_control_standby"

    var/type_frame = /obj/item/frame/airlock_controller_norad

    var/list/memory = new()

	var/obj/machinery/door/airlock/tag_exterior_door
	var/obj/machinery/door/airlock/tag_interior_door
	var/obj/machinery/atmospherics/unary/vent_pump/tag_airpump
    var/obj/machinery/atmospherics/unary/vent_scrubber/tag_scrubber
	var/obj/machinery/airlock_sensor/tag_exterior_sensor
	var/obj/machinery/airlock_sensor/tag_interior_sensor
	var/tag_secure = 0

    var/state = STATE_IDLE
    var/target_state = state

	var/cycle_to_external_air = 0

    var/safety_lock = 1           // You can only crowbar it off if safety is off by accessing the UI.

/obj/machinery/airlock_controller_norad/New(location, ndir, source)
    ..()
    dir = ndir
    memory["chamber_sensor_pressure"] = ONE_ATMOSPHERE
    memory["external_sensor_pressure"] = 0					//assume vacuum for simple airlock controller
    memory["internal_sensor_pressure"] = ONE_ATMOSPHERE
    memory["exterior_status"] = list(state = "closed", lock = "locked")		//assume closed and locked in case the doors dont report in
    memory["interior_status"] = list(state = "closed", lock = "locked")
    memory["pump_status"] = "unknown"
    memory["target_pressure"] = ONE_ATMOSPHERE
    memory["purge"] = 0
    memory["secure"] = 0
    memory["processing"] = (state != target_state)

/obj/machinery/airlock_controller_norad/CanUseTopic(var/mob/user)
	if(!allowed(user))
		return min(STATUS_UPDATE, ..())
	else
		return ..()

/obj/machinery/airlock_controller_norad/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/nano_ui/master_ui = null, var/datum/topic_state/state = GLOB.default_state)

    var/err = check_for_errors()
    if (err)
        to_chat(user, "<span class='warning'>Error: [err]</span>")

    memory["processing"] = (state != target_state)
    var/data[0]
	data = list(
		"chamber_pressure" = round(memory["chamber_sensor_pressure"]),
		"external_pressure" = round(memory["external_sensor_pressure"]),
		"internal_pressure" = round(memory["internal_sensor_pressure"]),
		"processing" = memory["processing"],
		"purge" = memory["purge"],
		"secure" = safety_lock
	)

	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)

	if (!ui)
		ui = new(user, src, ui_key, "advanced_airlock_console_norad.tmpl", name, 470, 290, state = state)

		ui.set_initial_data(data)

		ui.open()

		ui.set_auto_update(1)

/obj/machinery/airlock_controller_norad/Topic(href, href_list)
	if(..())
		return

	usr.set_machine(src)
	src.add_fingerprint(usr)

    var/clean
	switch(href_list["command"])
		if("cycle_ext")
            clean = 1
            cycle_air("ext")
		if("cycle_int")
            clean = 1
            cycle_air("int")
		if("force_ext")
            clean = 1
            cycle_doors("ext")
		if("force_int")
            clean = 1
            cycle_doors("int")
		if("abort")
            clean = 1
            if (target_state == TARGET_INOPEN)
                target_state = TARGET_OUTOPEN
            if (target_state == TARGET_OUTOPEN)
                target_state = TARGET_INOPEN
		if("purge")
            clean = 1
		if("secure")
            clean = 1
            safety_lock = !safety_lock

    if (!clean)
        return


	return 1

/obj/machinery/airlock_controller_norad/Process()
    ..()
    if (state != target_state)
        state = STATE_PREPARE
    if (state == STATE_IDLE)
        return

        /*var/datum/gas_mixture/air_sample = return_air()
    		if(!air_sample)
    			qdel(src)
    			return
    		var/pressure = round(air_sample.return_pressure(),0.1)*/
    var/datum/gas_mixture/air_chamber = return_air()
    var/current_pressure = round(air_chamber.return_pressure(),0.1)
    // Updates current pressure.
    memory["chamber_sensor_pressure"] = current_pressure
    memory["external_sensor_pressure"] = get_pressure("ext")
    memory["internal_sensor_pressure"] = get_pressure("int")

    var/target_pressure
    if (target_state == TARGET_INOPEN)
        target_pressure = get_pressure("int")
    else if (target_state == TARGET_OUTOPEN)
        target_pressure = get_pressure("ext")

    if (target_pressure > current_pressure)
        vent("in", target_pressure)
    if (target_pressure < current_pressure)
        vent("out", target_pressure)
    if (target_pressure -3 < current_pressure && current_pressure < target_pressure +3) // Hardcoded pressure tolerance of -/+3 (6kPa difference max)
        vent("stop")
        state = target_state
    if (state == target_state) //finish the process, open the door,
        cycle_doors()
        state = STATE_IDLE
        target_state = state

/obj/machinery/airlock_controller_norad/attackby(var/obj/item/O as obj, var/mob/user as mob)
    if (isCrowbar(O) && !safety_lock)
        //PUT SOUND HERE... LATA.
        new type_frame (loc)
        for (obj/O in components)
            O.loc = src.loc
        qdel(src)
    else if (isMultitool(O))
        if (!buffer_object)
            buffer_object = src
            to_chat(user, "<span class='notice'>You add \the [src] to the buffer. </span>")
        else
            buffer_object = null
            to_chat(user, "<span class='notice'>You flush the buffer from your [O]. </span>")
    else
        ..()

/obj/machinery/airlock_controller_norad/proc/check_for_errors()
    if ( !tag_exterior_door || !tag_interior_door || !tag_airpump || !tag_scrubber || !tag_exterior_sensor || !tag_interior_sensor)
        return "Missing device"
    return 0

/obj/machinery/airlock_controller_norad/proc/vent(var/stat, var/pressure)
    if (stat == "from_chamber")
        tag_scrubber.scrubbing = 0
    if (stat == "to_chamber")
        tag_scrubber.scrubbing = 1
    tag_airpump.external_pressure_bound = pressure

/obj/machinery/airlock_controller_norad/proc/cycle_air(var/target)
    if (!str)
        return 0
    if (target == "ext")
        target_state = TARGET_OUTOPEN
    else if (target == "int")
        target_state = TARGET_INOPEN

    tag_interior_door.locked = 0
    tag_exterior_door.locked = 0
    tag_interior_door.close()
    tag_exterior_door.close()
    tag_interior_door.locked = 1
    tag_exterior_door.locked = 1

    if (!tag_exterior_door.density || !tag_interior_door.density) //if any of the doors remains open, we won't initiate the process.
        target_state = state

/obj/machinery/airlock_controller_norad/proc/cycle_doors(var/door, var/door_state)
    if (door) //specific door toggle
        if (door == "int")
            if (door_state)
                tag_interior_door.locked = 0
                tag_interior_door.open()
            else
                tag_interior_door.close()
                tag_interior_door.locked = 1
        if (door == "ext")
            if (door_state)
                tag_exterior_door.locked = 0
                tag_exterior_door.open()
            else
                tag_exterior_door.close()
                tag_exterior_door.locked = 1
        return
    else
        if (target_state == TARGET_INOPEN)
            tag_interior_door.locked = 0
            tag_interior_door.open()
        if (target_state == TARGET_OUTOPEN)
            tag_exterior_door.locked = 0
            tag_exterior_door.open()

/obj/machinery/airlock_controller_norad/proc/get_pressure(var/target)
    var/pressure = 0
    if (target == "int" && tag_interior_sensor.air_contents) // interior sensor is MUST.
        pressure = round(tag_interior_sensor.air_contents.return_pressure(), 0.1)
    if (target == "ext" && tag_exterior_sensor && tag_exterior_sensor.air_contents) //if no exterior sensor, it'll act as if target pressure is 0kpa.
        pressure = round(tag_exterior_sensor.air_contents.return_pressure(), 0.1)
    return pressure


#undef STATE_IDLE
#undef STATE_DEPRESSURIZE
#undef STATE_PRESSURIZE

#undef TARGET_NONE
#undef TARGET_INOPEN
#undef TARGET_OUTOPEN
