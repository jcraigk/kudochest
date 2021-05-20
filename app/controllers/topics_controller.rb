# frozen_string_literal: true
class TopicsController < ApplicationController
  before_action :fetch_current_team

  def index
    authorize Topic
    fetch_topics
  end

  def new
    authorize Topic
    @topic = Topic.new
  end

  def create
    authorize Topic

    @topic = Topic.new(topic_params)
    if @topic.save
      flash[:notice] = t('topics.created')
      redirect_to topics_path
    else
      render :new
    end
  end

  def edit
    fetch_topic
    authorize @topic
  end

  def update
    fetch_topic
    authorize @topic

    if @topic.update(topic_params)
      flash[:notice] = t('topics.updated')
      redirect_to edit_topic_path(@topic)
    else
      render :edit
    end
  end

  def destroy
    fetch_topic
    authorize @topic

    if @topic.tips.count.positive?
      flash[:alert] = t('topics.cannot_destroy_claimed')
    else
      flash[:notice] = t('topics.destroyed')
      @topic.destroy
    end

    redirect_to topics_path
  end

  def list
    if @current_profile.team.enable_topics?
      @topics = Topic.active.where(team: @current_team).order(name: :asc)
    else
      redirect_to_dasboard(alert: t('topics.disabled'))
    end
  end

  private

  def fetch_topic
    @topic = Topic.includes(:team).find(params[:id])
  end

  def fetch_topics
    @topics =
      Topic.where(team: @current_team)
           .includes(:team)
           .order(name: :asc)
           .page(params[:page])
    apply_search
    apply_status_filter
  end

  def apply_status_filter
    status = params[:status]
    return if status.blank? || status == 'all'
    @topics = (status == 'active' ? @topics.active : @topics.inactive)
  end

  def apply_search
    return if params[:search].blank?
    @topics = @topics.search(params[:search])
  end

  def topic_params
    permitted_params.merge(team: @current_team)
  end

  def permitted_params
    params.require(:topic).permit(:name, :description, :emoji, :keyword, :active)
  end
end
