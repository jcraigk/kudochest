class EnableUuid < ActiveRecord::Migration[6.0]
  def change
    return if extension_enabled? 'pgcrypto'
    enable_extension 'pgcrypto'
  end
end
