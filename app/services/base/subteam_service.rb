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
      subteam = find_or_create_subteam(remote_subteam)
      assign_profiles(subteam, remote_subteam)
    end
  end

  def assign_profiles(subteam, remote_subteam)
    subteam.profiles =
      Profile.collection_with_team(team.rid, profile_rids_for(remote_subteam))
  end

  def assign_app_subteam
    return if app_subteam_rid.blank?
    team.update(app_subteam_rid: app_subteam_rid)
  end

  def find_or_create_subteam(attrs)
    base_attrs = base_attributes(attrs)
    sync_attrs = syncable_attributes(attrs)

    if (subteam = Subteam.find_by(base_attrs))
      subteam.update(sync_attrs)
      return subteam
    end

    Subteam.create!(base_attrs.merge(sync_attrs))
  end

  def destroy_old_subteams
    old_rids = team.subteams.map(&:rid) - remote_subteams.map(&:id)
    team.subteams.where(rid: old_rids).destroy_all
  end

  def base_attributes(subteam)
    {
      team: team,
      rid: subteam.id
    }
  end
end
