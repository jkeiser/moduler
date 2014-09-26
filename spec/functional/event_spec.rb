require 'support/spec_support'
require 'moduler/event'

describe Moduler::Event do
  context "When an Event is created" do
    let(:event) { Moduler::Event.new(:event) }

    context "And no handlers are registered" do
      it "Fire succeeds but does nothing" do
        event.fire(10)
      end
    end

    context "And a handler is registered" do
      before { event.register { |x| @a = x*2 } }
      it "Fires the event to the handler" do
        event.fire(10)
        expect(@a).to eq 20
      end

      it "Fires multiple events to the handler" do
        event.fire(10)
        expect(@a).to eq 20
        event.fire(30)
        expect(@a).to eq 60
      end
    end

    context "And multiple handlers are registered" do
      before { @a_listener = event.register { |x| @a = x*2 } }
      before { event.register { |x| @b = x*3 } }
      it "Fires events to all handlers" do
        event.fire(10)
        expect(@a).to eq 20
        expect(@b).to eq 30
      end

      context "And one of the handlers is unregistered" do
        before { event.unregister @a_listener }
        it "Fires events only to the remaining handler" do
          event.fire(10)
          expect(@a).to be_nil
          expect(@b).to eq 30
        end
      end

      context "And unregister_all is called" do
        before { event.unregister_all }
        it "Fire succeeds but does nothing" do
          event.fire(10)
          expect(@a).to be_nil
          expect(@b).to be_nil
        end
      end
    end
  end

  context "When an event is created with :single_event" do
    let(:event) { Moduler::Event.new(:hi, :single_event) }
    context "And multiple handlers are registered" do
      before { @a_listener = event.register { |x| @a = x*2 } }
      before { event.register { |x| @b = x*3 } }
      it "Fires events to all handlers" do
        event.fire(10)
        expect(@a).to eq 20
        expect(@b).to eq 30
      end
      it "After the event is fired, all listeners are unregistered" do
        event.fire(10)
        expect(@a).to eq 20
        expect(@b).to eq 30
        expect(event.listeners.size).to eq 0
        event.fire(20)
        expect(@a).to eq 20
        expect(@b).to eq 30
      end
    end
  end

  context "When an event is created with :unregister_on => stop_event" do
    let(:stop_event) { Moduler::Event.new(:a) }
    let(:event) { Moduler::Event.new(:b, :unregister_on => stop_event) }
    context "And handlers are registered to the event" do
      before { event.register { |x| @a = x*2 } }
      it "Listeners receive data" do
        event.fire(10)
        expect(@a).to eq 20
      end

      context "And stop_event fires" do
        before { stop_event.fire }
        it "All listeners are unregistered" do
          event.fire(10)
          expect(@a).to be_nil
          expect(event.listeners.size).to eq 0
        end
      end

      context "And stop_event fires with multiple arguments" do
        before { stop_event.fire(1,2,3) }
        it "All listeners are unregistered" do
          event.fire(10)
          expect(@a).to be_nil
          expect(event.listeners.size).to eq 0
        end
      end
    end
  end

  context "Scope" do
    context "When an Event subclass is created with self.x" do
      class EventWithX < Moduler::Event
        def x
          'EventWithX.x'
        end
      end

      class Listener
        def x
          'Listener.x'
        end
        attr_reader :a
        def register_me(event)
          event.register { @a = x }
        end
      end

      class NewContext
        def x
          'NewContext.x'
        end
        attr_reader :a
      end

      let(:event_with_x) { EventWithX.new(:event) }

      context "And a handler is registered with local variable x outside the scope" do
        before do
          x = 'local to event'
          event_with_x.register { @a = x }
        end
        it "Firing an event yields the local variable" do
          event_with_x.fire
          expect(@a).to eq 'local to event'
        end

        context "And a NewContext.new exists with self.x" do
          let(:new_context) { NewContext.new }
          it "fire_in_context(new_context) yields the local variable" do
            event_with_x.fire_in_context(new_context)
            expect(new_context.a).to eq 'local to event'
          end
        end
      end

      context "And a handler is registered from an object with self.x" do
        let(:listener) { Listener.new }
        before { listener.register_me(event_with_x) }

        it "Firing an event yields the Listener.x" do
          event_with_x.fire
          expect(listener.a).to eq 'Listener.x'
        end

        context "And a NewContext.new exists with self.x" do
          let(:new_context) { NewContext.new }
          it "fire_in_context(new_context) yields NewContext.x" do
            event_with_x.fire_in_context(new_context)
            expect(new_context.a).to eq 'NewContext.x'
          end
        end
      end
    end
  end

end
