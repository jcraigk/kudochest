# frozen_string_literal: true
module ApplicationHelper
  def submit_button(label = nil, icon = 'check', css = '')
    text = label || t('controls.save_changes')
    button_tag(
      type: 'submit',
      id: 'btn-save-changes',
      class: "button is-primary #{css}".strip,
      data: { disable_with: t('controls.please_wait') }
    ) do
      icon_and_text(icon, text)
    end
  end

  def search_button
    button_tag(
      type: 'submit',
      class: 'button',
      data: { disable_with: t('controls.please_wait') }
    ) do
      icon_and_text('search', t('nav.search'))
    end
  end

  def cancel_changes_button(label = nil, icon = 'times')
    text = label || t('controls.discard_changes')
    button_tag(
      type: 'reset',
      id: 'btn-discard-changes',
      class: 'button is-danger'
    ) do
      icon_and_text(icon, text)
    end
  end

  def back_button(path)
    link_to(icon_and_text('arrow-left', t('controls.go_back')), path, class: 'button cancel')
  end

  def icon_and_text(icon_key, text)
    fa_icon(icon_key, 'btn-icon') + text
  end

  def fa_icon(icon_key, css = nil)
    tag.i(class: "fa fa-#{icon_key} #{css}".strip)
  end

  def yes_no_tag(bool)
    word = bool ? 'Yes' : 'No'
    css = bool ? 'is-success is-light' : ''
    tag.span(word, class: "tag is-medium #{css}".strip)
  end

  def status_tag(bool)
    word = bool ? 'Active' : 'Inactive'
    css = bool ? 'is-success is-light' : ''
    tag.span(word, class: "tag is-medium #{css}".strip)
  end

  def quantity_tag(quantity)
    tag.span(number_with_delimiter(quantity), class: 'tag is-medium')
  end

  def remaining_quantity_tag(quantity)
    css = quantity.positive? ? 'is-primary' : 'is-danger'
    tag.span(number_with_delimiter(quantity), class: "tag is-medium is-light #{css}")
  end

  def channel_select(form, attr)
    form.select \
      attr,
      options_for_select(channel_options(form.object), form.object.send(attr)),
      include_blank: 'Disabled'
  end

  def channel_options(team)
    team.channels
        .sort_by(&:name)
        .map { |c| ["# #{c.name}", c.rid] }
  end

  def tooltip_btn(i18n_key, css_class = nil, i18n_params = {})
    tag.span \
      tag.i(class: 'fa fa-question-circle is-grey'),
      class: "tooltip-btn has-tooltip-multiline #{css_class}",
      data: { tooltip: t(i18n_key, **i18n_params) }
  end

  def hour_select(form, attr)
    form.select \
      attr,
      options_for_select(
        hour_options,
        form.object.send(attr)
      )
  end

  def hour_options
    (0..23).map { |num| [num_to_hour(num), num] }
  end

  def num_to_hour(num)
    case num
    when 0 then '12:00am'
    when 1..11 then "#{num}:00am"
    when 12 then '12:00pm'
    when 13..23 then "#{num - 12}:00pm"
    end
  end

  def copyright_years
    start_year = 2020
    current_year = Time.current.year
    start_year == current_year ? start_year : "#{start_year} - #{current_year}"
  end

  def channel_ref(tip)
    return 'Private' if tip.from_channel_name.blank?
    "#{CHAN_PREFIX}#{tip.from_channel_name}"
  end

  def group_label(tip)
    return 'Everyone' if tip.to_everyone
    tip.to_channel_name.presence || tip.to_subteam_handle.presence || 'Direct'
  end

  def rank_with_trend(rank, previous_rank)
    [
      trend_icon(rank, previous_rank),
      rank_or_trophy(rank)
    ].join("\n").html_safe # rubocop:disable Rails/OutputSafety
  end

  def trend_icon(rank, previous_rank)
    return if previous_rank.zero? || rank <= previous_rank
    fa_icon('triangle', 'trend-icon')
  end

  def rank_or_trophy(rank)
    return rank unless rank.in?(1..3)
    image_pack_tag "media/images/trophies/#{rank}.png", size: '20x25'
  end

  def user_email_domains_sentence
    App.user_email_domains.to_sentence \
      two_words_connector: ' or ',
      last_word_connector: ', or '
  end
end
