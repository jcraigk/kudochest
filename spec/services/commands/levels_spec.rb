# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Commands::Levels do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team: team) }
  let(:response) { OpenStruct.new(mode: :private, text: text) }
  let(:text) do
    "```\nLevel  Karma  Delta\n-----  -----  -----\n" \
    "1      0      0\n2      13     13\n3      35     22\n" \
    "4      63     28\n5      97     34\n6      135    38\n" \
    "7      178    43\n8      224    46\n9      274    50\n" \
    "10     327    53\n11     382    55\n12     441    59\n" \
    "13     502    61\n14     566    64\n15     633    67\n" \
    "16     702    69\n17     773    71\n18     847    74\n" \
    "19     923    76\n20     1000   77\n```"
  end

  it 'returns leaderboard text' do
    expect(command).to eq(response)
  end
end
