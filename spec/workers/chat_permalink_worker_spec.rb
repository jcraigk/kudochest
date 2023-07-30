require 'rails_helper'

RSpec.describe ChatPermalinkWorker do
  subject(:perform) { described_class.new.perform(tip.id, channel.rid, message_ts) }

  let(:team) { create(:team) }
  let(:from_profile) { create(:profile, team:) }
  let(:tip) { create(:tip, from_profile:) }
  let(:channel) { create(:channel) }
  let(:message_ts) { Time.current.to_i }
  let(:permalink) { 'https://my-msg-permalink.org' }

  before do
    allow(Tip).to receive_messages(includes: Tip, find: tip)
    allow(team.slack_client).to receive(:chat_getPermalink).and_return(OpenStruct.new(permalink:))
    perform
  end

  it 'updates tip permalink' do
    expect(tip.reload.chat_permalink).to eq(permalink)
  end
end
