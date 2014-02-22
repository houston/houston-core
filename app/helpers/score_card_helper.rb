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
    prefixed_value = ""
    css = Array(options.fetch(:class, []))
    
    if value
      css << "zero" if value == 0
      css << "positive" if value > 0
      css << "negative" if value < 0
      
      if value.is_a?(Float) && (value.nan? || value.infinite?)
        value = "&mdash;".html_safe
        css << "nan"
      elsif precision
        value = @view.number_with_precision(value, precision: precision) if precision
      end
      
      prefixed_value = options[:prefix] ? "#{options[:prefix]}#{value}".html_safe : value
    else
      label = ""
    end
      
    tag = :p
    tag_options = {:class => css.join(" ")}
    if options.key?(:href)
      tag = :a
      tag_options.merge!(options.pick(:href))
      tag_options.merge!(target: "_blank")
    end
    
    @scores << @view.content_tag(tag, tag_options) do
      @view.content_tag(:span, prefixed_value, :class => score_count_class.join(" ")) +
      @view.content_tag(:span, label, :class => "score-label")
    end
    
    nil
  end
  
  def percent(label, value, options={})
    score(label, value, options.merge(score_count_class: "percent", precision: 0))
  end
  
  def raw(content=nil, &block)
    content = @view.capture(&block) if block_given?
    @scores << content
  end
  
  def generate
    css = ["score"].concat Array(@options.fetch(:class, []))
    css << "score-large" if @size == :large
    css << "score-medium" if @size == :medium
    css << "score-small" if @size == :small
    @view.content_tag(:div, @scores.join.html_safe, @options.slice(:style).merge(:class => css.join(" ")))
  end
  
end
