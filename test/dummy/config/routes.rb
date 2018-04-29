Rails.application.routes.draw do
  mount Stateful::Engine => "/stateful"
end
