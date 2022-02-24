# frozen_string_literal: true

# Filter out message content from Slack to promote privacy
Rails.application.config.filter_parameters += %i[password message text]
