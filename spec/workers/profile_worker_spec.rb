# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ProfileWorker do
  subject(:perform) { described_class.new.perform(team.rid, first_run) }

  let(:team) { create(:team) }
  let(:first_run) { true }

  before do
    allow(Slack::ProfileService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Slack::ProfileService).to have_received(:call).with(team:, first_run:)
  end
end
