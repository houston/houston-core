module AnsiHelper

  ANSI_COLOR = {
     "1" => "ansi-bold",
     "4" => "ansi-underline",
    "30" => "ansi-black",
    "31" => "ansi-red",
    "32" => "ansi-green",
    "33" => "ansi-yellow",
    "34" => "ansi-blue",
    "35" => "ansi-magenta",
    "36" => "ansi-cyan",
    "37" => "ansi-white",
    "90" => "ansi-bright-black",
    "91" => "ansi-bright-red",
    "92" => "ansi-bright-green",
    "93" => "ansi-bright-yellow",
    "94" => "ansi-bright-blue",
    "95" => "ansi-bright-magenta",
    "96" => "ansi-bright-cyan",
    "97" => "ansi-bright-white" }.freeze

  def ansi_to_html(ansi)
    return "" if ansi.nil?

    html = "<div class=\"ansi\">"
    string = StringScanner.new(ansi.gsub("<", "&lt;"))
    spans = 0
    until string.eos?
      if string.scan(/\e\[(3[0-7]|90|1)m/)
        html << "<span class=\"#{ANSI_COLOR[string[1]]}\">"
        spans += 1
      elsif string.scan(/\e\[0m/)
        while spans > 0
          html << "</span>"
          spans -= 1
        end
      else
        html << string.scan(/./m)
      end
    end
    html << "</div>"
    html.html_safe
  end

end
