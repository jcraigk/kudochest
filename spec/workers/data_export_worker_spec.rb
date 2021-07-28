# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DataExportWorker do
  subject(:perform) { described_class.new.perform(team.id) }

  let(:team) { create(:team) }
  let!(:profile1) { create(:profile, team: team) }
  let!(:profile2) { create(:profile, team: team) }
  let(:mock_mailer) { instance_spy(ActionMailer::MessageDelivery) }
  let(:csv_str) do
    CSV.generate do |csv|
      csv << ['ID', 'Name', App.points_term.titleize]
      [profile1, profile2].each do |profile|
        csv << [
          profile.rid,
          profile.display_name,
          profile.points
        ]
      end
    end
  end

  before do
    allow(TeamOwnerMailer).to receive(:data_export).and_return(mock_mailer)
    allow(mock_mailer).to receive(:deliver_later)
    perform
  end

  it 'calls service with expected args' do
    expect(TeamOwnerMailer).to have_received(:data_export).with(team, csv_str)
    expect(mock_mailer).to have_received(:deliver_later)
  end
end
