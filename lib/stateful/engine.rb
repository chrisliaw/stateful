module Stateful
  class Engine < ::Rails::Engine
    isolate_namespace Stateful
		
		config.to_prepare do
			# include into ApplicationController
			#ActionController::Base.send :include, Canopus::Concerns::Controllers::Authenticator
			ActiveRecord::Base.send :include, Stateful::StateMachine
		end		
		
  end
end
