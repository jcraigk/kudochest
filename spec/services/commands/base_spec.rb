# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Base do
  let(:args) { { team_rid: team.rid, profile_rid: profile.rid, text: 'some text' } }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team) }

  it 'calls `#new(args)` on self' do
    allow(described_class).to receive(:new).and_call_original
    described_class.call(args)
    expect(described_class).to have_received(:new).with(args)
  end

  it 'exposes #call as self.call' do
    expect(described_class.call(args)).to eq('Override in child class')
  end

  it 'exposes protected #team' do
    expect(described_class.new(args).send(:team)).to eq(team)
  end

  it 'exposes protected #profile' do
    expect(described_class.new(args).send(:profile)).to eq(profile)
  end
end
