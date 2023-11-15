class Base::SubteamSyncService < Base::Service
  option :team

  def call
    destroy_old_subteams
    sync_active_subteams
    assign_app_subteam
  end

  private

  def sync_active_subteams
    remote_subteams.each do |remote_subteam|
      next unless (subteam = find_or_create_subteam(remote_subteam))
      assign_profiles(subteam)
    end
  end

  def assign_profiles(subteam)
    subteam.profiles = Profile.where(team:, rid: profile_rids_for(subteam))
  end

  def assign_app_subteam
    return if app_subteam_rid.blank?
    team.update!(app_subteam_rid:)
  end

  def find_or_create_subteam(attrs) # rubocop:disable Metrics/MethodLength
    base_attrs = base_attributes(attrs)
    sync_attrs = syncable_attributes(attrs)
    if (subteam = Subteam.find_by(base_attrs))
      subteam.update!(sync_attrs)
      subteam
    else
      combined_attrs = base_attrs.merge(sync_attrs)
      Subteam.create!(combined_attrs)
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.error(e)
    nil
  end

  def destroy_old_subteams
    old_rids = team.subteams.pluck(:rid) - remote_subteams.pluck(:id)
    team.subteams.where(rid: old_rids).destroy_all
  end

  def base_attributes(attrs)
    {
      team:,
      rid: attrs[:id]
    }
  end
end
