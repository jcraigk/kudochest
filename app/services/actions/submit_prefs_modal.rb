# frozen_string_literal: true
class Actions::SubmitPrefsModal < Actions::Base
  def call
    profile.update!(attrs)
    ChatResponse.new(mode: :silent)
  end

  private

  def attrs
    options.index_with { |opt| selected.include?(opt) }
  end

  def options
    params[:view][:blocks].first[:accessory][:options].pluck(:value)
  end

  def selected
    @selected ||= prefs[:selected_options].pluck(:value)
  end

  def prefs
    params[:view][:state][:values].first.second[:prefs]
  end
end
