require "resolv"
# require "redis"
# require "redis-namespace"

$redis = Redis::Namespace.new("redis_hostnames", :redis => Redis.new)

class CoordinateInfoV1 < ApplicationRecord

    $db_host_pg    = ENV["RAILS_HOST_PG"]
    $db_name_pg    = ENV["RAILS_DATABASE_PG"]
    $db_port_pg    = ENV["RAILS_PORT_PG"]
    $db_user_pg    = ENV["RAILS_USERNAME_PG"]
    $db_pwd_pg     = ENV["RAILS_PASSWORD_PG"]
    $db_sslmode    = "require"

    $db_host_mongo = ENV["RAILS_HOST_MONGO"]
    $db_name_mongo = ENV["RAILS_DATABASE_MONGO"]
    $db_port_mongo = ENV["RAILS_PORT_MONGO"]
    $db_user_mongo = ENV["RAILS_USERNAME_MONGO"]
    $db_pwd_mongo  = ENV["RAILS_PASSWORD_MONGO"]

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
puts db_type
puts "traceA"
        case db_type
            when "pg"
                
                # try and see if i can cache the hostaddr
                # if $redis.get($db_host_pg)
                #     puts "found"
                # else
                #     puts "not found"
                # end

                # resolve the host ip address if necessary; :hostaddr (ip) overrides :host (name)

                begin
                    hostaddr = Resolv.getaddress $db_host_pg
                rescue
                    # catch the error but just continue
                end

                begin
                    conn = PG::Connection.open(
                        :host     => $db_host_pg,
                        :port     => $db_port_pg,
                        :dbname   => $db_name_pg,
                        :user     => $db_user_pg,
                        :password => $db_pwd_pg,
                        :hostaddr => hostaddr,
                        :sslmode  => $db_sslmode
                    )

                    return conn
                rescue PG::Error => e
                    return false
                end

            when "mongo"
                begin
                    hostaddr = Resolv.getaddress $db_host_mongo
                rescue
                    # catch the error but just continue
                end

                begin
                    Mongo::Logger.logger.level = ::Logger::FATAL
                    # puts $db_host_mongo
                    # puts $db_name_mongo
                    # puts $db_port_mongo
                    # puts "start"
                    # conn = Mongo::Connection.new($db_host_mongo, $db_port_mongo).db($db_name_mongo)
                    # conn = Mongo::Connection.new("192.168.1.120", 27017).db("gadm")

                    conn = Mongo::Client.new([ $db_host_mongo], :database => $db_name_mongo)
                    return conn
                    
                    # conn = PG::Connection.open(
                    #     :host     => $db_host_mongo,
                    #     :port     => $db_port_mongo,
                    #     :dbname   => $db_name_mongo,
                    #     :user     => $db_user_mongo,
                    #     :password => $db_pwd_mongo,
                    #     :hostaddr => hostaddr,
                    #     :sslmode  => $db_sslmode
                    # )
                rescue
                    puts client
                    return false
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
    def self.coord_info_do(longitude_x, latitude_y, db, key)

        # ----------------------------------------
        # ----------------------------------------
        # mongo support in progress; reject and exit out
        # if db == "mongo"
        #     return_hash = { :success => 0, 
        #         :results =>  { msg: "mongo currently not supported" }
        #       }

        #     return JSON.generate(return_hash)
        # end
        # ----------------------------------------
        # ----------------------------------------


        # pass request params and create coordinate object
        coordinate = Coordinate.new(longitude_x, latitude_y, key, db)

        # check validity of x,y coordinates
        if !coordinate.valid_xy

            return_hash = { :success => 0, 
                            :results =>  { msg: "invalid longitude_x and/or latitude_y" }
                          }

            return JSON.generate(return_hash)

        else
            # get db connection and execute query-function
            conn = get_db_conn(coordinate.db)

            if conn

                if coordinate.db == 'mongo'
                    collection = conn["gadm36"]
                    puts collection.count()
                    # response_query = collection.find({"geometry":{"$geoIntersects":{"$geometry":{"type":"Point", "coordinates":[longitude_x, latitude_y]}}}})
                    response_query = collection.find({"geometry":{"$geoIntersects":{"$geometry":{"type":"Point", "coordinates":[-95, 35]}}}})
                    puts response_query.each { |doc| puts doc }
                    puts response_query[0]


                else
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
                end

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
