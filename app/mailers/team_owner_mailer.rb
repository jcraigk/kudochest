class TeamOwnerMailer < ApplicationMailer
  layout 'email'

  def data_export(team, csv_str)
    @team = team
    attachments["#{App.app_name} Team Data.csv"] = csv_str
    mail to: team.owning_user.email, subject: I18n.t('teams.export_data')
  end

  def bonus_calculator(team, csv_str)
    @team = team
    attachments["#{App.app_name} Bonus Calculator.csv"] = csv_str
    mail to: team.owning_user.email, subject: I18n.t('nav.bonus_calculator')
  end
end
