# frozen_string_literal: true
class Base::SubteamService < Base::Service
  option :team

  def call
    sync_active_subteams
    destroy_old_subteams
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
    subteam.profiles = Profile.collection_with_team(team.rid, profile_rids_for(subteam))
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
      return subteam
    end

    combined_attrs = base_attrs.merge(sync_attrs)
    Subteam.create!(combined_attrs)
  rescue ActiveRecord::RecordInvalid => e
    parameters = { attrs: attrs.to_h, combined_attrs: }
    Honeybadger.notify(e, parameters:) if defined?(Honeybadger)
    nil
  end

  def destroy_old_subteams
    old_rids = team.subteams.pluck(:rid) - remote_subteams.pluck(:id)
    team.subteams.where(rid: old_rids).destroy_all
  end

  def base_attributes(remote_subteam)
    {
      team_id: team.id,
      rid: remote_subteam[:id]
    }
  end
end
