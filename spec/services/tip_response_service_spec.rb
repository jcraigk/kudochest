# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TipResponseService do
  include EmojiHelper
  include EntityReferenceHelper

  subject(:service) { described_class.call(tips:) }

  let(:team) { build(:team, platform:) }
  let(:from_profile) { create(:profile, team:) }
  let(:to_profile) { create(:profile, team:) }
  let(:quantity) { 1 }
  let(:note) { 'For being just super' }
  let(:channel) { build(:channel) }
  let(:tips) { [tip] }
  let(:tip) do
    create \
      :tip,
      from_profile:,
      to_profile:,
      quantity:,
      note:,
      from_channel_rid: channel.rid,
      from_channel_name: channel.name
  end
  let(:lead_frag) { nil }
  let(:channel_frag) { nil }
  let(:image_lead_frag) { nil }
  let(:image_channel_frag) { nil }
  let(:leveling_frag) { nil }
  let(:image_leveling_frag) { nil }
  let(:streak_frag) { nil }
  let(:image_streak_frag) { nil }
  let(:main_frag) { nil }
  let(:image_main_frag) do
    <<~TEXT.chomp
      #{IMG_DELIM}#{from_profile.display_name} #{IMG_DELIM} gave #{IMG_DELIM}#{to_profile.display_name} #{IMG_DELIM} #{points_format(quantity, label: true)}
    TEXT
  end
  let(:note_frag) { "Note: _#{tip.note}_" }
  let(:image_note_frag) { "Note: #{tip.note}" }
  let(:chat_fragments) do
    {
      lead: lead_frag,
      main: main_frag,
      channel: channel_frag,
      note: note_frag,
      leveling: leveling_frag,
      streak: streak_frag
    }
  end
  let(:image_fragments) do
    {
      lead: image_lead_frag,
      main: image_main_frag,
      channel: image_channel_frag,
      note: image_note_frag,
      leveling: image_leveling_frag,
      streak: image_streak_frag
    }
  end
  let(:expected_result) do
    described_class::TipResponse.new \
      chat_fragments:,
      image_fragments:,
      web: web_response
  end
  let(:web_ts) { '<span class="ts">Nov 11 9:01pm:</span>' }
  let(:recipients) { tips.map(&:to_profile) }
  let(:from_profile_webref_with_stat) { emojify(from_profile.webref_with_stat, size: 12) }
  let(:to_profile_webref_with_stat) { emojify(to_profile.webref_with_stat, size: 12) }
  let(:platform) { :slack }
  let(:point_emoji) { emojify(team.point_emoj, size: 12) }

  shared_examples 'expected response' do
    it 'produces expected message' do
      expect(service).to eq(expected_result)
    end
  end

  before do
    travel_to(Time.zone.local(2019, 11, 11, 21, 1, 1))
  end

  context 'when Discord (simple test)' do
    let(:platform) { :discord }
    let(:main_frag) do
      <<~TEXT.chomp
        **#{from_profile.display_name}** gave **#{to_profile.display_name}** #{points_format(quantity, label: true)}
      TEXT
    end
    let(:channel_frag) { "in #{channel.link}" }
    let(:note_frag) { "Note: *#{tip.note}*" }
    let(:web_response) do
      <<~TEXT.chomp
        #{web_ts} #{from_profile.webref} gave #{to_profile.webref} #{points_format(quantity, label: true)} in #{channel.webref}<br>Note: <i>#{note}</i>
      TEXT
    end

    before { team.update(response_theme: 'quiet') }

    include_examples 'expected response'
  end

  context 'with a single recipient' do
    context 'when response_theme is `basic`' do
      let(:main_frag) do
        <<~TEXT.chomp
          #{from_profile.link} gave #{to_profile.link} #{points_format(quantity, label: true)}
        TEXT
      end
      let(:channel_frag) { "in #{channel.link}" }
      let(:web_response) do
        <<~TEXT.chomp
          #{web_ts} #{from_profile.webref} gave #{to_profile.webref} #{points_format(quantity, label: true)} in #{channel.webref}<br>Note: <i>#{note}</i>
        TEXT
      end

      before { team.update(response_theme: 'basic') }

      include_examples 'expected response'
    end
  end

  context 'when response_theme is `quiet`' do
    let(:main_frag) do
      <<~TEXT.chomp
        <#{App.base_url}/profiles/#{from_profile.slug}|#{from_profile.display_name}> gave <#{App.base_url}/profiles/#{to_profile.slug}|#{to_profile.display_name}> #{points_format(quantity, label: true)}
      TEXT
    end
    let(:channel_frag) { "in #{channel.link}" }
    let(:web_response) do
      <<~TEXT.chomp
        #{web_ts} #{from_profile.webref} gave #{to_profile.webref} #{points_format(quantity, label: true)} in #{channel.webref}<br>Note: <i>#{note}</i>
      TEXT
    end

    before { team.update(response_theme: 'quiet') }

    include_examples 'expected response'
  end

  context 'when response_theme is `quiet_stat`' do
    let(:main_frag) do
      <<~TEXT.chomp
        #{from_profile.dashboard_link_with_stat} gave #{to_profile.dashboard_link_with_stat} #{points_format(quantity, label: true)}
      TEXT
    end
    let(:channel_frag) { "in #{channel.link}" }
    let(:web_response) do
      <<~TEXT.chomp
        #{web_ts} #{from_profile.webref} gave #{to_profile.webref} #{points_format(quantity, label: true)} in #{channel.webref}<br>Note: <i>#{note}</i>
      TEXT
    end

    before { team.update(response_theme: 'quiet_stat') }

    include_examples 'expected response'
  end

  context 'when response_theme is `fancy`' do
    let(:main_frag) do
      <<~TEXT.chomp
        #{from_profile.link_with_stat} gave #{to_profile.link_with_stat} #{points_format(quantity, label: true)} #{team.point_emoj * quantity}
      TEXT
    end
    let(:channel_frag) { "in #{channel.link}" }
    let(:web_response) do
      <<~TEXT.chomp
        #{web_ts} #{from_profile_webref_with_stat} gave #{to_profile_webref_with_stat} #{points_format(quantity, label: true)} #{point_emoji} in #{channel.webref}<br>Note: <i>#{note}</i>
      TEXT
    end

    before { team.update(response_theme: 'fancy') }

    include_examples 'expected response'
  end

  context 'when a streak is rewarded' do
    let(:chat_snippet) do
      <<~TEXT.chomp
        #{from_profile.link} earned #{points_format(team.streak_reward, label: true)} for achieving a Giving Streak of 5 days
      TEXT
    end
    let(:web_snippet) do
      <<~TEXT.chomp
        #{from_profile.webref} earned #{points_format(team.streak_reward, label: true)} for achieving a Giving Streak of 5 days
      TEXT
    end

    before do
      allow(StreakRewardService).to receive(:call).and_return(true)
      from_profile.update(streak_count: 5)
    end

    it 'includes streak message' do
      expect(service.chat_fragments[:streak]).to eq(chat_snippet)
    end
  end

  context 'when recipient levels up' do
    let(:quantity) { 5 }
    let(:main_frag) do
      <<~TEXT.chomp
        #{from_profile.link} gave #{to_profile.reload.link} #{points_format(quantity, label: true)}
      TEXT
    end
    let(:channel_frag) { "in #{channel.link}" }
    let(:leveling_frag) { "#{to_profile.link} leveled up to #{to_profile.level}!" }
    let(:image_leveling_frag) do
      "#{IMG_DELIM}#{to_profile.display_name} #{IMG_DELIM} leveled up to #{to_profile.level}!"
    end
    let(:web_response) do
      <<~TEXT.chomp
        #{web_ts} #{from_profile.webref} gave #{to_profile.webref} #{points_format(quantity, label: true)} in #{channel.webref}<br>Note: <i>#{note}</i><br>#{to_profile.webref} leveled up to #{to_profile.level}!
      TEXT
    end

    before { to_profile.update(balance: 10) }

    include_examples 'expected response'
  end

  xcontext 'when sender levels up' do
  end

  context 'with multiple recipients' do
    let(:to_profile2) { create(:profile, team:) }
    let(:to_profile3) { create(:profile, team:) }
    let(:tips) { [tip, tip2, tip3] }
    let(:tip2) do
      create \
        :tip,
        from_profile:,
        to_profile: to_profile2,
        quantity: 1,
        note:,
        from_channel_rid: channel.rid,
        from_channel_name: channel.name
    end
    let(:tip3) do
      create \
        :tip,
        from_profile:,
        to_profile: to_profile3,
        quantity: 2,
        note:,
        from_channel_rid: channel.rid,
        from_channel_name: channel.name
    end
    let(:main_frag) do
      <<~TEXT.chomp
        #{from_profile.link} gave #{to_profile3.link} #{points_format(2, label: true)} and #{to_profile.link} and #{to_profile2.link} #{points_format(1, label: true)} each
      TEXT
    end
    let(:channel_frag) { "in #{channel.link}" }
    let(:image_main_frag) do
      <<~TEXT.chomp
        #{IMG_DELIM}#{from_profile.display_name} #{IMG_DELIM} gave #{IMG_DELIM}#{to_profile3.display_name} #{IMG_DELIM} #{points_format(2, label: true)} and #{IMG_DELIM}#{to_profile.display_name} #{IMG_DELIM} and #{IMG_DELIM}#{to_profile2.display_name} #{IMG_DELIM} #{points_format(1, label: true)} each
      TEXT
    end
    let(:web_response) do
      <<~TEXT.chomp
        #{web_ts} #{from_profile.webref} gave #{to_profile3.webref} #{points_format(2, label: true)} and #{to_profile.webref} and #{to_profile2.webref} #{points_format(1, label: true)} each in #{channel.webref}<br>Note: <i>#{note}</i>
      TEXT
    end

    include_examples 'expected response'

    context 'when at least one tip was given to a channel' do
      let(:tip3) do
        create \
          :tip,
          from_profile:,
          to_profile: to_profile3,
          quantity: 2,
          note:,
          from_channel_rid: channel.rid,
          from_channel_name: channel.name,
          to_channel_rid: channel.rid,
          to_channel_name: channel.name
      end
      let(:lead_frag) do
        <<~TEXT.chomp
          Everyone in #{channel_link(channel.rid)} has received #{App.points_term}
        TEXT
      end
      let(:image_lead_frag) do
        <<~TEXT.chomp
          Everyone in #{IMG_DELIM}#{CHAN_PREFIX}#{channel.name} #{IMG_DELIM} has received #{App.points_term}
        TEXT
      end

      it 'includes channel snippet' do
        expect(service.chat_fragments[:lead]).to eq(lead_frag)
      end
    end

    xcontext 'when `@everyone` are given points' do
    end

    context 'when at least one tip was gave to a subteam' do
      let(:subteam) { create(:subteam, team:) }
      let(:tip3) do
        create \
          :tip,
          from_profile:,
          to_profile: to_profile3,
          quantity: 2,
          note:,
          from_channel_rid: channel.rid,
          from_channel_name: channel.name,
          to_subteam_rid: subteam.rid,
          to_subteam_handle: subteam.handle
      end
      let(:chat_snippet) { 'Everyone in' }

      it 'includes subteam snippet' do
        expect(service.chat_fragments[:lead]).to start_with(chat_snippet)
      end
    end

    context 'when there are > App.max_response_mentions recipients, no individual mentions' do
      let(:main_frag) do
        <<~TEXT.chomp
          #{from_profile.link} gave #{to_profile3.link} #{points_format(2, label: true)} and 2 users #{points_format(1, label: true)} each
        TEXT
      end
      let(:channel_frag) { "in #{channel.link}" }
      let(:image_main_frag) do
        <<~TEXT.chomp
          #{IMG_DELIM}#{from_profile.display_name} #{IMG_DELIM} gave #{IMG_DELIM}#{to_profile3.display_name} #{IMG_DELIM} #{points_format(2, label: true)} and 2 users #{points_format(1, label: true)} each
        TEXT
      end
      let(:web_response) do
        <<~TEXT.chomp
          #{web_ts} #{from_profile.webref} gave #{to_profile3.webref} #{points_format(2, label: true)} and 2 users #{points_format(1, label: true)} each in #{channel.webref}<br>Note: <i>#{note}</i>
        TEXT
      end

      before { allow(App).to receive(:max_response_mentions).and_return(1) }

      include_examples 'expected response'
    end
  end
end
