#!/bin/bash 

#
# shp2pgsql will look for the environment variable PGPASSWORD
#
echo "export PGPASSWORD=my_password"

eval "shp2pgsql  -d -e -s 4326 /Users/greghorne/Downloads/gadm28.shp/gadm28 world > shapeinsert.sql"

eval "psql -h 192.168.1.72 -d postgres -U gis -f shapeinsert.sql"

eval "rm shapeinsert.sql"

echo "================= finihed ================="
