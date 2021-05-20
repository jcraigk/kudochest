# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SubteamMembership do
  subject(:subteam_membership) { build(:subteam_membership) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:subteam) }
  it { is_expected.to belong_to(:profile) }
end
