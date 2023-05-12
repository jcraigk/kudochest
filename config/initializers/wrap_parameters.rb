ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: %i[json]
end
