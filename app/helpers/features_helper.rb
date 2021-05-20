# frozen_string_literal: true
module FeaturesHelper
  def feature_modal_link(key)
    base = "features.list.#{key}"
    icon_key = t("#{base}.icon")
    link_to(
      icon_and_text(icon_key, t("#{base}.title")),
      '#',
      data: {
        detail: t("#{base}.detail"),
        icon: "fa-#{icon_key}"
      }
    )
  end
end
