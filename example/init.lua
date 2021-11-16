hs.loadSpoon("spooner")

spoon.spooner:start {
  ignore = { "System Preferences" },
  masters = 1,
  pad = 8,
  padStep = 8,
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

