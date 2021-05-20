# frozen_string_literal: true
class SubteamMembership < ApplicationRecord
  belongs_to :profile
  belongs_to :subteam
end
