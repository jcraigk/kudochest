class ApplicationMailer < ActionMailer::Base
  default from: App.from_email
end
