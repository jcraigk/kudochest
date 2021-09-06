# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Discord::EmojiInstallService do
  subject(:service) { described_class.call(team: team) }

  let(:team) { create(:team) }
  let(:existing_emoji_rid) { '456' }
  let(:new_emoji_rid) { '789' }
  let(:resolve_data) do
    {
      emojis: [
        {
          id: '123',
          name: 'some-emoji'
        },
        {
          id: existing_emoji_rid
        }
      ]
    }
  end
  let(:add_emoji_data) { { id: new_emoji_rid } }

  described_class::EMOJI_TYPES.each do |type|
    before do
      data = resolve_data
      data[:emojis].second[:name] = App.send("discord_#{type}_emoji")
      allow(Discordrb::API::Server).to(
        receive(:resolve).with(App.discord_token, team.rid)
      ).and_return(data.to_json)
      allow(Discordrb::API::Server).to receive(:delete_emoji)
      allow(Discordrb::API::Server).to receive(:add_emoji)
      service
    end

    it 'deletes existing emoji (from previous install)' do
      expect(Discordrb::API::Server).to \
        have_received(:delete_emoji)
        .with(App.discord_token, team.rid, existing_emoji_rid)
    end

    it 'creates new emoji' do
      image = File.open("#{described_class::EMOJI_DIR}/#{type}.png").read
      emoji_data = "data:image/png;base64,#{Base64.encode64(image)}"
      expect(Discordrb::API::Server).to \
        have_received(:add_emoji)
        .with(App.discord_token, team.rid, emoji_data, App.send("discord_#{type}_emoji"))
    end
  end
end
