# ConVar Configs
Performs some ConVar manipulation based on a configuration file.

## Purpose
Basically just exposes `ConVar.SetBounds()` and `ConVar.Flags` in an easy-to-read configuration file for server administration purposes.  Also provides a lower level ConVar lock (though I didn't know SourceMod's base commands already had that).

Handy for things like:
* Setting minumum and maximum values for `host_timescale`.
* Removing the upper bounds for `mp_bonusroundtime`.
* Stripping the cheat and development flags off of `tf_flamethrower_burstammo` and `mp_waitingforplayers_time` so they can be dropped into a config file without prefixing `sm_cvar`.
* Preventing changes to `sv_allow_point_servercommand`.
