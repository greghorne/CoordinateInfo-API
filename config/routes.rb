Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope "/api" do
    scope "/v1" do
      get "coord_info" => "coordinate_infos#coord_info_v1"
    end
  end

  get  'home/index' => 'home#index'
  root 'home#index'

end
