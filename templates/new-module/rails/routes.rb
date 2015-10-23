Rails.application.routes.draw do

  mount Houston::<%= camelized %>::Engine => "/<%= name %>"

end
