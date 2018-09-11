require "resolv"
require "pg"
require "redis"
require "redis-namespace"

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

        if db_type == "pg"
            host = $db_host_pg
        else
            host = $db_host_mongo
        end

        # the following redis statemetns is to just play aroundd
        # and experiment with redis.
        if $redis.get(host)
            hostaddr = $redis.get(host)
            puts "found =====>"
        else
            hostaddr = Resolv.getaddress host
            if hostaddr 
                $redis.set(host, hostaddr)
                $redis.expire(host, 60)
                puts "not found <====="
            end
        end

        case db_type
            when "pg"

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

                    if hostaddr
                        conn_string = hostaddr.to_s + ":" + $db_port_mongo.to_s
                    else
                        conn_string = $db_host_mongo.to_s + ":" + $db_port_mongo.to_s
                    end

                    conn = Mongo::Client.new([conn_string], :database => $db_name_mongo, :user => $db_user_mongo, :password => $db_pwd_mongo)
                    return conn

                rescue
                    return false
                end

        end
    end
    # =========================================

    # =========================================
    def self.adjust_response_data(response, type)

        # string manipulation of the query response to json
        if type
            response_arr = response[0]["z_gadm36_xy_intersect"].tr('())', '').gsub(/[\"]/,"").split(",")
            return_json = {
                :country               => response_arr[1],

                :municipality1         => response_arr[2],
                :municipaltiy_nl1      => response_arr[3],
                :municipality_nl_type1 => response_arr[4],

                :municipality2         => response_arr[6],
                :municipaltiy_nl2      => response_arr[7],
                :municipality_nl_type2 => response_arr[8]
            }
        else
            return_json = {
                :country               => response["NAME_0"],

                :municipality1         => response["NAME_1"],
                :municipaltiy_nl1      => response["NL_NAME_1"],
                :municipality_nl_type1 => response["TYPE_1"],

                :municipality2         => response["NAME_2"],
                :municipaltiy_nl2      => response["NL_NAME_2"],
                :municipality_nl_type2 => response["TYPE_2"]
            }
        end

        return return_json
    end
    # =========================================

    # =========================================
    def self.coord_info_do(longitude_x, latitude_y, db, key)

        # pass request params and create coordinate object
        coordinate = Coordinate.new(longitude_x, latitude_y, key, db)

        # check validity of x,y coordinates
        if !coordinate.valid_xy

            return_hash = { :success => 0,  :results =>  { msg: "invalid longitude_x and/or latitude_y" } }
            return JSON.generate(return_hash)

        else
            # get db connection
            conn = get_db_conn(coordinate.db)

            if conn

                return_json = {}
                if coordinate.db == 'mongo'

                    collection = conn["gadm36"]

                    response_cursor = collection.find({"geometry":{"$geoIntersects":{"$geometry":{"type":"Point", "coordinates":[longitude_x.to_f, latitude_y.to_f]}}}})

                    # some weirdness here; check on how to do it properly
                    document = ""
                    response_cursor.each { |doc| 
                        document = doc 
                        break 
                    }

                    if document 
                        return_json = adjust_response_data(document['properties'], false)
                    end

                else

                    # postgis function z_world_xy_intersects
                    response_query = conn.query("select z_gadm36_xy_intersect($1, $2)",[coordinate.longitude_x.to_f, coordinate.latitude_y.to_f])
                    conn.close

                    if response_query.num_tuples.to_i === 1
                        return_json = adjust_response_data(response_query, true)
                    end

                end
                return_hash = { :success => 1, :results => return_json }
                return JSON.generate(return_hash)

            else
                return_hash = { :success => 0, :results =>  { msg: "database connect error" } }
                return JSON.generate(return_hash)

            end

        end

    end
    # ================
end
