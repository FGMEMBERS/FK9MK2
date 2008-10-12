# Maik Justus 

if (!contains(globals, "cprint")) {
	globals.cprint = func {};
}

var optarg = aircraft.optarg;
var makeNode = aircraft.makeNode;

var sin = func(a) { math.sin(a * math.pi / 180.0) }
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var pow = func(v, w) { math.exp(math.ln(v) * w) }
var npow = func(v, w) { math.exp(math.ln(abs(v)) * w) * (v < 0 ? -1 : 1) }
var clamp = func(v, min = 0, max = 1) { v < min ? min : v > max ? max : v }
var normatan = func(x) { math.atan2(x, 1) * 2 / math.pi }





# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/fk9mk2/lighting/strobe-bottom", [0.05, 1.03], strobe_switch);



# nav lights ========================================================
var nav_light_switch = props.globals.getNode("controls/lighting/nav-lights", 1);
var visibility = props.globals.getNode("environment/visibility-m", 1);
var sun_angle = props.globals.getNode("sim/time/sun-angle-rad", 1);
var nav_lights = props.globals.getNode("sim/model/fk9mk2/lighting/nav-lights", 1);

var nav_light_loop = func {
	if (nav_light_switch.getValue()) {
		nav_lights.setValue(visibility.getValue() < 5000 or sun_angle.getValue() > 1.4);
	} else {
		nav_lights.setValue(0);
	}
	settimer(nav_light_loop, 3);
}

settimer(nav_light_loop, 0);






# instruments
var airspeed_kt = props.globals.getNode("velocities/airspeed-kt", 1);
var out_airspeed_kmh = props.globals.getNode("sim/fk9mk2/airspeed-kmh", 1);
var engine_rpm = props.globals.getNode("engines/engine/rpm", 1);
var out_engine_rpm = props.globals.getNode("sim/fk9mk2/engine-rpm", 1);

var update_instruments = func(dt) {
	out_airspeed_kmh.setValue(airspeed_kt.getValue() * 1.852);
	out_engine_rpm.setValue(engine_rpm.getValue());
}




# crash handler =====================================================
#var load = nil;
var crash = func {
	if (arg[0]) {
		# crash
		strobe_switch.setValue(0);
		nav_light_switch.setValue(0);

	} else {
		# uncrash (for replay)
		strobe_switch.setValue(1);
	}
}




# view management ===================================================

var elapsedN = props.globals.getNode("/sim/time/elapsed-sec", 1);




# main() ============================================================
var delta_time = props.globals.getNode("/sim/time/delta-realtime-sec", 1);

var main_loop = func {

	var dt = delta_time.getValue();
	update_instruments(dt);
	settimer(main_loop, 0);
}


var crashed = 0;


# initialization
setlistener("/sim/signals/fdm-initialized", func {


	setlistener("/sim/signals/reinit", func(n) {
		n.getBoolValue() and return;
		cprint("32;1", "reinit");
		crashed = 0;
	});

	setlistener("sim/crashed", func(n) {
		cprint("31;1", "crashed ", n.getValue());
		if (n.getBoolValue()) {
			crash(crashed = 1);
		}
	});

	setlistener("/sim/freeze/replay-state", func(n) {
		cprint("33;1", n.getValue() ? "replay" : "pause");
		if (crashed) {
			crash(!n.getBoolValue())
		}
	});

	# the attitude indicator needs pressure
	# settimer(func { setprop("engines/engine/rpm", 3000) }, 8);

	main_loop();
});


