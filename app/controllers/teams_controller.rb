# frozen_string_literal: true
class TeamsController < ApplicationController
  before_action :fetch_current_team
  before_action :remember_section, only: %i[edit update]

  def edit
    authorize current_team
    prepare_infinite_profile_options
  end

  def update
    authorize current_team
    params[:team][:import_file].present? ? handle_import : update_team_attrs
  end

  def reset_stats
    authorize current_team
    TeamResetWorker.perform_async(current_team.id)
    redirect_to app_settings_path, notice: t('teams.reset_requested')
  end

  def join_channels
    authorize current_team
    ChannelsJoinWorker.perform_async(current_team.id)
    redirect_to app_settings_path, notice: t('teams.join_all_channels_requested')
  end

  def export_data
    authorize current_team
    DataExportWorker.perform_async(current_team.id)
    redirect_to app_settings_path,
                notice: t('teams.export_data_requested', email: current_team.owning_user.email)
  end

  def leaderboard_page
    @leaderboard = LeaderboardService.call(
      team: @current_profile.team,
      offset: params[:offset].to_i,
      count: params[:count].to_i
    )
    return if @leaderboard.profiles.blank?
    render partial: 'profiles/tiles/leaderboard_rows',
           locals: { leaderboard: @leaderboard, profile: @current_profile }
  end

  private

  def update_team_attrs
    update_infinite_profiles
    current_team.update(platform_team_params) ? update_success : update_fail
  end

  def handle_import
    flash[:notice] = CsvImporter.call(
      team: current_team,
      text: params[:team][:import_file].read
    )
    redirect_to app_settings_path
  end

  def update_infinite_profiles
    profile_rids = (params[:infinite_profile_rids].presence || '').split(':')
    current_team.profiles
                .where.not(rid: profile_rids)
                .where(infinite_tokens: true)
                .update_all(infinite_tokens: false) # rubocop:disable Rails/SkipsModelValidations
    current_team.profiles
                .where(rid: profile_rids, infinite_tokens: false)
                .update_all(infinite_tokens: true) # rubocop:disable Rails/SkipsModelValidations
  end

  def prepare_infinite_profile_options
    @team_profile_options = active_profiles.map do |profile|
      {
        label: profile.long_name,
        value: profile.rid
      }
    end
    @infinite_profile_rids = active_profiles.select(&:infinite_tokens?).map(&:rid)
  end

  def active_profiles
    @active_profiles ||= current_team.profiles.active.all
  end

  def team_params
    params.require(:team).permit(
      :throttle_tips, :token_frequency, :token_quantity, :token_max, :token_hour,
      :notify_tokens_disbursed, :max_karma_per_tip, :tip_notes, :show_channel,
      :enable_fast_ack, :week_start_day, :enable_levels, :level_curve,
      :enable_emoji, :emoji_quantity, :max_level, :max_level_karma, :response_mode,
      :response_theme, :log_channel_rid, :tip_emoji, :enable_streaks,
      :streak_duration, :streak_reward, :time_zone, :weekly_report, :karma_increment,
      :split_tip, :join_channels, :enable_cheers, :enable_loot, :enable_topics,
      :require_topic, work_days: []
    )
  end

  def platform_team_params
    case current_team.platform
    when 'slack' then team_params
    when 'discord' then team_params.except(:tip_emoji, :join_channels)
    end
  end

  def update_success
    flash[:notice] = t('teams.update_success')
    redirect_to app_settings_path
  end

  def update_fail
    prepare_infinite_profile_options
    flash.now[:alert] = t('teams.update_fail', msg: current_team.errors.full_messages.to_sentence)
    render :edit
  end

  def remember_section
    session[:section] = params[:section] if params[:section]
  end
end
