class WeeklyReportController < ApplicationController
  before_filter :get_date
  before_filter :get_weekly_report
  skip_before_filter :verify_authenticity_token, :only => :send_email
  
  def show
    @projects = Project.unretired
  end
  
  def prepare_email
    show
    @for_email = true
  end
  
  def send_email
    @recipients = params[:recipients].split(/[\r\n]+|;/)
    @weekly_report.deliver_to!(@recipients)
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
  
  def get_weekly_report
    @weekly_report = WeeklyReport.new(@date)
    @title = @weekly_report.title
  end
  
end
