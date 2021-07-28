# frozen_string_literal: true
class CsvImporter < Base::Service
  option :team
  option :text

  def call
    @num_imported = 0
    @invalid_names = []

    import_tips
    result_sentence
  end

  private

  attr_reader :num_imported, :invalid_names

  def result_sentence
    <<~TEXT.chomp
      CSV import results: #{pluralize(num_imported, 'user')} updated, #{pluralize(invalid_names.size, 'invalid display name')} found: #{invalid_names.to_sentence}
    TEXT
  end

  def import_tips
    text.split("\n").each do |line|
      display_name, quantity = line.split(',')
      profile = team.profiles.find_by(display_name: display_name.tr('@', ''))
      next create_import_tip(profile, quantity.to_f.round(2)) if profile.present?
      @invalid_names << display_name
    end
  end

  def create_import_tip(profile, quantity)
    Tip.transaction do
      create_tip(profile, quantity)
      profile.update!(points_claimed: profile.points_claimed + quantity)
    end
    @num_imported += 1
  end

  def create_tip(profile, quantity)
    Tip.create!(
      from_profile: team.app_profile,
      to_profile: profile,
      quantity: quantity,
      source: 'import',
      event_ts: Time.current.to_f.to_s
    )
  end
end
