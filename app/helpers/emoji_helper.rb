module EmojiHelper
  include ActionView::Helpers::AssetTagHelper

  def emojify(content, opts = {})
    return if content.blank?
    content.gsub(/:([\w+-]+):/) do |match|
      emoji_alias = Regexp.last_match[1]
      emoji = Emoji.find_by_alias(emoji_alias) # rubocop:disable Rails/DynamicFindBy
      return match unless emoji
      image_tag \
        emoji_image_url(emoji),
        { alt: emoji_alias, class: 'emoji' }.merge(opts)
    end.html_safe # rubocop:disable Rails/OutputSafety
  end

  def emoji_image_url(emoji)
    "https://github.githubassets.com/images/icons/emoji/#{emoji.image_filename}"
  end
end
