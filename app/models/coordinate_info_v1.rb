class CoordinateInfoV1 < ApplicationRecord

    $db_host = ENV["RAILS_HOST"]
    $db_name = ENV["RAILS_DATABASE"]
    $db_port = ENV["RAILS_PORT"]
    $db_user = ENV["RAILS_USERNAME"]
    $db_pwd  = ENV["RAILS_PASSWORD"]

    # $db_pwd  = "password"

    # =========================================
    class Coordinate

        def initialize(longitude_x, latitude_y, key, db)
            @longitude_x = longitude_x
            @latitude_y  = latitude_y
            @key         = key.to_s 

            (db.to_s === "pg" || db.to_s === "mongo") ? @db = db : @db="pg"
        end

        attr_reader :longitude_x, :latitude_y, :key, :db
            
        private def longitude_valid(value)
            (value >= -180 && value <= 180) ? true : false
        end

        private def latitude_valid(value)
            (value >= -90 && value <= 90) ? true : false
        end

        def valid_xy
            ((Float(@longitude_x) rescue false) && (Float(@latitude_y) rescue false)) && 
                (longitude_valid(Float(@longitude_x)) && latitude_valid(Float(@latitude_y))) ? true : false
        end

        def check_key
            # right now we are not checking @key
        end

    end
    # =========================================

    # =========================================
    def self.get_db_conn(db_type)

        case db_type
            when "pg"
                begin
                    conn = PG::Connection.open(
                        :host     => $db_host,
                        :port     => $db_port,
                        :dbname   => $db_name,
                        :user     => $db_user,
                        :password => $db_pwd
                    )

                    return conn
                rescue PG::Error => e
                    return false
                end

            when "mongo"
                begin

                end

        end
    end
    # =========================================

    # =========================================
    def self.adjust_response_data(response)

        # string manipulation of the query response to json

        response_arr = response[0]["z_world_xy_intersect"].tr('())', '').gsub(/[\"]/,"").split(",")
        return_json = {
            :country               => response_arr[1],

            :municipality1         => response_arr[2],
            :municipaltiy_nl1      => response_arr[3],
            :municipality_nl_type1 => response_arr[4],

            :municipality2         => response_arr[6],
            :municipaltiy_nl2      => response_arr[7],
            :municipality_nl_type2 => response_arr[8]
        }
        return return_json
    end
    # =========================================

    # =========================================
    def self.coord_info_do(long_x, lat_y, db, key)

        # ----------------------------------------
        # ----------------------------------------
        # mongo support in progress; reject and exit out
puts "--------------"
puts db
puts "--------------"
        if db == "mongo"
            return_hash = { :success => 0, 
                :results =>  { msg: "mongo currently not supported" }
              }

            return JSON.generate(return_hash)
        end
        # ----------------------------------------
        # ----------------------------------------


        # pass request params and create coordinate object
        coordinate = Coordinate.new(long_x, lat_y, key, db)

        # check validity of x,y coordinates
        if !coordinate.valid_xy

            return_hash = { :success => 0, 
                            :results =>  { msg: "invalid lat_y and/or long_x" }
                          }

            return JSON.generate(return_hash)

        else
            # get db connection and execute query-function
            conn = get_db_conn(coordinate.db)

            if conn

                # postgis function z_world_xy_intersects
                response_query = conn.query("select z_world_xy_intersect($1, $2)",[coordinate.longitude_x.to_f, coordinate.latitude_y.to_f])
                conn.close

                if response_query.num_tuples.to_i === 1
                    return_json = adjust_response_data(response_query)
                else
                    return_json = {}
                end

                return_hash = { :success => 1,
                                :results => return_json 
                            }

                return JSON.generate(return_hash)

            else
                return_hash = { :success => 0, 
                    :results =>  { msg: "database connect error" }
                  }

                return JSON.generate(return_hash)

            end

        end

    end
    # ================
end
