# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ResponseChannel do
  xit 'successfully subscribes' do
    subscribe
    expect(subscription).to be_confirmed
  end
end
