module ScoreCardHelper
  
  def score_card(*args)
    options = args.extract_options!
    size = args.first
    score_card = ScoreCard.new(self, options, size)
    yield score_card
    score_card.generate
  end
  
end

class ScoreCard
  
  def initialize(view, options={}, size)
    @view = view
    @options = options
    @size = size
    @scores = []
  end
  
  def score(label, value, options={})
    score_count_class = Array(options.delete(:score_count_class)) << "score-count"
    precision = options.delete(:precision)
    
    css = Array(options.fetch(:class, []))
    if value.is_a?(Numeric)
      css << "zero" if value == 0
      css << "positive" if value > 0
      css << "negative" if value < 0
    end
    
    if value.is_a?(Float) && (value.nan? || value.infinite?)
      value = "&mdash;".html_safe
      css << "nan"
    elsif precision
      value = @view.number_with_precision(value, precision: precision) if precision
    end
    
    value = value.to_s.gsub(/\./, '<span class="period">.</span>')
    value = options[:prefix] + value if options[:prefix]
    value << "<span class=\"unit\">#{options[:unit]}</span>" if options[:unit]
    
    @scores << @view.content_tag(:p, :class => css.join(" ")) do
      @view.content_tag(:span, value.html_safe, :class => score_count_class.join(" ")) +
      @view.content_tag(:span, label, :class => "score-label")
    end
    
    nil
  end
  
  def fraction(label, numerator, denominator, options={})
    return score(label, numerator, options) unless denominator
    
    precision = options.delete(:precision)
    if precision
      numerator = @view.number_with_precision(numerator, precision: precision)
      denominator = @view.number_with_precision(denominator, precision: precision)
    end
    
    value = "<span class=\"numerator\">#{numerator}</span>" +
            "<span class=\"divided-by\">/</span>" +
            "<span class=\"denominator\">#{denominator}</span>"
    score(label, value.html_safe, options.merge(score_count_class: "fraction"))
  end
  
  def percent(label, value, options={})
    score(label, value, options.reverse_merge(precision: 0).merge(score_count_class: "percent"))
  end
  
  def raw(content=nil, &block)
    content = @view.capture(&block) if block_given?
    @scores << content
  end
  
  def generate
    css = ["score"].concat Array(@options.fetch(:class, []))
    css << "score-giant" if @size == :giant
    css << "score-large" if @size == :large
    css << "score-medium" if @size == :medium
    css << "score-small" if @size == :small
    @view.content_tag(:div, @scores.join.html_safe, @options.slice(:style).merge(:class => css.join(" ")))
  end
  
end
