# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::SubmitPrefsModal do
  subject(:action) { described_class.call(params) }

  let(:team) { build(:team) }
  let(:profile) { create(:profile, team: team, allow_dm: false) }
  let(:curated_params) do
    {
      profile_rid: profile.rid,
      team_rid: team.rid
    }
  end
  let(:modal_submission) do
    {
      view: {
        blocks: [
          {
            accessory: {
              options: [{ value: 'allow_dm' }]
            }
          }
        ],
        state: {
          values: {
            JyY1m: {
              prefs: {
                selected_options: [{ value: 'allow_dm' }]
              }
            }
          }
        }
      }
    }
  end
  let(:params) { curated_params.merge(modal_submission) }

  it 'updates user preferences' do
    action
    expect(profile.reload.allow_dm).to eq(true)
  end
end
