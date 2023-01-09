local fsm = require "fsm"

describe("fsm", function ()
  local m

  describe("events & states", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"},
          {name = "clear", from = "yellow", to = "green" }
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("transitions from green to yellow", function ()
      m.warn()
      assert.are_equal("yellow", m.current)
    end)

    it("transitions from yellow to red", function ()
      m.warn()
      m.panic()
      assert.are_equal("red", m.current)
    end)

    it("transitions from red to yellow", function ()
      m.warn()
      m.panic()
      m.calm()
      assert.are_equal("yellow", m.current)
    end)

    it("transitions from yellow to green", function ()
      m.warn()
      m.panic()
      m.calm()
      m.clear()
      assert.are_equal("green", m.current)
    end)
  end)

  describe("#is", function()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"},
          {name = "clear", from = "yellow", to = "green" }
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("does report current state as green", function ()
      assert.is_true(m.is("green"))
    end)

    it("does NOT report current state as yellow", function ()
      assert.is_not_true(m.is("yellow"))
    end)

    it("does report current state as green or red", function ()
      assert.is_true(m.is({"green", "red"}))
    end)

    it("does NOT report current state as yellow or red", function ()
      assert.is_not_true(m.is({"yellow", "red"}))
    end)

    describe("when warned", function ()
      before_each(function ()
        m.warn()
      end)

      it("is yellow", function ()
        assert.are_equal("yellow", m.current)
      end)

      it("does NOT report current state as green", function ()
        assert.is_not_true(m.is("green"))
      end)

      it("does report current state as yellow", function ()
        assert.is_true(m.is("yellow"))
      end)

      it("does NOT report current state as green or red", function ()
        assert.is_not_true(m.is({"green", "red"}))
      end)

      it("does report current state as yellow or red", function ()
        assert.is_true(m.is({"yellow", "red"}))
      end)
    end)
  end)

  describe("#can(not)", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"}
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("is able to warn from green state", function ()
      assert.is_true(m.can("warn"))
    end)

    it("is NOT able to panic from green state", function ()
      assert.is_true(m.cannot("panic"))
    end)

    it("is NOT able to calm from green state", function ()
      assert.is_true(m.cannot("calm"))
    end)

    describe("when warned", function ()
      before_each(function ()
        m.warn()
      end)

      it("is yellow", function ()
        assert.are_equal("yellow", m.current)
      end)

      it("is NOT able to warn from yellow state", function ()
        assert.is_true(m.cannot("warn"))
      end)

      it("is able to panic from yellow state", function ()
        assert.is_true(m.can("panic"))
      end)

      it("is NOT able to calm from yellow state", function ()
        assert.is_true(m.cannot("calm"))
      end)
    end)

    describe("when panicked", function ()
      before_each(function ()
        m.warn()
        m.panic()
      end)

      it("is red", function ()
        assert.are_equal("red", m.current)
      end)

      it("is NOT able to warn from red state", function ()
        assert.is_true(m.cannot("warn"))
      end)

      it("is NOT able to panic from red state", function ()
        assert.is_true(m.cannot("panic"))
      end)

      it("is able to calm from red state", function ()
        assert.is_true(m.can("calm"))
      end)
    end)
  end)

  describe("#transitions", function()
    describe("with single states", function ()
      before_each(function ()
        m = fsm.create({
          initial = "green",
          events = {
            {name = "warn",  from = "green",  to = "yellow"},
            {name = "panic", from = "yellow", to = "red"   },
            {name = "calm",  from = "red",    to = "yellow"},
            {name = "clear", from = "yellow", to = "green" }
          }
        })
      end)

      it("starts with green", function ()
        assert.are_equal("green", m.current)
      end)

      it("reports current transition to be yellow", function ()
        assert.is_same({"warn"}, m.transitions())
      end)

      it("reports current transitions to be panic and clear", function ()
        m.warn()
        assert.is_same({"panic", "clear"}, m.transitions())
      end)

      it("reports current transitions to be calm", function ()
        m.warn()
        m.panic()
        assert.is_same({"calm"}, m.transitions())
      end)

      it("reports current transitions to be panic and clear", function ()
        m.warn()
        m.panic()
        m.calm()
        assert.is_same({"panic", "clear"}, m.transitions())
      end)

      it("reports current transitions to be panic and clear", function ()
        m.warn()
        m.panic()
        m.calm()
        m.clear()
        assert.is_same({"warn"}, m.transitions())
      end)
    end)

    describe("with multiple states", function ()
      before_each(function ()
        m = fsm.create({
          events = {
            {name = "start", from = "none",              to = "green" },
            {name = "warn",  from = {"green", "red"},    to = "yellow"},
            {name = "panic", from = {"green", "yellow"}, to = "red"   },
            {name = "clear", from = {"red", "yellow"},   to = "green" }
          }
        })
      end)

      it("starts empty", function ()
        assert.are_equal("none", m.current)
      end)

      it("reports current transition to be start", function ()
        assert.is_same({"start"}, m.transitions())
      end)

      it("reports current transitions to be warn and panic", function ()
        m.start()
        assert.is_same({"warn", "panic"}, m.transitions())
      end)

      it("reports current transitions to be panic and clear", function ()
        m.start()
        m.warn()
        assert.is_same({"panic", "clear"}, m.transitions())
      end)

      it("reports current transitions to be warn and clear", function ()
        m.start()
        m.warn()
        m.panic()
        assert.is_same({"warn", "clear"}, m.transitions())
      end)

      it("reports current transitions to be warn and panic", function ()
        m.start()
        m.warn()
        m.panic()
        m.clear()
        assert.is_same({"warn", "panic"}, m.transitions())
      end)
    end)

    describe("with looping", function ()
      local done_before_loop = false
      local done_leave_green = false
      local done_enter_green = false
      local done_after_loop = false

      function reset_flags()
        done_before_loop = false
        done_leave_green = false
        done_enter_green = false
        done_after_loop = false
      end

      before_each(function ()
        reset_flags()

        m = fsm.create({
          initial = "green",
          events = {
            {name = "warn",  from = "green",  to = "yellow"},
            {name = "loop",  from = "green",  to = "green"},
            {name = "panic", from = "yellow", to = "red"   },
            {name = "calm",  from = "red",    to = "yellow"},
            {name = "clear", from = "yellow", to = "green" }
          },
          callbacks = {
            on_before_loop = function () done_before_loop = true end,
            on_leave_green = function () done_leave_green = true end,
            on_enter_green = function () done_enter_green = true end,
            on_after_loop = function () done_after_loop = true end,
          }
        })
      end)

      it("starts with green", function ()
        assert.are_equal("green", m.current)
        assert.is_not_true(done_before_loop)
        assert.is_not_true(done_leave_green)
        assert.is_true(done_enter_green)
        assert.is_not_true(done_after_loop)
      end)

      it("reports current transitions to be warn and loop", function ()
        assert.is_same({"warn", "loop"}, m.transitions())
      end)

      it("warn leads to yellow and correct actions", function ()
        reset_flags()
        m.warn()
        assert.are_equal("yellow", m.current)
        assert.is_not_true(done_before_loop)
        assert.is_true(done_leave_green)
        assert.is_not_true(done_enter_green)
        assert.is_not_true(done_after_loop)
      end)

      it("clear leads to green and correct actions", function ()
        m.warn()
        reset_flags()
        m.clear()
        assert.are_equal("green", m.current)
        assert.is_not_true(done_before_loop)
        assert.is_not_true(done_leave_green)
        assert.is_true(done_enter_green)
        assert.is_not_true(done_after_loop)
      end)

      it("loop leads to green and correct actions", function ()
        reset_flags()
        m.loop()
        assert.are_equal("green", m.current)
        assert.is_true(done_before_loop)
        assert.is_true(done_leave_green)
        assert.is_true(done_enter_green)
        assert.is_true(done_after_loop)
      end)

    end)
  end)

  describe("#is_pending", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   }
        },
        callbacks = {
          on_leave_green = function () return fsm.DEFERRED end
        }
      })
    end)

    it("is NOT pending when green", function ()
      assert.is_not_true(m.is_pending())
    end)

    it("is pending when leaving green", function ()
      m.warn()
      assert.is_true(m.is_pending())
    end)
  end)

  describe("#is_finished", function ()
    describe("with terminal state", function ()
      before_each(function ()
        m = fsm.create({
          initial = "green",
          terminal = "red",
          events = {
            {name = "warn",  from = "green",  to = "yellow"},
            {name = "panic", from = "yellow", to = "red"   }
          }
        })
      end)

      it("is NOT finished when green", function ()
        assert.is_not_true(m.is_finished())
      end)

      it("is NOT finished when yellow", function ()
        m.warn()
        assert.is_not_true(m.is_finished())
      end)

      it("is finished when yellow", function ()
        m.warn()
        m.panic()
        assert.is_true(m.is_finished())
      end)
    end)

    describe("without terminal state", function ()
      before_each(function ()
        m = fsm.create({
          initial = "green",
          events = {
            {name = "warn",  from = "green",  to = "yellow"},
            {name = "panic", from = "yellow", to = "red"   }
          }
        })
      end)

      it("is NOT finished when green", function ()
        assert.is_not_true(m.is_finished())
      end)

      it("is NOT finished when yellow", function ()
        m.warn()
        assert.is_not_true(m.is_finished())
      end)

      it("is NOT finished when yellow", function ()
        m.warn()
        m.panic()
        assert.is_not_true(m.is_finished())
      end)
    end)
  end)

  describe("event return values", function ()
    before_each(function ()
      m = fsm.create({
        initial = "stopped",
        events = {
          {name = "prepare", from = "stopped", to = "ready"  },
          {name = "fake",    from = "ready",   to = "running"},
          {name = "start",   from = "ready",   to = "running"},
          {name = "start",   from = "running"                }
        },
        callbacks = {
          on_before_fake = function () return false end,
          on_leave_ready = function () return fsm.DEFERRED end
        }
      })
    end)

    it("starts with stopped", function ()
      assert.are_equal("stopped", m.current)
    end)

    it("reports event to have succeeded", function ()
      assert.are_equal(fsm.SUCCEEDED, m.prepare())
      assert.are_equal("ready", m.current)
    end)

    it("reports event to have been cancelled", function ()
      m.prepare()
      assert.are_equal(fsm.CANCELLED, m.fake())
      assert.are_equal("ready", m.current)
    end)

    it("reports event to be pending", function ()
      m.prepare()
      assert.are_equal(fsm.PENDING, m.start())
      assert.are_equal("ready", m.current)
    end)

    it("reports deferred transition to have succeeded", function ()
      m.prepare()
      m.start()
      assert.are_equal(fsm.SUCCEEDED, m.confirm())
      assert.are_equal("running", m.current)
    end)

    it("reports deferred transition to have been cancelled", function ()
      m.prepare()
      m.start()
      assert.are_equal(fsm.CANCELLED, m.cancel())
      assert.are_equal("ready", m.current)
    end)

    it("reports event to cause no transition", function ()
      m.prepare()
      m.start()
      m.confirm()
      assert.are_equal(fsm.NO_TRANSITION, m.start())
      assert.are_equal("running", m.current)
    end)
  end)

  describe("invalid events", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"}
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("throws if we try to panic from green", function ()
      assert.has_errors(function () m.panic() end,
        "invalid transition from state 'green' with event 'panic'")
    end)

    it("throws if we try to calm from green", function ()
      assert.has_errors(function () m.calm() end,
        "invalid transition from state 'green' with event 'calm'")
    end)

    it("throws if we try to warn from yellow", function ()
      m.warn()
      assert.has_errors(function () m.warn() end,
        "invalid transition from state 'yellow' with event 'warn'")
    end)

    it("throws if we try to calm from yellow", function ()
      m.warn()
      assert.has_errors(function () m.calm() end,
        "invalid transition from state 'yellow' with event 'calm'")
    end)

    it("throws if we try to warn from red", function ()
      m.warn()
      m.panic()
      assert.has_errors(function () m.warn() end,
        "invalid transition from state 'red' with event 'warn'")
    end)

    it("throws if we try to panic from red", function ()
      m.warn()
      m.panic()
      assert.has_errors(function () m.panic() end,
        "invalid transition from state 'red' with event 'panic'")
    end)
  end)

  describe("invalid transitions", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"},
          {name = "clear", from = "yellow", to = "green" }
        },
        callbacks = {
          on_leave_green  = function() return fsm.DEFERRED end,
          on_leave_yellow = function() return fsm.DEFERRED end,
          on_leave_red    = function() return fsm.DEFERRED end
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("throws if we try to panic from yellow without confirming the previous transition", function ()
      m.warn()
      assert.has_errors(function () m.panic() end,
        "previous transition still pending")
    end)

    it("throws if we try to calm from red without confirming the previous transition", function ()
      m.warn()
      m.confirm()
      m.panic()
      assert.has_errors(function () m.calm() end,
        "previous transition still pending")
    end)

    it("throws if we try to clear from yellow without confirming the previous transition", function ()
      m.warn()
      m.confirm()
      m.panic()
      m.confirm()
      m.calm()
      assert.has_errors(function () m.clear() end,
        "previous transition still pending")
    end)
  end)

  describe("noop transitions (empty 'to')", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "noop",  from = "green"                },
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"},
          {name = "clear", from = "yellow", to = "green" }
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("is able to noop from green state", function ()
      assert.is_true(m.can("noop"))
    end)

    it("is able to warn from green state", function ()
      assert.is_true(m.can("warn"))
    end)

    it("does NOT cause a transition when noop", function ()
      m.noop()
      assert.are_equal("green", m.current)
    end)

    it("does cause a transition when warn", function ()
      m.noop()
      m.warn()
      assert.are_equal("yellow", m.current)
    end)

    it("is NOT able to noop from yellow state", function ()
      m.noop()
      m.warn()
      assert.is_true(m.cannot("noop"))
    end)

    it("is NOT able to warn from yellow state", function ()
      m.noop()
      m.warn()
      assert.is_true(m.cannot("warn"))
    end)
  end)

  describe("implicit wildcard transitions (empty 'from')", function ()
    before_each(function ()
      m = fsm.create({
        initial = "stopped",
        events = {
          {name = "prepare", from = "stopped", to = "ready"  },
          {name = "start",   from = "ready",   to = "running"},
          {name = "resume",  from = "paused",  to = "running"},
          {name = "pause",   from = "running", to = "paused" },
          {name = "stop",                      to = "stopped"}
        }
      })
    end)

    it("starts with stopped", function ()
      assert.are_equal("stopped", m.current)
    end)

    it("is able to stop from ready", function ()
      m.prepare()
      m.stop()
      assert.are_equal("stopped", m.current)
    end)

    it("is able to stop from running", function ()
      m.prepare()
      m.start()
      m.stop()
      assert.are_equal("stopped", m.current)
    end)

    it("is able to stop from paused", function ()
      m.prepare()
      m.start()
      m.pause()
      m.stop()
      assert.are_equal("stopped", m.current)
    end)
  end)

  describe("explicit wildcard transitions ('from' set to '*')", function ()
    before_each(function ()
      m = fsm.create({
        initial = "stopped",
        events = {
          {name = "prepare", from = "stopped", to = "ready"  },
          {name = "start",   from = "ready",   to = "running"},
          {name = "resume",  from = "paused",  to = "running"},
          {name = "pause",   from = "running", to = "paused" },
          {name = "stop",    from = "*",       to = "stopped"}
        }
      })
    end)

    it("starts with stopped", function ()
      assert.are_equal("stopped", m.current)
    end)

    it("is able to stop from ready", function ()
      m.prepare()
      m.stop()
      assert.are_equal("stopped", m.current)
    end)

    it("is able to stop from running", function ()
      m.prepare()
      m.start()
      m.stop()
      assert.are_equal("stopped", m.current)
    end)

    it("is able to stop from paused", function ()
      m.prepare()
      m.start()
      m.pause()
      m.stop()
      assert.are_equal("stopped", m.current)
    end)
  end)

  describe("deferrable startup", function ()
    before_each(function ()
      m = fsm.create({
        initial = {state = "green", event = "init", defer = true},
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"}
        }
      })
    end)

    it("starts with none", function ()
      assert.are_equal("none", m.current)
    end)

    it("is able to init from none to green", function ()
      m.init()
      assert.are_equal("green", m.current)
    end)

    it("is able to warn from green", function ()
      m.init()
      m.warn()
      assert.are_equal("yellow", m.current)
    end)
  end)

  describe("cancellable event", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green", to = "yellow"},
          {name = "panic", from = "green", to = "red"   }
        },
        callbacks = {
          on_before_warn = function () return false end,
          on_leave_green = function () return false end
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("stays green when warn event is cancelled", function ()
      m.warn()
      assert.are_equal("green", m.current)
    end)

    it("stays green when panic event is cancelled", function ()
      m.panic()
      assert.are_equal("green", m.current)
    end)
  end)

  describe("callbacks", function ()
    local called

    local function track(name, args)
      if args then
        name = name .. "(" .. table.concat(args, ",") .. ")"
      end
      table.insert(called, name)
    end

    before_each(function ()
      called = {}

      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"},
          {name = "clear", from = "yellow", to = "green" }
        },
        callbacks = {
          -- generic callbacks
          on_before_event = function (_, ...) track("on_before", {...}) end,
          on_after_event  = function (_, ...) track("on_after", {...})  end,
          on_enter_state  = function (_, ...) track("on_enter", {...})  end,
          on_leave_state  = function (_, ...) track("on_leave", {...})  end,
          -- specific state callbacks
          on_enter_green  = function () track("on_enter_green")  end,
          on_enter_yellow = function () track("on_enter_yellow") end,
          on_enter_red    = function () track("on_enter_red")    end,
          on_leave_green  = function () track("on_leave_green")  end,
          on_leave_yellow = function () track("on_leave_yellow") end,
          on_leave_red    = function () track("on_leave_red")    end,
          -- specific event callbacks
          on_before_warn  = function () track("on_before_warn")  end,
          on_before_panic = function () track("on_before_panic") end,
          on_before_calm  = function () track("on_before_calm")  end,
          on_before_clear = function () track("on_before_clear") end,
          on_after_warn   = function () track("on_after_warn")   end,
          on_after_panic  = function () track("on_after_panic")  end,
          on_after_calm   = function () track("on_after_calm")   end,
          on_after_clear  = function () track("on_after_clear")  end
        }
      })
    end)

    it("invokes all callbacks when warn", function ()
      m.warn()
      assert.are_same({
        "on_before(startup,none,green)",
        "on_leave(startup,none,green)",
        "on_enter_green",
        "on_enter(startup,none,green)",
        "on_after(startup,none,green)",
        "on_before_warn",
        "on_before(warn,green,yellow)",
        "on_leave_green",
        "on_leave(warn,green,yellow)",
        "on_enter_yellow",
        "on_enter(warn,green,yellow)",
        "on_after_warn",
        "on_after(warn,green,yellow)"
      }, called)
    end)

    it("invokes all callbacks with additional arguments when panic", function ()
      m.warn()
      m.panic("foo", "bar")
      assert.are_same({
        "on_before(startup,none,green)",
        "on_leave(startup,none,green)",
        "on_enter_green",
        "on_enter(startup,none,green)",
        "on_after(startup,none,green)",
        "on_before_warn",
        "on_before(warn,green,yellow)",
        "on_leave_green",
        "on_leave(warn,green,yellow)",
        "on_enter_yellow",
        "on_enter(warn,green,yellow)",
        "on_after_warn",
        "on_after(warn,green,yellow)",
        "on_before_panic",
        "on_before(panic,yellow,red,foo,bar)",
        "on_leave_yellow",
        "on_leave(panic,yellow,red,foo,bar)",
        "on_enter_red",
        "on_enter(panic,yellow,red,foo,bar)",
        "on_after_panic",
        "on_after(panic,yellow,red,foo,bar)"
      }, called)
    end)
  end)

  describe("callbacks throwing errors", function ()
    before_each(function ()
      m = fsm.create({
        initial = "green",
        events = {
          {name = "warn",  from = "green",  to = "yellow"},
          {name = "panic", from = "yellow", to = "red"   },
          {name = "calm",  from = "red",    to = "yellow"}
        },
        callbacks = {
          on_enter_yellow = function () error("oops") end
        }
      })
    end)

    it("starts with green", function ()
      assert.are_equal("green", m.current)
    end)

    it("does not swallow generated error", function ()
      assert.has_errors(function () m.warn() end, "oops")
    end)
  end)

end)
