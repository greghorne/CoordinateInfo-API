### CoordinateInfoAPI

Scope:

	-   Rails 5.2.1 API
	-   Given an x, y coordinate, return country and municipality information that intersects the coordinates.


Data Source:

	-   GADM dataset of Global Administrative Area - www.gadm.org
	-   File version 3.6 (June 2018 - gadm36_shp.zip)


Tech Stack:

	-   Development Machine - Vagrant ubuntu/trusty32 - (3.13.0-110-generic)
	-   Vagrant Box setup script: https://github.com/greghorne/VagrantRailsBox/blob/master/setup.sh

	-   Ruby 2.5.1p57 (2018-03-09 revision 63029) [i686-linux]
	-   Rails 5.2.1
    -   Redis 4.0.11
	
	-   PostgreSQL 9.4 with PostGIS 2.1.4
	    Executing on a Raspberry Pi 2 Model B running Raspbian-Jessie
	-   MongoDB v4.0.1
	    Executing as a Docker 18.06.1-ce replica set, primary, secondary & arbiter, on a Raspberry Pi 3 B running HypriotOS x64
	-   (Note: PostgreSQl & MongoDB contain the same gadm36 dataset)
	   
    -   API tested with Postman (see 'test' folder for JSON test files)
       
    -   Deployed to Heroku (free tier):  https://coordinate-info.herokuapp.com
    -   (Note: Initial API call may require the API to spin-up from sleep on Heroku)
 

API Usage:

    - Requests are throttled to 100 requests per 2 minutes per ip.

    - https://coordinate-info.herokuapp.com/api/v1?longitude_x=float&latitude_y=float&db=db_type&key=optional

        longitude_x = type: float 
        latitude_y  = type: float 
        db = type: string ==> pg (default) or mongo 

    - Return value is JSON
        {
            "success": integer         1 = success, 0 = error (check this value first)
            "response": {
                country:               country name in English
                municipality1:         municipality name in English
                municipality_nl1:      municipality name in native language
                municipality_nl_type1: municipality type in native language spelled in English
                municipality2:         municipality name in English
                municipality_nl2:      municipality name in native language
                municipality_nl_type2: municipality type in native language spelled in English
                municipality3:         municipality name in English
                municipality_nl3:      municipality name in native language
                municipality_nl_type3: municipality type in native language spelled in English
            }
        }

        if success = 0 then "response" will contain a "msg" (see below for example)

Example API Calls:

    - example https://coordinate-info.herokuapp.com/api/v1/coord_info?longitude_x=88.445670&latitude_y=23.243660

        returns JSON (intersects location in India)

        {
            "success": 1,
            "response": {
                "country": "India",
                "municipality1": "West Bengal",
                "municipaltiy_nl1": "",
                "municipality_nl_type1": "State",
                "municipality2": "Nadia",
                "municipaltiy_nl2": "",
                "municipality_nl_type2": "District",
		        "municipality3": "Ranaghat",
        		"municipaltiy_nl3": "",
		        "municipality_nl_type3": "Taluk"
            }
        }

        read as:
            (India, West Bengal State, Nadia District, Ranaghat Taluk)


    - example https://coordinate-info.herokuapp.com/api/v1/coord_info?db=mongo&longitude_x=-95.992775&latitude_y=36.153980

        returns JSON (intersects location in Tulsa, OK)

        {
            "success": 1,
            "response": {
                "country": "United States",
                "municipality1": "Oklahoma",
                "municipaltiy_nl1": "",
                "municipality_nl_type1": "State",
                "municipality2": "Tulsa",
                "municipaltiy_nl2": "",
                "municipality_nl_type2": "County",
		        "municipality3": null,
        		"municipaltiy_nl3": null,
		        "municipality_nl_type3": null
            }
        }

        read as:
            (United States, Oklahoma State, Tulsa County)


    - example https://coordinate-info.herokuapp.com/api/v1/coord_info?longitude_x=116.407396&latitude_y=39.904200

        returns JSON (intersects location in China)

        {
            "success": 1,
            "response": {
                "country": "China",
                "municipality1": "Beijing",
                "municipaltiy_nl1": "北京|北京",
                "municipality_nl_type1": "Zhíxiáshì",
                "municipality2": "Beijing",
                "municipaltiy_nl2": "北京|北京",
                "municipality_nl_type2": "Zhíxiáshì",
		        "municipality3": "Beijing",
        		"municipaltiy_nl3": "北京|北京",
		        "municipality_nl_type3": "Zhíxiáshì"
            }
        }

        read as:
            (China, Beijing Zhíxiáshì)
                        or
            (China, 北京|北京 Zhíxiáshì)

            In that the data repeats itself only the first set of data is relavent.
            Also note dataset error of repeat of 北京 as 北京|北京.  北京 = Beijing


    - example https://coordinate-info.herokuapp.com/api/v1/coord_info?longitude_x=34.299316&latitude_y=43.413029

        returns JSON (intersects location in The Black Sea):
        {
            "success": 1,
            "response": { }
        }


    - example https://coordinate-info.herokuapp.com/api/v1/coord_info?longitude_x=-200&latitude_y=15.552727

        returns JSON (invalid longitude_x):
        {
            "success": 0,
            "response": {
                "msg": "invalid longitude_x and/or latitude_y"
            }
        }

    - example https://coordinate-info.herokuapp.com/api/v1/coord_info?longitude_x=48.516388&latitude_y=15.552727

        returns JSON (intersects location in Yemen): 
        {
            "success": 1,
            "response": {
                "country": "Yemen",
                "municipality1": "Hadramawt",
                "municipaltiy_nl1": "حضرموت",
                "municipality_nl_type1": "Muhafazah",
                "municipality2": "Wadi Al Ayn",
                "municipaltiy_nl2": "وادي العين وحوره",
                "municipality_nl_type2": "Muderiah",
                "municipality3": null,
                "municipaltiy_nl3": null,
                "municipality_nl_type3": null
            }
        }

        read as:
            (Yemen, Hadramawt Muhafazah, Wadi Al Ayn Muderiah) 
                                   or
            (Yemen, حضرموت Muhafazah, وادي العين وحوره Muderiah)


Notes:

    - There are additonal columns in the dataset but I have cut them off after the first two interations of a location.

    - Creating this app has been a weird trip
      
      rails new . --api --skip-turbolinks --skip-puma --database=postgresql (which is what finally worked)

      --skip-active-records ==> if used as an option I never could create a controller 
      Instead of a controller, I tried putting code into an .rb file in lib/.  This would work in
      'development' but once I switched to 'production' then rails couldn't find the lib/file.rb.
      Googled the issue and tried a number of 'solutions'.  I never could resolve this issue.
      Basically, you can't generate a new controller on the command line without active records and a db.

      repo CoordinateInfoAPI was the previous version I worked on that in the end I just had to dump the project.
