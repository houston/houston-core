module ActionsHelper

  def format_action_params(params)
    return "<pre>{}</pre>".html_safe if params == {}
    <<-HTML.html_safe
      <div class="action-params-short">
        <pre>{ #{params.keys.map(&:inspect).join(", ")} }</pre>
      </div>
      <div class="action-params-full">
        <pre>#{_add_white_space Houston::ParamsSerializer.new.dump(params)}</pre>
      </div>
    HTML
  end

  def _add_white_space(json)
    scanner = StringScanner.new(json)
    output = ""
    indent = 0
    until scanner.eos?
      match = scanner.scan(/(?:[\[\]\{\}":,]|[^\[\]\{\}":,]+)/)
      case match
      when "{", "["
        indent += 2
        output << "#{match}\n#{" " * indent}"
      when "}", "]"
        indent -= 2
        output << "\n#{" " * indent}#{match}"
      when "\""
        # hopefully this grabs the entire string
        output << "\"" << scanner.scan(/.*?(?<!\\)"/)
      when ":"
        output << ": "
      when ","
        output << ",\n#{" " * indent}"
      else
        output << match
      end
    end
    output
  end

end