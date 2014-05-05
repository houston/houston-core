class ProjectPreticketsController < ApplicationController
  before_filter :find_project
  before_filter :api_authenticate!
  
  
  def show
    @problems = @project.error_tracker.open_problems(comments: true).sort_by(&:last_notice_at).reverse
    antecedents = @problems.map(&:err_ids).flatten.map { |id| "'Errbit:#{id}'" }
    tickets = antecedents.any? ? @project.tickets.where("antecedents && ARRAY[#{antecedents.join(",")}]") : []
    tickets.each do |ticket|
      ticket.antecedents.each do |antecedent|
        next unless antecedent.kind == "Errbit"
        err_id = antecedent.id.to_i
        problem = @problems.detect { |problem| problem.err_ids.member?(err_id) }
        problem.ticket = ticket if problem
      end
    end
  end
  
  
private
  
  def find_project
    @project = Project.find_by_slug!(params[:slug])
  end
  
end
