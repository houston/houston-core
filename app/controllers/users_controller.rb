class UsersController < ApplicationController
  load_and_authorize_resource
  
  # GET /users
  # GET /users.json
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    
    respond_to do |format|
      format.html do
        
        template = "show"
        
        if @user.tester?
          template = "tester_wall"
          tickets_in_testing = Ticket.in_queue "in_testing"
          
          # These are tickets that are:
          #  1. In Testing
          #  2. Where the tester's most recent note is failing
          #  3. Where the tester's most recent note is before a release
          @tickets_to_retest = []
          
          # These are tickets that are:
          #  1. In Testing
          #  2. Where the tester hasn't created any notes
          @tickets_to_test = tickets_in_testing.without_testing_notes_by(@user)
          
          # These are tickets that are:
          #  1. In Testing
          #  2. Where the tester _hash_ created a note
          #  3. That are not in @tickets_to_retest
          @tickets_already_tested = tickets_in_testing.with_testing_notes_by(@user)
        end
        
        render template: "users/#{template}"
      end
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.invite!(params[:user])
    
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully invited.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
