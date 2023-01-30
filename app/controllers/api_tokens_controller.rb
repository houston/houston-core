class ApiTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :find_api_token, only: [:edit, :update, :destroy]

  def index
    @title = "API Tokens"
    authorize! :read, :all_api_tokens
    @api_tokens = ApiToken.all.preload(:user)
  end

  def mine
    @title = "My API Tokens"
    authorize! :create, ApiToken
    @api_tokens = current_user.api_tokens
    render action: :index
  end

  def new
    @title = "New API Token"
    authorize! :create, ApiToken
    @api_token = ApiToken.new
  end

  def create
    @api_token = current_user.api_tokens.build(params.require(:api_token).permit(:name))
    authorize! :create, @api_token

    if @api_token.save
      redirect_to edit_api_token_path(@api_token)
    else
      render action: :new, error: @api_token.errors.full_messages.to_sentence
    end
  end

  def edit
    @title = "Edit API Token"
    authorize! :update, @api_token
  end

  def update
    authorize! :update, @api_token

    if @api_token.update(params.require(:api_token).permit(:name))
      redirect_to my_api_tokens_path
    else
      render action: :new
    end
  end

  def destroy
    authorize! :destroy, @api_token

    @api_token.destroy
    redirect_to my_api_tokens_path, notice: "Deleted API Token \"#{@api_token.name}\""
  end

private

  def find_api_token
    @api_token = ApiToken.find(params[:id])
  end

end
