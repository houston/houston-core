class ApplicationController < ActionController::Base
  include FreightTrain
  protect_from_forgery
end
