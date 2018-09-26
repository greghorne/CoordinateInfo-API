class CoordinateInfosController < ApplicationController

    config.middleware.insert_before 0, "Rack::Cors" do
        allow do
            origins '*'
            resource '*', :headers => :any, :methods => [:get, :post, :options]
        end
    end

    def coord_info_v1

        begin

            key = params[:key]
            db  = params[:db]

            response = CoordinateInfoV1.coord_info_do(params[:longitude_x], params[:latitude_y], db, key)

            if JSON.parse(response)["success"] === 1
                render json: response, status: 200
            else
                render json: response, status: 400
            end
       
        rescue Exception => e 

            return_hash = { :success => 0,
                            :results =>  { :msg => e.to_s}
            }

            render json: return_hash, status: 500

        end
    end

end
