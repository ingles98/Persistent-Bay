//Yet another spaget cooked by Stigma. The HTML file is at html/designer.html. -- https://github.com/ingles98

/atom/var/designer_creator_ckey = "None - This icon wasn't created by the Designer feature."	//For blaming reasons
/atom/proc/GetDesign(var/icon/design, var/ckey) //Adds a general proc so any atom may be able to hook into the designer feature.

/obj/item/design_item //test item
	name = "designs"
	desc = "Test it out. ~Stigma"
	gender = NEUTER
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	var/icon/icon_custom
	var/list/pixel_list
	var/datum/designer/design

/obj/item/design_item/New()
	design = new(source = src)

/obj/item/design_item/verb/Design()
	set name = "Design tool by Stigma - DEBUG"
	set category = "Debug"
	design.pixel_width = text2num( input("Max Width:", "Designer DEBUG", 32) )
	design.pixel_height = text2num( input("Max Width:", "Designer DEBUG", 32) )
	design.Design()

/obj/item/design_item/GetDesign(var/icon/ico, ckey)
	if (!ico || !istype(ico) )
		return
	var/offset_x = text2num( input("Offset X:", "Designer DEBUG", 0) )
	var/offset_y = text2num( input("Offset Y:", "Designer DEBUG", 0) )
	ico.Shift(EAST, offset_x)
	ico.Shift(SOUTH, offset_y)
	icon = ico

	if (ckey)
		designer_creator_ckey = ckey


/////////////////////////////////////////////////////
/obj/item/weapon/paper_sketch
	name = "\improper sketch"
	desc = "\"Do I have to draw you a picture ?\""
	gender = NEUTER
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	var/icon/icon_custom
	var/list/pixel_list
	var/datum/designer/design

	var/icon/sketch //The sketch goes into this var
	var/sketch_width
	var/sketch_height

/obj/item/weapon/paper_sketch/New()
	if (!sketch) sketch = icon("icons/64x64.dmi", "def") //blank sketch
	sketch_width = sketch.Width()
	sketch_height = sketch.Height()
	message_admins("SKETCH CREATION: [sketch_width], [sketch_height]")
	design = new(source = src)

/obj/item/weapon/paper_sketch/attack_self(mob/living/user as mob)
	user.examinate(src)

/obj/item/weapon/paper_sketch/attackby(obj/item/weapon/P as obj, mob/user as mob)
	if (istype(P, /obj/item/weapon/pen))
		design.pixel_width = sketch_width
		design.pixel_height = sketch_height
		design.Design()

/obj/item/weapon/paper_sketch/GetDesign(var/icon/ico, ckey)
	if (!ico || !istype(ico) )
		message_admins("SKETCH: [ico] is not an icon. Ckey: [ckey]")
		qdel(ico)
		return
	sketch = ico

	if (ckey)
		designer_creator_ckey = ckey

/obj/item/weapon/paper_sketch/examine(mob/user)
	. = ..()
	if(name != initial(name) )
		to_chat(user, "It's titled '[name]'.")

	if(in_range(user, src) || isghost(user))
		show_content(usr)
	else
		to_chat(user, "<span class='notice'>You have to go closer if you want to read it.</span>")

/obj/item/weapon/paper_sketch/proc/show_content(mob/user, forceshow)
	set background = 1
	if (!sketch)
		message_admins("Error. paper_sketch bug, contact a dev plz...")
		return
	var/can_read = (istype(user, /mob/living/carbon/human) || isghost(user) || istype(user, /mob/living/silicon)) || forceshow
	usr << browse(file("html/designer_sketch.html"), "window=sketch;size=[sketch_width*3 +20]x[sketch_height*3 +20];can_close=1" )
	usr << output("href='?src=\ref[src];[sketch_width];[sketch_width]","sketch.browser:getData")
	var/sketch_data = "alert(\"WORKED\");"
	for (var/x = 1, x <= sketch_width, x++)
		for (var/y = 1, y <= sketch_height, y++)
			var/list/color_array = ReadRGB(sketch.GetPixel(x,y))
			if (!color_array || !color_array.len)
				//message_admins("SKETCH: No color array ([sketch.GetPixel(x,y)])")
				color_array = new/list()
				color_array.len = 4
				color_array[1] = 255
				color_array[2] = 0
				color_array[3] = 255
				color_array[4] = 255
			if (color_array.len < 4)
				color_array.len = 4
				color_array[4] = 255
			if (!can_read && prob(75))
				color_array[ rand(1, 4) ] = rand(1,255)
			if (!can_read && prob(30))
				color_array = new/list(0,0,0,0)
			//usr << output("[x];[y];[color_array[1]];[color_array[2]];[color_array[3]];[color_array[4]]","sketch.browser:getPixel")
			sketch_data += "pixel_map\[[x]\]\[[y]\].style.backgroundColor = rgb([color_array[1]],[color_array[2]],[color_array[3]]);"
			sketch_data += "pixel_map\[[x]\]\[[y]\].style.opacity = [color_array[4]]/255;"

	//text2file(sketch_data,sketch_file)
	//text2file(sketch_data,"DESIGNER_CACHE/sketch_data.js")
	//usr << browse_rsc("DESIGNER_CACHE/sketch_data.js")
	usr << output("[sketch_data]","sketch.browser:getImageData")


/////////////////////////////////////////////////

/datum/designer
	var/pixel_width = 8
	var/pixel_height = 8

	var/atom/my_atom

	var/list/colors
	var/icon/icon_custom

	var/creator_ckey

/datum/designer/New(source = null)
	if (source)
		my_atom = source


/datum/designer/proc/Design()
	usr << browse(file("html/designer.html"), "window=designer;size=600x400;can_close=1" )
	spawn(10)usr << output("href='?src=\ref[src];[pixel_width];[pixel_height]","designer.browser:getData")

/datum/designer/Topic(href,href_list[])
	switch(href_list["action"])
		if ("pixel")
			var/x = text2num(href_list["x"])
			var/y = text2num(href_list["y"])

			var/r = text2num(href_list["r"])
			var/g = text2num(href_list["g"])
			var/b = text2num(href_list["b"])
			var/alpha = text2num(href_list["a"])
			var/color = rgb(r,g,b,alpha)

			processIcon(color,x,y)
		if ("start")
			icon_custom = icon('icons/effects/effects.dmi', "icon_state"="nothing")
			creator_ckey = usr.ckey
		if ("stop")
			finishIcon()

/datum/designer/proc/processIcon(var/color,var/x,var/y)
	set background = 1
	icon_custom.DrawBox(color,x, y)
	sleep(-1)

/datum/designer/proc/finishIcon()
	icon_custom.Flip(NORTH)

	if (my_atom)
		my_atom.GetDesign(icon_custom, ckey = creator_ckey)
