-- luacheck: globals unpack
local unpack = unpack or table.unpack

local M = {}

M.WILDCARD      = "*"
M.DEFERRED      = 0
M.SUCCEEDED     = 1
M.NO_TRANSITION = 2
M.PENDING       = 3
M.CANCELLED     = 4

local function do_callback(handler, args)
  if handler then
    return handler(unpack(args))
  end
end

local function before_event(self, event, _, _, args)
  local specific = do_callback(self["on_before_" .. event], args)
  local general = do_callback(self["on_before_event"], args)

  if specific == false or general == false then
    return false
  end
end

local function leave_state(self, _, from, _, args)
  local specific = do_callback(self["on_leave_" .. from], args)
  local general = do_callback(self["on_leave_state"], args)

  if specific == false or general == false then
    return false
  end
  if specific == M.DEFERRED or general == M.DEFERRED then
    return M.DEFERRED
  end
end

local function enter_state(self, _, _, to, args)
  do_callback(self["on_enter_" .. to] or self["on_" .. to], args)
  do_callback(self["on_enter_state"] or self["on_state"], args)
end

local function after_event(self, event, _, _, args)
  do_callback(self["on_after_" .. event] or self["on_" .. event], args)
  do_callback(self["on_after_event"] or self["on_event"], args)
end

local function build_transition(self, event, states)
  return function (...)
    local from = self.current
    local to = states[from] or states[M.WILDCARD] or from
    local args = {self, event, from, to, ...}

    assert(not self.is_pending(),
      "previous transition still pending")

    assert(self.can(event),
      "invalid transition from state '" .. from .. "' with event '" .. event .. "'")

    local before = before_event(self, event, from, to, args)
    if before == false then
      return M.CANCELLED
    end

    if from == to then
      after_event(self, event, from, to, args)
      return M.NO_TRANSITION
    end

    self.confirm = function ()
      self.confirm = nil
      self.cancel = nil

      self.current = to

      enter_state(self, event, from, to, args)
      after_event(self, event, from, to, args)

      return M.SUCCEEDED
    end

    self.cancel = function ()
      self.confirm = nil
      self.cancel = nil

      after_event(self, event, from, to, args)

      return M.CANCELLED
    end

    local leave = leave_state(self, event, from, to, args)
    if leave == false then
      return M.CANCELLED
    end
    if leave == M.DEFERRED then
      return M.PENDING
    end

    if self.confirm then
      return self.confirm()
    end
  end
end

function M.create(cfg, target)
  local self = target or {}

  -- Initial state.
  local initial = cfg.initial
  -- Allow for a string, or a map like `{state = "foo", event = "setup"}`.
  initial = type(initial) == "string" and {state = initial} or initial

  -- Initial event.
  local initial_event = initial and initial.event or "startup"

  -- Terminal state.
  local terminal = cfg.terminal

  -- Events.
  local events = cfg.events or {}

  -- Callbacks.
  local callbacks = cfg.callbacks or {}

  -- Track state transitions allowed for an event.
  local states_for_event = {}

  -- Track events allowed from a state.
  local events_for_state = {}

  local function add(e)
    -- Allow wildcard transition if `from` is not specified.
    local from = type(e.from) == "table" and e.from or (e.from and {e.from} or {M.WILDCARD})
    local to = e.to
    local event = e.name

    states_for_event[event] = states_for_event[event] or {}
    for _, fr in ipairs(from) do
      events_for_state[fr] = events_for_state[fr] or {}
      table.insert(events_for_state[fr], event)

      -- Allow no-op transition if `to` is not specified.
      states_for_event[event][fr] = to or fr
    end
  end

  if initial then
    add({name = initial_event, from = "none", to = initial.state})
  end

  for _, event in ipairs(events) do
    add(event)
  end

  for event, states in pairs(states_for_event) do
    self[event] = build_transition(self, event, states)
  end

  for name, callback in pairs(callbacks) do
    self[name] = callback
  end

  self.current = "none"

  function self.is(state)
    if type(state) == "table" then
      for _, s in ipairs(state) do
        if self.current == s then
          return true
        end
      end

      return false
    end

    return self.current == state
  end

  function self.can(event)
    local states = states_for_event[event]
    local to = states[self.current] or states[M.WILDCARD]
    return to ~= nil
  end

  function self.cannot(event)
    return not self.can(event)
  end

  function self.transitions()
    return events_for_state[self.current]
  end

  function self.is_pending()
    return self.confirm ~= nil
  end

  function self.is_finished()
    return self.is(terminal)
  end

  if initial and not initial.defer then
    self[initial_event]()
  end

  return self
end

return M
