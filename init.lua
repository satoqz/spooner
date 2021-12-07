-- Shortcuts
local window = hs.window
local hotkey = hs.hotkey

local spooner = {}

function spooner:start(options)
  self.ignore = options.ignore or {}
  self.pad = options.pad or 8
  self.padStep = options.padStep or 4
  self.masters = options.masters or 1
  self.mod = options.mod or "alt"
  self.keys = options.keys or {}
  self.transition = options.transition or 0.1

  local wf = window.filter.new()
  wf:subscribe({
    window.filter.windowNotOnScreen,
    window.filter.windowMoved,
  }, function()
    self:fullRefresh()
  end)

  -- We know which space to re-render in this event case
  wf:subscribe(window.filter.windowOnScreen, function(win)
    self:createSpaces()
    self:renderSpace(self:getSpace(win))
  end)

  self:bindKeys()
  self:fullRefresh()
end


function spooner:fullRefresh()
  self:createSpaces()
  self:renderSpaces()
end


function spooner:createSpaces()
  local wins = window.visibleWindows()

  -- Filter out all non standard windows, add frame info to the object
  local mapped = {}
  for _, w in ipairs(wins) do
    local ignored = false
    local appname = w:application():name()
    for _, test in ipairs(self.ignore) do
      if appname == test then
        ignored = true
      end
    end

    if w:isStandard() and not ignored then
      table.insert(mapped, {
        win   = w,
        frame = w:frame()
      })
    end
  end

  -- Sort windows by screen
  local screens = {}
  for _, w in ipairs(mapped) do
    local s = w.win:screen():frame()
    local existed = false
    for _, screen in ipairs(screens) do
      if not existed then
        local s2 = screen[1].win:screen():frame()
        if s2.x == s.x and s2.y == s.y then
          table.insert(screen, w)
          existed = true
        end
      end
    end
    if not existed then
      table.insert(screens, { w })
    end
  end

  -- sort each screen from north west to south east
  for _, screen in ipairs(screens) do
    table.sort(screen, function(a, b)
      if a.frame.x == b.frame.x then
        return a.frame.y < b.frame.y
      end
      return a.frame.x < b.frame.x
    end)
  end

  local spaces = {}
  for _, wns in ipairs(screens) do
    local count = #(wns)

    local space = {
      masters = {},
      stack = {}
    }

    if count > 0 then
      for i, w in ipairs(wns) do
        if i <= self.masters then
          table.insert(space.masters, w)
        else
          table.insert(space.stack, w)
        end
      end
    end

    table.insert(spaces, space)
  end

  self.spaces = spaces
end


function spooner:getSpace(win)
  local s = win:screen():frame()
  for _, space in ipairs(self.spaces) do
    local s2 = space.masters[1].win:screen():frame()
    if s.x == s2.x and s.y == s2.y then
      return space
    end
  end
end


function spooner:getActiveSpace()
  local win = window.frontmostWindow()
  if win then
    return self:getSpace(win)
  end
end


function spooner:renderSpace(space)
  local tiles = #(space.masters)
  if tiles == 0 then
    return
  end
  if #(space.stack) > 0 then
    tiles = tiles + 1
  end

  local s = space.masters[1].win:screen():frame()

  -- act as if the screen was smaller to create padding around the screen edges
  local halfpad = self.pad / 2
  s.w = s.w - self.pad
  s.h = s.h - self.pad
  s.x = s.x + halfpad
  s.y = s.y + halfpad

  for i, win in ipairs(space.masters) do
    local f = win.frame
    f.y = s.y + halfpad
    f.h = s.h - self.pad
    f.x = s.x + s.w / tiles * (i - 1) + halfpad
    f.w = s.w / tiles - self.pad
    win.win:setFrame(f, self.transition)
  end

  for i, win in ipairs(space.stack) do
    local f = win.frame
    f.x = s.x + s.w / tiles * (tiles - 1) + halfpad
    f.w = s.w / tiles - self.pad
    f.y = s.y + (i - 1) * s.h / #(space.stack) + halfpad
    f.h = s.h / #(space.stack) - self.pad
    win.win:setFrame(f, self.transition)
  end
end


function spooner:renderSpaces()
  for _, space in ipairs(self.spaces) do
    self:renderSpace(space)
  end
end

-- methods that can be bound to keys

function spooner:incMasters()
  self.masters = self.masters + 1
  self:fullRefresh()
end


function spooner:decMasters()
  if self.masters == 1 then
    return
  end
  self.masters = self.masters - 1
  self:fullRefresh()
end


function spooner:incPad()
  self.pad = self.pad + self.padStep
  self:renderSpaces()
end


function spooner:decPad()
  if self.pad - self.padStep < 0 then
    self.pad = 0
  else
    self.pad = self.pad - self.padStep
  end
  self:renderSpaces()
end


function spooner:rotate()
  local space = self:getActiveSpace()
  if not space then
    return
  end

  local masterCount = #(space.masters)
  if masterCount == 0 then
    return
  end

  local i = masterCount
  while i > 0 do
    space.masters[i + 1] = space.masters[i]
    i = i - 1
  end

  local stackCount = #(space.stack)
  if stackCount == 0 then
    space.masters[1] = space.masters[masterCount + 1]
  else
    i = stackCount
    while i > 0 do
      space.stack[i + 1] = space.stack[i]
      i = i - 1
    end
    space.stack[1] = space.masters[masterCount + 1]
    space.masters[1] = space.stack[stackCount + 1]
    table.remove(space.stack, stackCount + 1)
  end
  table.remove(space.masters, masterCount + 1)

  self:renderSpace(space)
end


function spooner:bindKeys()
  for _, key in ipairs(self.keys) do
    local mods = { self.mod }
    if key.shift then
      table.insert(mods, "shift")
    end

    local fns = {
      incMasters = function() self:incMasters() end,
      decMasters = function() self:decMasters() end,
      rotate     = function() self:rotate() end,
      refresh    = function() self:fullRefresh() end,
      incPad     = function() self:incPad() end,
      decPad     = function() self:decPad() end,
      focusNorth = function() window.frontmostWindow():focusWindowNorth() end,
      focusWest  = function() window.frontmostWindow():focusWindowWest() end,
      focusSouth = function() window.frontmostWindow():focusWindowSouth() end,
      focusEast  = function() window.frontmostWindow():focusWindowEast() end,
      moveToScreenNorth = function() window.frontmostWindow():moveOneScreenNorth() end,
      moveToScreenWest  = function() window.frontmostWindow():moveOneScreenWest() end,
      moveToScreenSouth = function() window.frontmostWindow():moveOneScreenSouth() end,
      moveToScreenEast  = function() window.frontmostWindow():moveOneScreenEast() end,
    }

    hotkey.bind(mods, key.key, fns[key.run] or function() end)
  end
end

-- Spoon metadata
spooner.name = "spooner"
spooner.version = "0.1.0"
spooner.author = "satoqz"
spooner.homepage = "https://github.com/satoqz/spooner"
spooner.license = "MIT - https://opensource.org/licenses/MIT"

return spooner
