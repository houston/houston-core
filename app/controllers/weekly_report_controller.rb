class WeeklyReportController < ApplicationController
  before_filter :get_date
  
  def show
    monday = @date.beginning_of_week
    @date_range = monday..(6.days.since(monday))
    @projects = Project.scoped
  end
  
  def prepare_email
    show
    @for_email = true
  end
  
  def send_email
    show
    @for_email = true
    
    @recipients = params[:recipients].split
    
    html = render_to_string(template: "weekly_report/show", layout: "email")
    html_with_inline_css = Premailer.new(html, with_html_string: true).to_inline_css
    
    WeeklyReportMailer._new(recipients: @recipients, body: html_with_inline_css).deliver!
  rescue Timeout::Error
    redirect_to send_weekly_report_path, :notice => "Couldn't get a response from the mail server. Is everything OK?"
  end
  
private
  
  def get_date
    if params[:week]
      @date = Date.parse(params[:week])
    elsif params[:year]
      @date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    else
      @date = Date.today
    end
  rescue
    @date = Date.today
  end
  
end
