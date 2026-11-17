# Add inside Rails.application.routes.draw in config/routes.rb
resource :battery_automation, only: %i[show update] do
  post :toggle
  post :plug_on
  post :plug_off
end
