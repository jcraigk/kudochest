class CsvImporter < Base::Service
  option :team
  option :text

  def call
    @tips = []
    @invalid_names = []

    Tip.transaction do
      create_tips
      TipOutcomeService.call(tips:)
    end

    result_sentence
  end

  private

  attr_reader :tips, :invalid_names

  def result_sentence
    [update_fragment, invalid_fragment].compact.join(', ')
  end

  def update_fragment
    "CSV import results: #{pluralize(tips.size, 'user')} updated"
  end

  def invalid_fragment
    return if invalid_names.none?
    <<~TEXT.chomp
      #{pluralize(invalid_names.size, 'invalid display name')} found: #{invalid_names.to_sentence}
    TEXT
  end

  def create_tips
    text.split("\n").each do |line|
      display_name, quantity_str = line.split(',')
      quantity = quantity_str.to_f.round(2)
      next unless quantity.positive?
      profile = team.profiles.find_by(display_name: display_name.tr('@', ''))
      next @tips << create_import_tip(profile, quantity) if profile.present?
      @invalid_names << display_name
    end
  end

  def create_import_tip(profile, quantity)
    profile.update!(points_claimed: profile.points_claimed + quantity)
    create_tip(profile, quantity)
  end

  def create_tip(profile, quantity)
    Tip.new(
      from_profile: team.app_profile,
      to_profile: profile,
      quantity:,
      source: 'import',
      event_ts: Time.current.to_f.to_s
    ).tap do |tip|
      tip.save(validate: false)
    end
  end
end
