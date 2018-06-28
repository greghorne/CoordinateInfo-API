# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_06_28_175140) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "apitests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "coordinate_infos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "somemodels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spatial_ref_sys", primary_key: "srid", id: :integer, default: nil, force: :cascade do |t|
    t.string "auth_name", limit: 256
    t.integer "auth_srid"
    t.string "srtext", limit: 2048
    t.string "proj4text", limit: 2048
  end

# Could not dump table "tabblock_2010_pophu" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4269)' for column 'geom'

# Could not dump table "temp_table_mbr_blocks" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4269)' for column 'geom'

# Could not dump table "tl_2016_us_state" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4269)' for column 'geom'

# Could not dump table "tl_2017_us_county" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4269)' for column 'geom'

# Could not dump table "tl_2017_us_zcta510" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4269)' for column 'geom'

# Could not dump table "user_multi_polygon" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4269)' for column 'geom'

# Could not dump table "user_point" because of following StandardError
#   Unknown type 'geometry(Point,4269)' for column 'geom'

# Could not dump table "user_polygon" because of following StandardError
#   Unknown type 'geometry(Polygon,4269)' for column 'geom'

# Could not dump table "world" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

end
