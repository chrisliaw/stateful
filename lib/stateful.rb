require "stateful/engine"

module Stateful
	class Event
		attr_accessor :new_events
		def initialize(states,es_table)
			# mapping of { :event => [{:transition => {:from_state => :to_state}, :guard => Proc..., },
			#                         {:transition => {:from_state => :to_state}, :guard => Proc...,}
			#                         ] }
			@es_table = es_table
			@states = states					
			@new_events = []
		end

		def forward(event,opts={})
			#puts "Forward Event : #{event}"
			#puts "States : #{@states}"
			if @es_table[event] == nil
				@new_events << event
				@es_table[event] = []
			end
			@es_table[event] << { :transition => { @states.keys[0] => @states.values[0] }, :guard => opts[:guard] }
			#p @event_states
		end

		def backward(event,opts={})
			#puts "Backward Event : #{event}"
			#puts "States : #{@states}"
			if @es_table[event] == nil
				@new_events << event
				@es_table[event] = []
			end
			@es_table[event] << { :transition => { @states.values[0] => @states.keys[0] }, :guard => opts[:guard] }
			#p @event_states
		end

		def fire_event(event,record,auto_commit = true)
			current = record.state.to_sym
			#p record.event_states_table[event]
			@success = false
			#record.event_states_table[event].each do |evt|
			@es_table[event].each do |evt|
				if evt[:transition].keys[0] == current
					if evt[:guard] != nil
						if evt[:guard].call(record)
							record.state = evt[:transition].values[0].to_s if evt[:transition].keys[0] == current
							record.save if auto_commit  # to comply to '!' notication of the method
							@success = true
							break # break here to honour the first guard found and return true
						end
					else
						record.state = evt[:transition].values[0].to_s if evt[:transition].keys[0] == current
						record.save if auto_commit  # to comply to '!' notication of the method
						@success = true
					end
				end
			end
			@success
		end
	end
	# end Event class	
end

module Stateful
	module StateMachine
		extend ActiveSupport::Concern

		#mattr_accessor :_states, :initial, :options, :event_states_table

		included do
		end

		module ClassMethods

			def stateful(opts = {})
				options = {
					initial: "open",
					column_name: "state"
				}

				options.merge!(opts)
				#opts[:initial] = "open" if opts[:initial] == nil or opts[:initial].empty?
				#opts[:column_name] = "state"

				#@@_states = []
				#@@initial = options[:initial]
				#@@options = options
				#@@event_states_table = {}
				self.class_variable_set(:@@_states,[])
				#self.class_variable_set(:@@initial,opts[:initial])
				self.class_variable_set(:@@initial,options[:initial])
				self.class_variable_set(:@@options, options)
				self.class_variable_set(:@@event_states_table,{})			
			end

			def transform(states,opts={},&block)
				#puts "From state : #{states.keys[0]}"
				_states = class_variable_get :@@_states
				event_states_table = class_variable_get :@@event_states_table
				_states << states.keys[0].to_sym if !_states.include?(states.keys[0].to_sym)
				#puts "To state : #{states.values[0]}"
				_states << states.values[0].to_sym if !_states.include?(states.values[0].to_sym)
				e = Event.new(states,event_states_table)
				e.instance_eval(&block) if block
				e.new_events.each do |evt|
					define_method("#{evt}!") { 
						e.fire_event(evt,self) 
					}

					define_method("#{evt}") { 
						e.fire_event(evt,self,false) 
					}
				end
				#puts "Event states table"
				#p event_states_table
			end

			def states
				class_variable_get :@@_states
			end

		end # end ClassMethods

		# instance methods
		def possible_events
			@events = []
			opts = self.class.class_variable_get :@@options
			if self.has_attribute?(opts[:column_name].to_sym)

				@current = send(opts[:column_name].to_sym).to_sym #self.state.to_sym
				event_states_table = self.class.class_variable_get :@@event_states_table
				event_states_table.keys.each do |k|
					event_states_table[k].each do |s|
						if s[:transition].keys[0] == @current and !@events.include?(k)
							if s[:guard] != nil
								puts "guard result #{s[:guard].call(self)} for #{k}"
								if s[:guard].call(self)
									@events << k
								end
							else
								@events << k
							end
						end
					end
				end

			end
			@events
		end 
		alias :next_actions :possible_events

		def initialize(*arg)
			super(*arg)
			# 23 Aug 2014 - guard is to handle migration
			# If a model is not stateful but later it become stateful in subsequent migration script
			# and at the same time, there are default data created in the initial migration
			# script which creating new records. Migration will failed since there is no
			# state column. State column only exist further down the migration.
			# If the state field does not exist, just skipped that first. After all, it is not
			# important by the time initial migration scirpt was run
			begin
				opts = self.class.class_variable_get :@@options
				#opts = @@options
				if self.attributes.keys.include? opts[:column_name].to_s
					if self.class.class_variable_defined? :@@initial
						self.send("#{opts[:column_name]}=", opts[:initial])
						#self.state = self.class.class_variable_get :@@initial
						#self.state = self.state.to_s if self.state != nil
					end
				end
			
			rescue Exception => ex
			end
			#opts = self.class.class_variable_get :@@options
			##opts = @@options
			#if self.attributes.keys.include? opts[:column_name].to_s
			#	if self.class.class_variable_defined? :@@initial
			#		self.send("#{opts[:column_name]}=", opts[:initial])
			#		#self.state = self.class.class_variable_get :@@initial
			#		#self.state = self.state.to_s if self.state != nil
			#	end
			#end
		end

	end
end

