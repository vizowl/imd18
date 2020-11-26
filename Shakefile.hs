{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Main where

import Development.Shake
import Development.Shake.FilePath
import Development.Shake.Util ()
import Dhall (auto, input)
import Import
import qualified RIO.Map as Map

main :: IO ()
main = do
  -- Read the config
  (Config bld dbName shpFiles gisFiles _ _) <- input auto "./nzh.dhall"
  let db = bld </> dbName

  -- run shake

  shakeArgs
    shakeOptions
      { shakeFiles = bld,
        shakeThreads = 0
      }
    $ do
      want $
        [bld </> "shp" </> t | t <- Map.keys shpFiles]
          ++ [bld </> "gis" </> f | f <- Map.keys gisFiles]

      phony "clean" $ do
        putInfo "Cleaning files in .build"
        removeFilesAfter ".build" ["//*"]

      "interactive/ping" %> \o -> do
        putNormal o
        command_ [] "touch" ["interactive/ping"]
      db %> \o -> do
        command_ [] "dropdb" ["--if-exists", dbName]
        command_ [] "createdb" [dbName]
        command_ [] "psql" ["-c", "CREATE EXTENSION postgis", dbName]
        command_ [] "touch" [o]
        need [db]

      bld </> "shp.zip/*" %> \o -> do
        let key = takeBaseName o
        case Map.lookup key shpFiles of
          Just (ShpZip src _) -> do
            command_ [] "wget" [src, "-O", o]
          Nothing -> putNormal $ "config problem for " <> o

      bld </> "shp/*" %> \o -> do
        let key = takeBaseName o
            path = bld </> "shp"
            zipf = bld </> "shp.zip" </> key <.> "zip"
        case Map.lookup key shpFiles of
          Just (ShpZip _ fname) -> do
            need [db, zipf]
            command_ [Cwd path] "unzip" ["-o", ".." </> ".." </> zipf]
            command_ [] "psql" ["-c", "DROP TABLE IF EXISTS " <> key]
            (Stdout sout) <- command [Cwd bld] "shp2pgsql" ["-d", "-D", "-s", "2193", "-I", fname, key]
            command_ [StdinBS sout] "psql" [dbName]
            command_ [] "touch" [o]
          Nothing -> putNormal $ "config problem for " <> o

      bld </> "gis/*" %> \o -> do
        need [db]
        let key = takeBaseName o
        case Map.lookup key gisFiles of
          Just fname -> do
            command_ [] "psql" ["-c", "DROP TABLE IF EXISTS " <> key, dbName]
            command_ [] "ogr2ogr" ["-f", "PostgreSQL", "PG:dbname=" <> dbName, "gis" </> fname, "-nln", key]
            command_ [] "touch" [o]
          Nothing -> putNormal $ "config problem for " <> o

-- bld </> "pg/*" %> \o -> do
--   let key = takeBaseName o
--   case Map.lookup key pgFiles of
--     Just src -> do
--       need [src, db]
--       command_ [] "pg_restore" ["-Fc", "-d", dbName, "--if-exists", "-c", src]
--       command_ [] "touch" [o]
--     Nothing -> putNormal $ "config problem for " <> o

-- bld </> "sql/*" %> \o -> do
--   let key = takeBaseName o
--   case Map.lookup key sqlFiles of
--     Just (Sql src deps) -> do
--       need (src : [bld </> d | d <- deps] )
--       command_ [] "psql" ["-f", src, "-d", dbName]
--       command_ [] "touch" [o]
--     Nothing -> putNormal $ "config problem for " <> o