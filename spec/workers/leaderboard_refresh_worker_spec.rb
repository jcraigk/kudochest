# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LeaderboardRefreshWorker do
  subject(:perform) { described_class.new.perform(team.id, givingboard) }

  # TODO: Pull setup from LeaderboardService spec and
  # test only paging/filtering there

  let(:team) { create(:team) }

  xcontext 'when `givingboard` is false' do
    let(:givingboard) { false }

    it ''
  end

  xcontext 'when `givingboard` is true' do
    let(:givingboard) { true }
  end
end
