describe("speech", function()

    _G.love = require("mocklove")

    local slime = require("slime")

    function mock_speech_started() end
    function mock_draw_speech() end
    function mock_speech_ended() end

    it("add", function()
        slime.clear()
        slime.actor.add({name="ego", x=1, y=1, width=10, height=40})
        assert.is_false(slime.speech.is_talking())
        assert.is_false(slime.speech.is_talking("ego"))

        slime.speech.say("ego", "hello, world!")
        assert.are.equals(1, #slime.speech.queue)
        assert.is_true(slime.speech.is_talking("ego"))
    end)

    it("draw", function()
        local _message = "hello, world!"
        slime.clear()
        slime.actor.add({name="ego", x=1, y=1, width=10, height=40})
        slime.speech.say("ego", _message)

        -- test default draw
        slime.speech.draw()

        -- test custom draw
        local _default_draw_speech = slime.event.draw_speech
        local _event_draw_speech = spy.new(mock_draw_speech)
        slime.event.draw_speech = _event_draw_speech
        slime.speech.draw()
        slime.event.draw_speech = _default_draw_speech

        assert.spy(_event_draw_speech).was_called_with("ego", _message)
    end)

    it("update", function()
        slime.clear()
        slime.actor.add({name="ego", x=1, y=1, width=10, height=40})
        slime.speech.say("ego", "hello, world!")

        local _event_started = spy.new(mock_speech_started)
        local _event_ended = spy.new(mock_speech_ended)

        local _default_speech_started = slime.event.speech_started
        local _default_speech_ended = slime.event.speech_ended
        slime.event.speech_started = _event_started
        slime.event.speech_ended = _event_ended

        -- trigger the speech started event
        slime.speech.update(1)

        -- end the speech
        slime.speech.skip()

        slime.event.speech_started = _default_speech_started
        slime.event.speech_ended = _default_speech_ended

        assert.spy(_event_started).was_called_with("ego")
        assert.spy(_event_ended).was_called_with("ego")
    end)

end)
