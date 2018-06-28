class CoordinateInfosController < ApplicationController

    def coord_info_v1

        db  = params[:db]
        key = params[:key]

        response = CoordinateInfoV1.coord_info_do(params['longitude_x'], params['latitude_y'], db, key)
        render json: response
    end

end
