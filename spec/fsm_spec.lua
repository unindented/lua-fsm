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
        m.warn();
        assert.is_same({"panic", "clear"}, m.transitions())
      end)

      it("reports current transitions to be calm", function ()
        m.warn();
        m.panic();
        assert.is_same({"calm"}, m.transitions())
      end)

      it("reports current transitions to be panic and clear", function ()
        m.warn();
        m.panic();
        m.calm();
        assert.is_same({"panic", "clear"}, m.transitions())
      end)

      it("reports current transitions to be panic and clear", function ()
        m.warn();
        m.panic();
        m.calm();
        m.clear();
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
        m.warn();
        assert.is_not_true(m.is_finished())
      end)

      it("is finished when yellow", function ()
        m.warn();
        m.panic();
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
        m.warn();
        assert.is_not_true(m.is_finished())
      end)

      it("is NOT finished when yellow", function ()
        m.warn();
        m.panic();
        assert.is_not_true(m.is_finished())
      end)
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
        "cannot transition from state 'green' with event 'panic'")
    end)

    it("throws if we try to calm from green", function ()
      assert.has_errors(function () m.calm() end,
        "cannot transition from state 'green' with event 'calm'")
    end)

    it("throws if we try to warn from yellow", function ()
      m.warn()
      assert.has_errors(function () m.warn() end,
        "cannot transition from state 'yellow' with event 'warn'")
    end)

    it("throws if we try to calm from yellow", function ()
      m.warn()
      assert.has_errors(function () m.calm() end,
        "cannot transition from state 'yellow' with event 'calm'")
    end)

    it("throws if we try to warn from red", function ()
      m.warn()
      m.panic()
      assert.has_errors(function () m.warn() end,
        "cannot transition from state 'red' with event 'warn'")
    end)

    it("throws if we try to panic from red", function ()
      m.warn()
      m.panic()
      assert.has_errors(function () m.panic() end,
        "cannot transition from state 'red' with event 'panic'")
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
          {name = 'prepare', from = 'stopped', to = 'ready'  },
          {name = 'start',   from = 'ready',   to = 'running'},
          {name = 'resume',  from = 'paused',  to = 'running'},
          {name = 'pause',   from = 'running', to = 'paused' },
          {name = 'stop',                      to = 'stopped'}
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

end)
