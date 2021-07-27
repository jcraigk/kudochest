# frozen_string_literal: true
class TeamOwnerMailer < ApplicationMailer
  layout 'email'

  def data_export(team, csv_str)
    @team = team
    attachments['karmachest_team_data.csv'] = csv_str
    mail to: team.owning_user.email, subject: I18n.t('teams.export_data')
  end

  def bonus_calculator(team, csv_str)
    @team = team
    attachments['karmachest_bonus_calculator.csv'] = csv_str
    mail to: team.owning_user.email, subject: I18n.t('nav.bonus_calculator')
  end
end
