# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EmojiInstallWorker do
  subject(:perform) { described_class.new.perform(team.rid) }

  let(:team) { create(:team) }

  before do
    allow(Team).to receive(:find_by!).with(rid: team.rid).and_return(team)
    allow(Discord::EmojiInstallService).to receive(:call)
    perform
  end

  it 'calls service with expected args' do
    expect(Discord::EmojiInstallService).to have_received(:call).with(team:)
  end
end
