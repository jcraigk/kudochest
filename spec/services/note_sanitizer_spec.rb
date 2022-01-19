# frozen_string_literal: true
require 'rails_helper'

RSpec.describe NoteSanitizer do
  subject(:service) { described_class.call(platform:, team_rid: team.rid, text:) }

  let(:team) { create(:team, platform:) }
  let(:platform) { :slack }
  let(:subteam) { create(:subteam, team:) }
  let(:profile) { create(:profile, team:) }
  let(:channel) { create(:channel, team:) }

  shared_examples 'success' do
    it 'sanitizes mentions' do
      expect(service).to eq(result)
    end
  end

  context 'when special chars are included' do
    let(:text) { 'hey &lt; &gt; &amp;' }
    let(:result) { 'hey < > &' }

    include_examples 'success'
  end

  xcontext 'when Discord' do
    let(:platform) { :discord }
  end

  context 'when Slack' do
    context 'when channel name is given after pipe char, extacts directly' do
      let(:given_name) { 'given-name' }
      let(:text) { "hey <#{CHAN_PREFIX}#{channel.rid}|#{given_name}>" }
      let(:result) { "hey #{CHAN_PREFIX}#{given_name}" }

      include_examples 'success'
    end

    context 'when profile display_name name is given after pipe char, extacts directly' do
      let(:given_name) { 'given-name' }
      let(:text) { "hey <#{PROF_PREFIX}#{profile.rid}|#{given_name}>" }
      let(:result) { "hey #{PROF_PREFIX}#{given_name}" }

      include_examples 'success'
    end

    context 'when url given, extacts' do
      let(:link_name) { 'This is a link' }
      let(:text) { "hey <https://www.google.com|#{link_name}>" }
      let(:result) { "hey #{link_name}" }

      include_examples 'success'
    end

    context 'when no names given after pipe char' do
      let(:text) do
        <<~TEXT
          hey <#{SUBTEAM_PREFIX[:slack]}#{subteam.rid}> yep <#{CHAN_PREFIX}#{channel.rid}> and <#{PROF_PREFIX}#{profile.rid}> with <http://google.com|google.com>
        TEXT
      end
      let(:result) do
        <<~TEXT
          hey #{PROF_PREFIX}#{subteam.handle} yep #{CHAN_PREFIX}#{channel.name} and #{PROF_PREFIX}#{profile.display_name} with google.com
        TEXT
      end

      include_examples 'success'
    end
  end
end
