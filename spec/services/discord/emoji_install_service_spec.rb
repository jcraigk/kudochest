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
          id: existing_emoji_rid,
          name: App.default_tip_emoji
        }
      ]
    }
  end
  let(:add_emoji_data) { { id: new_emoji_rid } }

  described_class.EMOJIS.each_key do |type|
    before do
      image = File.open(described_class::IMAGE_FILE).read
      emoji_data = "data:image/png;base64,#{Base64.encode64(image)}"
      allow(Discordrb::API::Server).to(
        receive(:resolve).with(App.discord_token, team.rid)
      ).and_return(resolve_data.to_json)
      allow(Discordrb::API::Server).to receive(:delete_emoji)
      allow(Discordrb::API::Server).to(
        receive(:add_emoji).and_return(add_emoji_data.to_json)
      ).with(App.discord_token, team.rid, emoji_data, App.send("default_#{type}_emoji"))
      service
    end

    it 'deletes existing emoji (from previous install)' do
      expect(Discordrb::API::Server)
        .to have_received(:delete_emoji).with(App.discord_token, team.rid, existing_emoji_rid)
    end

    it 'adds emoji and updates team' do
      expect(team.reload.send("#{type}_emoji")).to eq(new_emoji_rid)
    end
  end
end
