require 'moduler/module_creator'

module ContainingModule
end

describe Moduler::ModuleCreator do
  describe '#define' do
    context "ModuleCreator.define" do
      it "The module is created and attached to the parent" do
        expect(ContainingModule.const_defined?(:Blah)).to eq false
        Moduler::ModuleCreator.define(ContainingModule, :Blah)
        expect(ContainingModule::Blah.class).to eq Module
      end
    end

    context "ModuleCreator.new(ContainingModule).define(:Blah2)" do
      it "The module is created and attached to the parent" do
        expect(ContainingModule.const_defined?(:BlahClass)).to eq false
        Moduler::ModuleCreator.new(ContainingModule).define(:Blah2)
        expect(ContainingModule::Blah2.class).to eq Module
      end
    end

    context "When Module Existing is already defined" do
      before do
        ::ContainingModule.const_set(:ExistingModule, Module.new { attr_reader :x })
      end

      context "And ModuleCreator.define targets it" do
        it "ModuleCreator reopens the module" do
          Moduler::ModuleCreator.define(ContainingModule, :ExistingModule) do
            add_dsl_method(:y) { 1 }
          end
          expect(ContainingModule::ExistingModule.instance_method(:x)).to_not be_nil
          expect(ContainingModule::ExistingModule.instance_method(:y)).to_not be_nil
        end
      end

      context "And ModuleCreator.new(ContainingModule).define(ExistingModule) targets it" do
        it "ModuleCreator reopens the module" do
          Moduler::ModuleCreator.new(ContainingModule).define(:ExistingModule) do
            add_dsl_method(:z) { 1 }
          end
          expect(ContainingModule::ExistingModule.instance_method(:x)).to_not be_nil
          expect(ContainingModule::ExistingModule.instance_method(:z)).to_not be_nil
        end
      end
    end
  end

  describe '#define_class' do
    context "ModuleCreator.define_class" do
      it "The module is created and attached to the parent" do
        expect(ContainingModule.const_defined?(:BlahClass)).to eq false
        Moduler::ModuleCreator.define_class(ContainingModule, :BlahClass)
        expect(ContainingModule::BlahClass.class).to eq Class
      end
    end

    context "ModuleCreator.new(ContainingModule).define_class(:BlahClass2)" do
      it "The module is created and attached to the parent" do
        expect(ContainingModule.const_defined?(:BlahClass2)).to eq false
        Moduler::ModuleCreator.new(ContainingModule).define_class(:BlahClass2)
        expect(ContainingModule::BlahClass2.class).to eq Class
      end
    end

    context "When Module ExistingModule is already defined" do
      before do
        ::ContainingModule.const_set(:ExistingClass, Class.new { attr_reader :x })
      end

      context "And ModuleCreator.define_class targets it" do
        it "ModuleCreator reopens the module" do
          Moduler::ModuleCreator.define_class(ContainingModule, :ExistingClass) do
            add_dsl_method(:y) { 1 }
          end
          expect(ContainingModule::ExistingClass.instance_method(:x)).to_not be_nil
          expect(ContainingModule::ExistingClass.instance_method(:y)).to_not be_nil
        end
      end
    end

    context "And ModuleCreator.new(ContainingModule).define(Blah) targets it" do
      it "ModuleCreator reopens the module" do
        Moduler::ModuleCreator.new(ContainingModule).define_class(:ExistingClass) do
          add_dsl_method(:z) { 1 }
        end
        expect(ContainingModule::ExistingClass.instance_method(:x)).to_not be_nil
        expect(ContainingModule::ExistingClass.instance_method(:z)).to_not be_nil
      end
    end
  end

  describe "on_close, on_closed, on_dsl_added" do
    context "With a module creator" do
      let(:creator) { Moduler::ModuleCreator.new(Module.new) }
      context "And listeners for on_close, on_closed and on_dsl_added" do
        attr_reader :events
        before do
          @events = []
          creator.on_dsl_added { |c,e| expect(c).to eq creator; @events << [ :dsl_added, e ] }
          creator.on_close { |c,e| expect(c).to eq creator; @events << [ :close ] }
          creator.on_closed { |c,e| expect(c).to eq creator; @events << [ :closed ] }
        end

        it "Listeners fire and are unregistered on close" do
          creator.close
          expect(events).to eq [ [ :close ], [ :closed ] ]
          expect(creator.on_close.listeners.size).to eq 0
          expect(creator.on_closed.listeners.size).to eq 0
          expect(creator.on_dsl_added.listeners.size).to eq 0
        end

        it "Each type of DSL add fires DSL add events" do
          dsl_proc = proc { attr_reader :x }
          class_dsl_proc = proc { attr_reader :y }
          dsl_method_proc = proc { }
          class_dsl_method_proc = proc { }

          creator.add_dsl(dsl_proc)
          creator.add_class_dsl(class_dsl_proc)
          creator.add_dsl_method(:a, dsl_method_proc)
          creator.add_class_dsl_method(:b, class_dsl_method_proc)

          included = Module.new
          extended = Module.new
          creator.include_dsl(included)
          creator.extend_dsl(extended)
          expect(events).to eq [
            [ :dsl_added, { :type => :dsl, :dsl => dsl_proc } ],
            [ :dsl_added, { :type => :class_dsl, :dsl => class_dsl_proc } ],
            [ :dsl_added, { :type => :dsl_method, :name => :a, :proc => dsl_method_proc } ],
            [ :dsl_added, { :type => :class_dsl_method, :name => :b, :proc => class_dsl_method_proc } ],
            [ :dsl_added, { :type => :included, :module => included } ],
            [ :dsl_added, { :type => :extended, :module => extended } ]
          ]
        end

        it "Block forms of DSL add fires DSL add events" do
          creator.add_dsl { }
          creator.add_class_dsl { }
          creator.add_dsl_method(:a) { }
          creator.add_class_dsl_method(:b) { }
          events.each do |e|
            if e[0] == :dsl_added
              case e[1][:type]
              when :dsl, :class_dsl
                expect(e[1][:dsl]).not_to be_nil
              when :dsl_method
                expect(e[1][:name]).to eq :a
                expect(e[1][:proc]).not_to be_nil
              when :class_dsl_method
                expect(e[1][:name]).to eq :b
                expect(e[1][:proc]).not_to be_nil
              else
                raise "Unknown type #{e[1][:type]}"
              end
            end
          end
          expect(events.map { |e| e[0] }).to eq [ :dsl_added, :dsl_added, :dsl_added, :dsl_added ]
        end

        it "String forms of DSL add fires DSL add events" do
          creator.add_dsl '1'
          creator.add_class_dsl '2'
          creator.add_dsl_method :a, '3'
          creator.add_class_dsl_method :b, '4'
          expect(events).to eq [
            [ :dsl_added, { :type => :dsl, :dsl => '1' } ],
            [ :dsl_added, { :type => :class_dsl, :dsl => '2' } ],
            [ :dsl_added, { :type => :dsl_method, :name => :a, :proc => '3' } ],
            [ :dsl_added, { :type => :class_dsl_method, :name => :b, :proc => '4' } ]
          ]
        end
      end
    end
  end

  describe "close" do
    it "After close, all dsl addition methods throw ModuleClosedError" do
      creator = Moduler::ModuleCreator.new(Module.new)
      creator.close
      expect { creator.add_dsl '1' }.to raise_error(Moduler::ModuleClosedError)
      expect { creator.add_class_dsl '2' }.to raise_error(Moduler::ModuleClosedError)
      expect { creator.add_dsl_method :a, '3' }.to raise_error(Moduler::ModuleClosedError)
      expect { creator.add_class_dsl_method :b, '4' }.to raise_error(Moduler::ModuleClosedError)
      expect { creator.include_dsl Module.new }.to raise_error(Moduler::ModuleClosedError)
      expect { creator.extend_dsl Module.new }.to raise_error(Moduler::ModuleClosedError)
    end
  end

  describe "DSL addition" do
    module M
      def x
        'M.x'
      end
    end
    let(:creator) { Moduler::ModuleCreator.new(Class.new) }
    context 'With block' do
      it "add_dsl creates instance methods" do
        creator.add_dsl do
          def x
            'x'
          end
        end
        expect(creator.target.new.x).to eq 'x'
      end
      it "add_class_dsl creates class methods" do
        creator.add_class_dsl do
          def x
            'x'
          end
        end
        expect(creator.target.x).to eq 'x'
      end
      it "add_dsl_method creates instance methods" do
        creator.add_dsl_method(:x) { 'x' }
        expect(creator.target.new.x).to eq 'x'
      end
      it "add_class_dsl_method creates class methods" do
        creator.add_class_dsl_method(:x) { 'x' }
        expect(creator.target.x).to eq 'x'
      end
      it "include_dsl includes the module" do
        creator.include_dsl(M)
        expect(creator.target.new.x).to eq 'M.x'
      end
      it "extend_dsl extends the module" do
        creator.extend_dsl(M)
        expect(creator.target.x).to eq 'M.x'
      end
    end

    context 'With block' do
      it "add_dsl creates instance methods" do
        creator.add_dsl(proc do
          def x
            'x'
          end
        end)
        expect(creator.target.new.x).to eq 'x'
      end
      it "add_class_dsl creates class methods" do
        creator.add_class_dsl(proc do
          def x
            'x'
          end
        end)
        expect(creator.target.x).to eq 'x'
      end
      it "add_dsl_method creates instance methods" do
        creator.add_dsl_method(:x, proc { 'x' })
        expect(creator.target.new.x).to eq 'x'
      end
      it "add_class_dsl_method creates class methods" do
        creator.add_class_dsl_method(:x, proc { 'x' })
        expect(creator.target.x).to eq 'x'
      end
    end

    context 'With block' do
      it "add_dsl creates instance methods" do
        creator.add_dsl <<-EOM
          def x
            'x'
          end
        EOM
        expect(creator.target.new.x).to eq 'x'
      end
      it "add_class_dsl creates class methods" do
        creator.add_class_dsl <<-EOM
          def x
            'x'
          end
        EOM
        expect(creator.target.x).to eq 'x'
      end
      it "add_dsl_method creates instance methods" do
        creator.add_dsl_method(:x, '"x"')
        expect(creator.target.new.x).to eq 'x'
      end
      it "add_class_dsl_method creates class methods" do
        creator.add_class_dsl_method(:x, '"x"')
        expect(creator.target.x).to eq 'x'
      end
    end
  end
end
