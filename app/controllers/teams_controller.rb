class TeamsController < ApplicationController
  before_action :find_team, only: [:edit, :update]
  load_and_authorize_resource except: [:index]


  def index
    @title = "Teams"
    @teams = Team.all.select { |team| can?(:read, team) }
    authorize! :read, :teams
  end


  def new
    @title = "New Team"
    @team = Team.new
    @team.roles.build(user: current_user, roles: ["Team Owner"]) if @team.roles.none?
  end


  def create
    @team = Team.new(team_attributes)

    if @team.save
      redirect_to teams_path, notice: "Team was successfully created."
    else
      flash.now[:error] = @team.errors[:base].join("\n")
      render action: "new"
    end
  end


  def edit
    @title = "Edit #{@team.name}"
    @team.roles.build(user: current_user, roles: ["Team Owner"]) if @team.roles.none?
  end


  def update
    @team.props.merge! team_attributes.delete(:props) if team_attributes.key?(:props)

    if @team.update_attributes(team_attributes)
      redirect_to teams_path, notice: "Team was successfully updated."
    else
      flash.now[:error] = @team.errors[:base].join("\n")
      render action: "edit"
    end
  end


private

  def find_team
    @team = Team.find(params[:id])
  end

  def team_attributes
    params.fetch(:team)
    # params.require(:team).permit(:name, :roles_attributes)
  end

end
