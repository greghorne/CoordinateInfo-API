class CoordinateInfosController < ApplicationController

    def coord_info_v1

        db  = params['db']
        key = params['key']

        response - coordinate_info_v1(params['longitude_x'], params['latitude_y'], db, key)
        # return_hash = { :msg => "hello" }
        render json: response
    end

end
