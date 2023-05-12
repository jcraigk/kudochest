module MailHelper
  def mail_team_avatar_image(team, size: 120)
    image_tag \
      team.avatar_url,
      alt: 'Team avatar image',
      size:,
      style: 'border-radius: 5px;'
  end

  def mail_profile_avatar_image(profile, size: 120)
    image_tag \
      profile.avatar_url,
      alt: 'Profile avatar image',
      size:,
      style: 'border-radius: 5px;'
  end

  def mail_profile_link(profile)
    link_to(profile.display_name, profile.web_url)
  end
end
