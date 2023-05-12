require 'rails_helper'

RSpec.describe Commands::Connect do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid: profile.rid, text: code)
  end

  let(:profile) { create(:profile, user:) }
  let(:team) { profile.team }
  let(:user) { nil }
  let(:code) { nil }

  shared_examples 'expected response' do
    let(:response) { ChatResponse.new(mode:, text:) }

    it 'returns expected response' do
      expect(command).to eq(response)
    end
  end

  context 'when profile is already connected' do
    let(:user) { create(:user) }
    let(:code) { user.reg_token }
    let(:mode) { :error }
    let(:text) { ":#{App.error_emoji}: Your profile is already connected to #{profile.user.email}" }

    include_examples 'expected response'
  end

  context 'when no code is provided' do
    let(:mode) { :private }
    let(:text) do
      "To connect your #{team.name} profile with your web account, visit: <#{url}>"
    end
    let(:url) do
      App.base_url +
        Rails.application.routes.url_helpers.profile_connection_path(reg_token: profile.reg_token)
    end

    include_examples 'expected response'
  end

  context 'when invalid code is provided' do
    let(:code) { 'invalid-code' }
    let(:mode) { :error }
    let(:text) { ":#{App.error_emoji}: #{I18n.t('profiles.connect_invalid')}" }

    include_examples 'expected response'
  end

  context 'when valid code is provided' do
    let(:profile) { create(:profile, user: nil) }
    let(:user) { create(:user) }
    let(:code) { user.reg_token }
    let(:mode) { :private }
    let(:text) { "#{profile.link} successfully connected to account #{user.email}" }

    include_examples 'expected response'

    it 'links the profile to the user' do
      command
      expect(profile.reload.user_id).to eq(user.id)
    end
  end
end
