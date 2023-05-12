class OneProfilePerTeamPerUserValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    return if record.user_id.nil? || conflicting_profile.blank?
    record.errors.add(:base, :one_team_profile_per_user)
  end

  private

  def conflicting_profile
    rel = Profile.where(user_id: record.user_id, team_id: record.team_id)
    rel = rel.where.not(id: record.id) if record.persisted?
    rel.first
  end
end
