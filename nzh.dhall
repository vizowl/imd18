let config =
      { db = "imd18"
      , buildDir = ".build"
      , shpZip = toMap
          { imd =
              { url = "https://www.fmhs.auckland.ac.nz/content/dam/uoa/fmhs/soph/epi/hgd/docs/IMD2018.zip",
                file = "IMD2018.shp"
              }
          }
      , pg = toMap { route = "data/routes.pg" }
      , sql = toMap
          { route = { code = "code/routes.sql", deps = [ "pg/route" ] }
          , crash = { code = "code/crash.sql", deps = [ "gis/crash" ] }
          , combine =
            { code = "code/combine.sql", deps = [ "sql/route", "sql/crash" ] }
          }
      }

in  config
