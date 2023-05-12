class SubteamMembership < ApplicationRecord
  belongs_to :profile
  belongs_to :subteam
end
