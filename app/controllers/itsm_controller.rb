require 'ntlm/http'

class ItsmController < ApplicationController
  
  def index
    http = Net::HTTP.start("ecphhelpertest", 80)
    req = Net::HTTP::Get.new("/ITSM.asmx/GetOpenCallsEmergingProducts")
    req.ntlm_auth("Houston", "cph.pri", "gKfub6mFy9BHDs6")
    response = http.request(req)
    @issues = Hash.from_xml(response.body)["ArrayOfOpenCallData"]["OpenCallData"].map do |issue|
      issue.merge("CallDetailUrl" => Nokogiri::HTML::fragment(issue["CallDetailLink"]).children.first[:href])
    end
    
    render partial: "itsm/fires" if request.xhr?
  end
  
end
