hs.loadSpoon("spooner")

spoon.spooner:start {
  -- app names belonging to windows to fully ignore
  ignore = { "System Preferences" },
  -- default amount of master windows
  masters = 1,
  -- default amount of padding around windows
  pad = 8,
  -- amount to in- or decrease window padding by when calling `incPad` or `decPad`
  padStep = 8,
  -- time in seconds for windows to finish transitioning to a new frame
  transition = 0.1,
  -- modifier used for all key binds
  mod = "alt",
  keys = {
    { key = "i", run = "incMasters" },
    { key = "i", shift = true, run = "decMasters" },
    { key = "r", run = "rotate" },
    { key = "r", shift = true, run = "refresh" },
    { key = "p", run = "incPad" },
    { key = "p", shift = true, run = "decPad" },
    { key = "h", run = "focusWest" },
    { key = "j", run = "focusSouth" },
    { key = "k", run = "focusNorth" },
    { key = "l", run = "focusEast" },
    { key = "h", shift = true, run = "moveToScreenWest" },
    { key = "j", shift = true, run = "moveToScreenSouth" },
    { key = "k", shift = true, run = "moveToScreenNorth" },
    { key = "l", shift = true, run = "moveToScreenEast" },
  },
}

