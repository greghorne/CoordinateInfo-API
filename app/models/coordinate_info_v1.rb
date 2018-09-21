require "resolv"
require "pg"
require "redis"
require "redis-namespace"

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
    # create pg connection
    # =========================================
    begin
        hostaddr = Resolv.getaddress $db_host_mongo
    rescue # catch the error but just continue
    end

    $conn_pg = PG::Connection.open(
        :host     => $db_host_pg,
        :port     => $db_port_pg,
        :dbname   => $db_name_pg,
        :user     => $db_user_pg,
        :password => $db_pwd_pg,
        :hostaddr => hostaddr,
        :sslmode  => $db_sslmode
    )
    # =========================================


    # =========================================
    # create mongodb connection pool
    # =========================================
    begin
        hostaddr = Resolv.getaddress $db_host_mongo
    rescue # catch the error but just continue
    end

    if hostaddr
        conn_string = hostaddr.to_s + ":" + $db_port_mongo.to_s
    else
        conn_string = $db_host_mongo.to_s + ":" + $db_port_mongo.to_s
    end

    Mongo::Logger.logger.level = Logger::WARN

    puts "conn_string =====>"
    puts conn_string
    puts 

    # valid values are :primary, :primary_preferred, :secondary, :secondary_preferred and :nearest
    $conn_mongo = Mongo::Client.new([conn_string], 
                                    :database       => $db_name_mongo, 
                                    :user           => $db_user_mongo, 
                                    :password       => $db_pwd_mongo, 
                                    :read           => { :mode => :secondary }, 
                                    :min_pool_size  => 2,
                                    :max_pool_size  => 10)
                                    # :replica_set    => 'jdv7vzc6xd07hjjunoykl5l8y')
    # =========================================
    puts "inspect =====>"
    puts $conn_mongo.cluster.inspect
    puts 
    puts "collection namespace =====>"
    puts $conn_mongo.database.collection_names
    puts 
    puts $conn_mongo.read_preference





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
    #
    # deprecated this function which takes a hostname and and resolves the hostaddr (ip)
    # now, a pg connection is being left open and mongo is using a connection pool
    # instead of opening/closing a connection per api request
    # speed difference is enomous completing requests in about 1/3 of the time
    # later, check pooling on pg
    #
    # def self.get_db_conn(db_type)
    #
    #     if db_type == "pg"
    #         host = $db_host_pg
    #     else
    #         host = $db_host_mongo
    #     end
    #
    #
    #     # redis - storing/retrieving host's ip
    #     if $redis.get(host)
    #         hostaddr = $redis.get(host)
    #     else
    #         hostaddr = Resolv.getaddress host
    #         if hostaddr 
    #             $redis.set(host, hostaddr)
    #             $redis.expire(host, 300)
    #         end
    #     end
    #
    # end
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
                :municipality_nl_type2 => response_arr[8],

                :municipality3         => response_arr[10],
                :municipaltiy_nl3      => response_arr[11],
                :municipality_nl_type3 => response_arr[12]
            }
        else
            return_json = {
                :country               => response["NAME_0"],

                :municipality1         => response["NAME_1"],
                :municipaltiy_nl1      => response["NL_NAME_1"],
                :municipality_nl_type1 => response["TYPE_1"],

                :municipality2         => response["NAME_2"],
                :municipaltiy_nl2      => response["NL_NAME_2"],
                :municipality_nl_type2 => response["TYPE_2"],

                :municipality3         => response["NAME_3"],
                :municipaltiy_nl3      => response["NL_NAME_3"],
                :municipality_nl_type3 => response["TYPE_3"]
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

            if coordinate.db == 'pg'

                # postgis function z_world_xy_intersects
                response_query = $conn_pg.query("select z_gadm36_xy_intersect($1, $2)",[coordinate.longitude_x.to_f, coordinate.latitude_y.to_f])

                if response_query.num_tuples.to_i === 1
                    return_json = adjust_response_data(response_query, true)
                end

            else

                collection = $conn_mongo["gadm36"]

                response_cursor = collection.find({"geometry":{"$geoIntersects":{"$geometry":{"type":"Point", "coordinates":[longitude_x.to_f, latitude_y.to_f]}}}}).to_a

                document = response_cursor[0]

                if document 
                    return_json = adjust_response_data(document['properties'], false)
                end

            end

            return_hash = { :success => 1, :results => return_json }
            return JSON.generate(return_hash)

        end

    end
    # ================
end
