require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr'
  c.ignore_localhost = true
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { match_requests_on: %i[path body] }
end
