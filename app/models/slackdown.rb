# Converts GitHub-flavored Markdown to Slack-flavored Markdown
class Slackdown
  attr_reader :markdown

  def initialize(markdown)
    @markdown = markdown
  end

  def convert
    # Remove the source name from fenced code blocks
    slackdown = markdown.gsub(/^```(ruby|diff|css|json|sql|html|xml|coffee(?:script)?|javascript|js|bash)/, "```")

    # Convert `__` and `**` to `*`
    slackdown = slackdown.gsub(/(?<!_)__(?!_)/, "*")
                         .gsub(/(?<!\*)\*\*(?!\*)/, "*")

    # Replace images with their URLs: Slack will unfurl them
    slackdown = slackdown.gsub(/<img[^>]*src="([^"]+)"[^>]*>/, "\\1")
    slackdown
  end
  alias :to_s :convert

end
