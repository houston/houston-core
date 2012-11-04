class Admin::TagsController < ApplicationController
  include FreightTrain
  respond_to :html
  uses_freight_train
  
  
  def index
    @tags = Tag.all
  end
  
  
  def update
    @tag = Tag.find(params[:id])
    @tag.update_attributes params[:tag]
    respond_with @tag
  end
  
  
  
end
