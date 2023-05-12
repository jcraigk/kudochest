class ClaimsController < ApplicationController
  before_action :fetch_current_team, except: %i[my_claims show]

  def index
    authorize Claim
    fetch_claims
  end

  def show
    @claim = Claim.find(params[:id])
    authorize @claim
  end

  def edit
    fetch_claim
    authorize @claim
  end

  def update
    fetch_claim
    authorize @claim

    @claim.update!(claim_params)

    flash[:notice] = t('claims.updated')
    redirect_to edit_claim_path(@claim)
  end

  def destroy
    fetch_claim
    authorize @claim

    @claim.destroy
    redirect_to claims_path, notice: t('claims.destroyed')
  end

  def my_claims
    @claims = Claim.where(profile: @current_profile).order(created_at: :desc)
  end

  private

  def team_reward_ids
    @reward_ids = @current_team.rewards.ids
  end

  def fetch_claim
    @claim = Claim.includes(:profile, :reward).find(params[:id])
  end

  def fetch_claims
    @claims = Claim.where(reward_id: team_reward_ids)
                   .includes(:profile, :reward)
                   .order(created_at: :desc)
                   .page(params[:page])
    apply_search
    apply_reward_filter
    apply_fulfillment_filter
  end

  def apply_search
    return if params[:search].blank?
    @claims = @claims.search(params[:search])
  end

  def apply_reward_filter
    reward_id = params[:reward_id]
    return if reward_id.blank? || reward_id == 'all'
    @claims = @claims.where(reward_id:)
  end

  def apply_fulfillment_filter
    fulfillment = params[:fulfillment]
    return if fulfillment.blank? || fulfillment == 'all'
    @claims = (fulfillment == 'fulfilled' ? @claims.fulfilled : @claims.pending)
  end

  def claim_params
    params.require(:claim).permit(:fulfilled_at, :fulfillment_key).tap do |attrs|
      attrs[:fulfilled_at] = (attrs[:fulfilled_at] == '1' ? Time.current : nil)
    end
  end
end
