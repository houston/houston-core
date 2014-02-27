require 'ntlm/http'

class ItsmController < ApplicationController
  
  def index
    http = Net::HTTP.start("ecphhelpertest", 80)
    req = Net::HTTP::Get.new("/ITSM.asmx/GetOpenCallsEmergingProducts")
    req.ntlm_auth("Houston", "cph.pri", "gKfub6mFy9BHDs6")
    response = http.request(req)
    issues = Hash.from_xml(response.body).fetch("ArrayOfOpenCallData").fetch("OpenCallData", [])
    @issues = issues.map do |issue|
      url = Nokogiri::HTML::fragment(issue["CallDetailLink"]).children.first[:href]
      user = User.find_by_email_address(issue["AssignedToEmailAddress"])
      Issue.new(issue["Summary"], url, issue["AssignedToEmailAddress"], user)
    end
    
    render partial: "itsm/fires" if request.xhr?
  end
  
  
  Issue = Struct.new(:summary, :url, :assigned_to_email, :assigned_to_user)
  
end
