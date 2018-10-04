var/datum/persisbase/PersisBase

/datum/persisbase
	var/DBConnection/persis_dbcon

/datum/persisbase/New()
	persis_dbcon = new()
	var/connected = persis_dbcon.Connect("dbi:mysql:[sqldb]:[sqladdress]:[sqlport]","[sqllogin]","[sqlpass]")
	if (!connected)
		usr << "Didn't work DBCON !"
		usr << "Connection failed: [persis_dbcon.ErrorMsg()]"

/datum/persisbase/proc/save_to_sql()
	var/DBQuery/qry = new()
	qry.Execute("SELECT * FROM `my_table`")
