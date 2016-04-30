-- luacheck: globals unpack
local unpack = unpack or table.unpack

local M = {}

local function do_callback(handler, args)
  if handler then
    return handler(unpack(args))
  end
end

local function build_transition(self, event, states)
  return function (...)
    local from = self.current
    local to = states[from] or states["*"] or from
    local args = {self, event, from, to, ...}

    assert(self.can(event),
      "cannot transition from state '" .. from .. "' with event '" .. event .. "'")

    if do_callback(self["on_before_" .. event], args) == false
    or do_callback(self["on_before_event"], args) == false
    or do_callback(self["on_leave_" .. from], args) == false
    or do_callback(self["on_leave_state"], args) == false then
      return false
    end

    self.current = to

    do_callback(self["on_enter_" .. to] or self["on_" .. to], args)
    do_callback(self["on_enter_state"] or self["on_state"], args)
    do_callback(self["on_change_state"], args)
    do_callback(self["on_after_" .. event] or self["on_" .. event], args)
    do_callback(self["on_after_event"] or self["on_event"], args)

    return true
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
    local from = type(e.from) == "table" and e.from or (e.from and {e.from} or {"*"})
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
    local to = states[self.current] or states["*"]
    return to ~= nil
  end

  function self.cannot(event)
    return not self.can(event)
  end

  function self.transitions()
    return events_for_state[self.current]
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
