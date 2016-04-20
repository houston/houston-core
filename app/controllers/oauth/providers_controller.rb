module Oauth
  class ProvidersController < ApplicationController

    def index
      @title = "Providers"
      authorize! :read, Oauth::Provider
      @providers = Oauth::Provider.all
    end

    def new
      @title = "New Provider"
      authorize! :create, Oauth::Provider
      @provider = Oauth::Provider.new
    end

    def create
      @provider = Oauth::Provider.new(params[:oauth_provider])
      authorize! :create, @provider

      if @provider.save
        redirect_to oauth_providers_path
      else
        render action: :new
      end
    end

    def edit
      @title = "Edit Provider"
      @provider = Oauth::Provider.find(params[:id])
      authorize! :update, @provider
    end

    def update
      @provider = Oauth::Provider.find(params[:id])
      authorize! :update, @provider

      if @provider.update_attributes(params[:oauth_provider])
        redirect_to oauth_providers_path
      else
        render action: :edit
      end
    end

  end
end
