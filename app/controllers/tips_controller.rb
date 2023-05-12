class TipsController < ApplicationController
  before_action :fetch_current_team

  def index
    authorize Tip
    fetch_tips
  end

  def destroy
    @tip = Tip.find(params[:id])
    authorize @tip

    @tip.destroy
    redirect_to tips_path, notice: t('tips.destroyed')
  end

  private

  def fetch_tips
    @tips = Tip.order(created_at: :desc, from_profile_id: :asc, to_profile_id: :asc)
               .includes(:from_profile, :to_profile, :topic)
               .page(params[:page])

    apply_search
    apply_from_profile_filter
    apply_to_profile_filter
    apply_topic_filter
    apply_team_constraint
    # apply_start_date_filter
    # apply_end_date_filter
  end

  def apply_search
    return if params[:search].blank?
    @tips = @tips.search_notes(params[:search])
  end

  def apply_topic_filter
    return if params[:topic_id].blank?
    @tips = @tips.where(topic_id: params[:topic_id])
  end

  def apply_from_profile_filter
    from_profile = Profile.find_by(id: params[:from_profile_id])
    return unless from_profile&.team_id == current_team.id
    @tips = @tips.where(from_profile:)
    @profile_filter = true
  end

  def apply_to_profile_filter
    to_profile = Profile.find_by(id: params[:to_profile_id])
    return unless to_profile&.team_id == current_team.id
    @tips = @tips.where(to_profile:)
    @profile_filter = true
  end

  def apply_team_constraint
    return if @profile_filter
    @tips = @tips.where(from_profile_id: Profile.where(team: current_team))
  end

  # def apply_start_date_filter
  #   return if params[:start_date].blank?
  #   @tips = @tips.where('created_at >= ?', Date.parse(params[:start_date]))
  # rescue ArgumentError
  # end
  #
  # def apply_end_date_filter
  #   return if params[:end_date].blank?
  #   @tips = @tips.where('created_at <= ?', Date.parse(params[:end_date]))
  # rescue ArgumentError
  # end

  # def apply_order
  #   sort_by = params[:sort_by].presence || :created_at
  #   sort_dir = params[:sort_dir] == :asc ? :asc : :desc
  #   @tips = @tips.order(sort_by => sort_dir)
  # end
end
