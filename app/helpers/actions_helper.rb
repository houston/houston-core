module ActionsHelper

  def format_action_params(params)
    return "<pre>{}</pre>".html_safe if params == {}
    <<-HTML.html_safe
      <div class="action-params-short">
        <pre>{ #{params.keys.map(&:inspect).join(", ")} }</pre>
      </div>
      <div class="action-params-full modal">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
          <h3><code>{ #{params.keys.map(&:inspect).join(", ")} }</code></h3>
        </div>
        <div class="modal-body">
          <pre>#{_add_white_space Houston::ParamsSerializer.new.dump(params)}</pre>
        </div>
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

  def format_action_state(action)
    if action.in_progress?
      '<i class="fa fa-spinner fa-pulse"></i>'.html_safe
    elsif action.succeeded?
      '<i class="fa fa-check success"></i>'.html_safe
    else
      '<i class="fa fa-times failure"></i>'.html_safe
    end
  end

end
