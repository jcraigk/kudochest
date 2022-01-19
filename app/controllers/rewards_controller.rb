# frozen_string_literal: true
class RewardsController < ApplicationController
  before_action :fetch_current_team, except: %i[shop claim]

  def index
    authorize Reward
    fetch_rewards
  end

  def new
    authorize Reward
    @reward = Reward.new
  end

  def create
    authorize Reward

    @reward = Reward.new(reward_params)
    if @reward.save
      flash[:notice] = t('rewards.created')
      redirect_to rewards_path
    else
      render :new
    end
  end

  def edit
    fetch_reward
    authorize @reward
  end

  def update
    fetch_reward
    authorize @reward

    if @reward.update(reward_params)
      flash[:notice] = t('rewards.updated')
      redirect_to edit_reward_path(@reward)
    else
      render :edit
    end
  end

  def destroy
    fetch_reward
    authorize @reward

    if @reward.claims.count.positive?
      flash[:alert] = t('rewards.cannot_destroy_claimed')
    else
      flash[:notice] = t('rewards.destroyed')
      @reward.destroy
    end

    redirect_to rewards_path
  end

  def shop
    return redirect_to_dasboard(alert: t('shop.disabled')) unless @current_profile.team.enable_loot?
    @rewards = Reward.shop_list(@current_profile.team)
  end

  def claim # rubocop:disable Metrics/AbcSize
    return redirect_to_dasboard(alert: t('shop.disabled')) unless @current_profile.team.enable_loot?

    reward = Reward.find_by(team: @current_profile.team, id: params[:id], active: true)
    result = RewardClaimService.call(profile: @current_profile, reward:)

    if result.error.present?
      flash[:alert] = result.error
    else
      flash[:notice] = t('shop.claim_successful')
    end

    redirect_to shop_path
  end

  private

  def fetch_reward
    @reward = Reward.includes(:team).find(params[:id])
  end

  def fetch_rewards
    @rewards =
      Reward.where(team: @current_team)
            .includes(:team)
            .order(name: :asc)
            .page(params[:page])
    apply_search
    apply_status_filter
  end

  def apply_status_filter
    status = params[:status]
    return if status.blank? || status == 'all'
    @rewards = (status == 'active' ? @rewards.active : @rewards.inactive)
  end

  def apply_search
    return if params[:search].blank?
    @rewards = @rewards.search(params[:search])
  end

  def reward_params
    permitted_params.tap do |attrs|
      attrs[:team] = @current_team
      if attrs[:auto_fulfill] == '1'
        attrs[:quantity] = 0
      else
        attrs[:fulfillment_keys] = ''
      end
    end
  end

  def permitted_params
    params.require(:reward)
          .permit(:active, :name, :description, :price, :auto_fulfill, :quantity, :fulfillment_keys)
  end
end
