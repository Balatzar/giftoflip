Rails.application.routes.draw do
  root to: "upload#landing"

  post "/create_flip", to: "upload#create_flip"
end
