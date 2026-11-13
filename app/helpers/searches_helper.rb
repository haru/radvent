# frozen_string_literal: true

# Helpers for the article search results: excerpts and keyword highlighting.
module SearchesHelper
  # Number of characters kept on each side of the first match in an excerpt.
  EXCERPT_RADIUS = 60
  # Length of the head-of-body excerpt used when no keyword appears in the body.
  EXCERPT_FALLBACK_LENGTH = EXCERPT_RADIUS * 2

  # Builds a plain-text excerpt of a body (Markdown is shown as written).
  #
  # Whitespace is collapsed. The excerpt is centered on the first keyword match, or is the head of the body
  # when no keyword is found in the body (e.g. only the title matched). The result is plain, unescaped text;
  # pass it through #highlight_keywords, which escapes it exactly once.
  #
  # @param body [String, nil] the article body
  # @param keywords [Array<String>] non-empty list of non-blank search keywords
  # @return [String, nil] the excerpt, or nil when the body is blank
  # @raise [ArgumentError] when keywords is empty or contains a blank keyword
  def search_excerpt(body, keywords)
    text = body.to_s.squish
    pattern = keyword_pattern(keywords)
    return nil if text.empty?

    excerpt(text, pattern, radius: EXCERPT_RADIUS, omission: '…') ||
      text.truncate(EXCERPT_FALLBACK_LENGTH, omission: '…')
  end

  # Escapes the text and wraps keyword matches in +mark+ tags.
  #
  # Every fragment is escaped separately, so nothing from the text is ever output as markup.
  #
  # @param text [String] plain text
  # @param keywords [Array<String>] non-empty list of non-blank search keywords
  # @return [ActiveSupport::SafeBuffer] HTML safe text with matches marked
  # @raise [ArgumentError] when keywords is empty or contains a blank keyword
  def highlight_keywords(text, keywords)
    # Splitting on a single capture group puts the matches at the odd indexes.
    fragments = text.to_s.split(/(#{keyword_pattern(keywords)})/).each_with_index.map do |fragment, index|
      index.odd? ? content_tag(:mark, fragment) : h(fragment)
    end
    safe_join(fragments)
  end

  private

  # Builds a case-insensitive regexp matching any keyword literally, the longest keyword first so that
  # overlapping keywords mark the longest match.
  #
  # @param keywords [Array<String>] non-empty list of non-blank search keywords
  # @return [Regexp] the pattern
  # @raise [ArgumentError] when keywords is empty or contains a blank keyword (it would match everywhere)
  def keyword_pattern(keywords)
    raise ArgumentError, 'keywords must not be empty or blank' if keywords.empty? || keywords.any?(&:blank?)

    Regexp.new(keywords.sort_by { |keyword| -keyword.length }.map { |keyword| Regexp.escape(keyword) }.join('|'),
               Regexp::IGNORECASE)
  end
end
