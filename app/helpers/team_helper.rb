# frozen_string_literal: true
module TeamHelper
  # rubocop:disable Metrics/MethodLength
  def reset_team_stats_button(team)
    link_to \
      icon_and_text(
        'exclamation-circle',
        t('teams.reset_stats_now', points_title: App.points_term.titleize)
      ),
      reset_stats_team_path(team),
      class: 'button is-danger',
      method: :patch,
      data: {
        confirm: t('teams.confirm_reset_stats', points: App.points_term)
      }
  end

  def active_claim_button(reward)
    link_to \
      icon_and_text(
        'sparkles',
        t(
          'shop.claim_item',
          amount: number_with_delimiter(reward.price),
          points: App.points_term
        )
      ),
      claim_reward_path(id: reward.id),
      method: :post,
      class: 'button is-primary is-large',
      data: { confirm: t('shop.confirm_claim') }
  end

  def inactive_claim_button(reward)
    link_to \
      icon_and_text(
        'do-not-enter',
        t(
          'shop.requires_points',
          amount: number_with_delimiter(reward.price),
          points: App.points_term
        )
      ),
      '#',
      class: 'button is-large btn-claim-disabled',
      disabled: true
  end
  # rubocop:enable Metrics/MethodLength

  def join_all_channels_button(team)
    link_to \
      icon_and_text('sign-in', t('teams.join_all_channels')),
      join_channels_team_path(team),
      class: 'button',
      method: :patch,
      data: {
        confirm: t('teams.confirm_join_all_channels')
      }
  end

  def export_data_button(team)
    link_to \
      icon_and_text('cloud-download', t('teams.export_data')),
      export_data_team_path(team),
      class: 'button',
      method: :patch,
      data: {
        confirm: t('teams.confirm_export_data')
      }
  end

  def claim_button(profile, reward)
    return active_claim_button(reward) if profile.points_unclaimed >= reward.price
    inactive_claim_button(reward)
  end

  def time_until_next_dispersal(team)
    distance_of_time_in_words(Time.current, team.next_tokens_at)
  end

  def next_dispersal_at(team)
    team.next_tokens_at.strftime('%b %-d %-l:%M%P')
  end

  def profile_select(team, column, blank_label, value)
    select_tag \
      column,
      options_for_select(
        team.profiles.active.map { |p| [p.display_name, p.id] },
        value
      ),
      class: 'input select2 autosubmit',
      include_blank: "(#{blank_label})"
  end

  def topic_select(team, blank_label, value)
    select_tag \
      :topic_id,
      options_for_select(
        team.topics.active.map { |t| [t.name, t.id] },
        value
      ),
      class: 'input select2 autosubmit',
      include_blank: "(#{blank_label})"
  end

  def status_select
    select_tag \
      :status,
      options_for_select(
        [['All Status', 'all'], %w[Active active], %w[Inactive inactive]],
        params[:status]
      ),
      class: 'input autosubmit'
  end

  def fulfillment_select
    select_tag \
      :fulfillment,
      options_for_select(
        [['All Status', 'all'], %w[Fulfilled fulfilled], %w[Pending pending]],
        params[:fulfillment]
      ),
      class: 'input autosubmit'
  end

  def reward_select(team)
    select_tag \
      :reward_id,
      options_for_select(reward_options(team), params[:reward_id]),
      class: 'input autosubmit'
  end

  def reward_options(team)
    [['All Loot Items', 'all']] +
      Reward.where(team:)
            .order(name: :asc)
            .map { |reward| [reward.name, reward.id] }
  end

  def search_input(placeholder)
    text_field_tag(:search, params[:search], class: 'input', placeholder:)
  end

  def team_avatar_image(team, size: 80)
    image_tag \
      team.avatar_url,
      alt: 'Team avatar image',
      size:,
      class: "team-avatar platform-#{team.platform}"
  end

  def response_mode_options(team)
    case team.platform
    when 'slack' then all_response_options
    when 'discord' then discord_response_options
    end
  end

  def all_response_options
    Team.response_mode.options
  end

  def discord_response_options
    Team.response_mode.options(except: %w[adaptive reply])
  end

  def discord_tip_emoji(size = nil)
    image_pack_tag('media/images/emoji/plus_plus.png', size:, alt: 'Plus Plus emoji')
  end

  def discord_jab_emoji(size = nil)
    image_pack_tag('media/images/emoji/minus_minus.png', size:, alt: 'Minus One emoji')
  end

  def discord_ditto_emoji(size = nil)
    image_pack_tag('media/images/emoji/plus_one_v1.png', size:, alt: 'Plus One emoji')
  end

  def max_allowed_teams?
    Team.active.count >= App.max_teams
  end
end
