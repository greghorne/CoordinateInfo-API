class HomeController < ApplicationController
    def index 

        puts "HomeController.index"
        # render :index
        # render "home/index"
        # render 'index.html.erb'
        # render text: "hello"
        # render "index"

        render html: 'For information: https://github.com/greghorne/CoordinateInfo-API', layout: true

    end
end