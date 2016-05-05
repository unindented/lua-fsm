# lua-fsm [![Version](https://img.shields.io/badge/luarocks-1.1.0-blue.svg)](https://luarocks.org/modules/unindented/fsm) [![Build Status](https://img.shields.io/travis/unindented/lua-fsm.svg)](http://travis-ci.org/unindented/lua-fsm) [![Coverage Status](https://img.shields.io/coveralls/unindented/lua-fsm.svg)](https://coveralls.io/r/unindented/lua-fsm)

A simple finite-state machine implementation for Lua. Based on [@jakesgordon's `javascript-finite-state-machine`](https://github.com/jakesgordon/javascript-state-machine).


## Installation

You can install through [LuaRocks](https://luarocks.org/):

```
$ luarocks install fsm
```

Or just download manually:

```
$ wget https://github.com/unindented/lua-fsm/raw/master/src/fsm.lua
```


## Usage

### Initialization

You can create a new state machine by doing something like:

```lua
local fsm = require "fsm"

local alert = fsm.create({
  initial = "green",
  events = {
    {name = "warn",  from = "green",  to = "yellow"},
    {name = "panic", from = "yellow", to = "red"   },
    {name = "calm",  from = "red",    to = "yellow"},
    {name = "clear", from = "yellow", to = "green" }
  }
})
```

This will create an object with a method for each event:

* `alert.warn()`  - causes the machine to transition from `green` to `yellow`
* `alert.panic()` - causes the machine to transition from `yellow` to `red`
* `alert.calm()`  - causes the machine to transition from `red` to `yellow`
* `alert.clear()` - causes the machine to transition from `yellow` to `green`

along with the following:

* `alert.current`       - contains the current state
* `alert.is(s)`         - returns `true` if state `s` is the current state
* `alert.can(e)`        - returns `true` if event `e` can be fired in the current state
* `alert.cannot(e)`     - returns `true` if event `e` cannot be fired in the current state
* `alert.transitions()` - returns the list of events that are allowed from the current state

If you don't specify any initial state, the state machine will be in the `none` state, and you would need to provide an event to take it out of this state:

```lua
local alert = fsm.create({
  events = {
    {name = "startup", from = "none",  to = "green"},
    {name = "panic",   from = "green", to = "red"  },
    {name = "calm",    from = "red",   to = "green"}
  }
})

print(alert.current) -- "none"
alert.startup()
print(alert.current) -- "green"
```

If you specify the name of your initial state, then an implicit `startup` event will be created for you and fired when the state machine is constructed:

```lua
local alert = fsm.create({
  initial = "green",
  events = {
    {name = "panic", from = "green", to = "red"  },
    {name = "calm",  from = "red",   to = "green"}
  }
})

print(alert.current) -- "green"
```

If your object already has a `startup` method you can use a different name for the initial event:

```lua
local alert = fsm.create({
  initial = {state = "green", event = "init"},
  events = {
    {name = "panic", from = "green", to = "red"  },
    {name = "calm",  from = "red",   to = "green"}
  }
})

print(alert.current) -- "green"
```

Finally, if you want to wait to call the initial state transition event until a later date you can defer it:

```lua
local alert = fsm.create({
  initial = {state = "green", event = "init", defer = true},
  events = {
    {name = "panic", from = "green", to = "red"  },
    {name = "calm",  from = "red",   to = "green"}
  }
})

print(alert.current) -- "none"
alert.init()
print(alert.current) -- "green"
```

### Callbacks

Four types of callback are available by attaching methods to your state machine, using the following naming conventions (where `<EVENT>` and `<STATE>` get replaced with your different event and state names):

* `on_before_<EVENT>` - fired before the event
* `on_leave_<STATE>`  - fired when leaving the old state
* `on_enter_<STATE>`  - fired when entering the new state
* `on_after_<EVENT>`  - fired after the event

For convenience, the 2 most useful callbacks can be shortened:

* `on_<EVENT>` - convenience shorthand for `on_after_<EVENT>`
* `on_<STATE>` - convenience shorthand for `on_enter_<STATE>`

In addition, four general-purpose callbacks can be used to capture **all** event and state changes:

* `on_before_event` - fired before *any* event
* `on_leave_state`  - fired when leaving *any* state
* `on_enter_state`  - fired when entering *any* state
* `on_after_event`  - fired after *any* event

All callbacks will be passed the same arguments:

* **self** (the finite-state machine that generated the transition)
* **event** name
* **from** state
* **to** state
* *(followed by any arguments you passed into the original event method)*

Callbacks can be specified when the state machine is first created:

```lua
local fsm = require "fsm"

local alert = fsm.create({
  initial = "green",
  events = {
    {name = "warn",  from = "green",  to = "yellow"},
    {name = "panic", from = "yellow", to = "red"   },
    {name = "calm",  from = "red",    to = "yellow"},
    {name = "clear", from = "yellow", to = "green" }
  },
  callbacks = {
    on_panic = function(self, event, from, to, msg) print('panic! ' .. msg)  end,
    on_clear = function(self, event, from, to, msg) print('phew... ' .. msg) end
  }
})

alert.warn()
alert.panic('killer bees')
alert.calm()
alert.clear('they are gone now')
```

The order in which callbacks occur is as follows, assuming event `calm` transitions from `red` state to `yellow`:

 * `on_before_calm`  - specific handler for the **calm** event only
 * `on_before_event` - generic  handler for all events
 * `on_leave_red`    - specific handler for the **red** state only
 * `on_leave_state`  - generic  handler for all states
 * `on_enter_yellow` - specific handler for the **yellow** state only
 * `on_enter_state`  - generic  handler for all states
 * `on_after_calm`   - specific handler for the **calm** event only
 * `on_after_event`  - generic  handler for all events

### Deferred state transitions

You may need to execute additional code during a state transition, and ensure the new state is not entered until your code has completed, e.g. fading a menu screen.

One way to do this is to return `fsm.DEFERRED` from your `on_leave_state` handler, and the state machine will be put on hold until you are ready to confirm the transition by calling the `confirm` method, or cancel it by calling the `cancel` method:

```lua
local screens = fsm.create({
  initial = "menu",
  events = {
    {name = "play", from = "menu", to = "game"},
    {name = "quit", from = "game", to = "menu"}
  },
  callbacks = {
    on_leave_menu = function (self)
      fade_out(0.5, self.confirm)
      return fsm.DEFERRED
    end
  }
})

screens.play()
```


## Meta

* Code: `git clone git://github.com/unindented/lua-fsm.git`
* Home: <https://github.com/unindented/lua-fsm/>


## Contributors

* Daniel Perez Alvarez ([unindented@gmail.com](mailto:unindented@gmail.com))


## License

Copyright (c) 2016 Daniel Perez Alvarez ([unindented.org](https://unindented.org/)). This is free software, and may be redistributed under the terms specified in the LICENSE file.
