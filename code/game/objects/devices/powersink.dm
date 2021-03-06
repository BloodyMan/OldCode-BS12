// Powersink - used to drain station power

/obj/item/device/powersink
	desc = "A nulling power sink which drains energy from electrical systems."
	name = "power sink"
	icon_state = "powersink0"
	item_state = "electronic"
	w_class = 4.0
	flags = FPRINT | TABLEPASS | CONDUCT
	throwforce = 5
	throw_speed = 1
	throw_range = 2
	m_amt = 750
	w_amt = 750
	var/drain_rate = 200000		// amount of power to drain per tick
	var/power_drained = 0 		// has drained this much power
	var/max_power = 1e8		// maximum power that can be drained before exploding
	var/mode = 0		// 0 = off, 1=clamped (off), 2=operating


	var/obj/cabling/attached		// the attached cable

	attackby(var/obj/item/I, var/mob/user)
		if(istype(I, /obj/item/weapon/screwdriver))
			if(mode == 0)
				var/turf/T = loc
				if(isturf(T) && !T.intact)
					for(var/obj/cabling/Cable in T)
						if(Cable.type == /obj/cabling/power)
							attached = Cable
							break
					if(!attached)
						user << "No exposed electrical cable here to attach to."
						return
					else
						anchored = 1
						mode = 1
						user << "You attach the device to the electrical cable."
						for(var/mob/M in viewers(user))
							if(M == user) continue
							M << "[user] attaches the power sink to the electrical cable."
						return
				else
					user << "Device must be placed over an exposed electrical cable to attach to it."
					return
			else
				anchored = 0
				mode = 0
				attached = null
				user << "You detach	the device from the electrical cable."
				for(var/mob/M in viewers(user))
					if(M == user) continue
					M << "[user] detaches the power sink from the electrical cable."
				ul_SetLuminosity(0)
				icon_state = "powersink0"
				return
		else
			..()



	attack_paw()
		return

	attack_ai()
		return

	attack_hand(var/mob/user)
		switch(mode)
			if(0)
				..()

			if(1)
				user << "You activate the device!"
				for(var/mob/M in viewers(user))
					if(M == user) continue
					M << "[user] activates the power sink!"
				mode = 2
				icon_state = "powersink1"
				processing_items.Add(src)

	process()
		if(attached)
			var/datum/UnifiedNetwork/Network = attached.Networks[attached.type]
			var/datum/UnifiedNetworkController/PowernetController/Controller = Network.Controller
			if(Network)
				if(!luminosity)
					ul_SetLuminosity(12)


				// found a powernet, so drain up to max power from it

				var/drained = min ( drain_rate, Controller.Power )
				Controller.DrawPower(drained)
				power_drained += drained

				// if tried to drain more than available on powernet
				// now look for APCs and drain their cells
				if(drained < drain_rate)
					for(var/obj/machinery/power/terminal/T in Network.Nodes)
						if(istype(T.master, /obj/machinery/power/apc))
							var/obj/machinery/power/apc/A = T.master
							if(A.operating && A.cell)
								A.cell.charge = max(0, A.cell.charge - 50)
								power_drained += 50


			if(power_drained > max_power * 0.95)
				playsound(src, 'sound/effects/screech.ogg', 100, 1, 1)
			if(power_drained >= max_power)
				processing_items.Remove(src)
				explosion(src.loc, 3,6,9,12,1)
				del(src)
