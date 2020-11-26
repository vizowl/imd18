{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Types where

import Dhall
import Dhall.Deriving
import RIO
import RIO.Process

data Cmd
  = NoOp

-- | Command line arguments
data Options = Options
  { optionsVerbose :: Bool,
    optionsCmd :: !Cmd
  }

data ShpZip = ShpZip
  { shpZipUrl :: String,
    shpZipFile :: String
  }
  deriving (Generic, Show)
  deriving (FromDhall) via Codec (Field (CamelCase <<< DropPrefix "shpZip")) ShpZip

data Sql = Sql
  { sqlCode :: String,
    sqlDeps :: [String]
  }
  deriving (Generic, Show)
  deriving (FromDhall) via Codec (Field (CamelCase <<< DropPrefix "sql")) Sql

data Config = Config
  { configBuildDir :: FilePath,
    configDb :: String,
    configShpZip :: Map String ShpZip,
    configPg :: Map String FilePath,
    configSql :: Map String Sql
  }
  deriving (Generic, Show)
  deriving (FromDhall) via Codec (Field (CamelCase <<< DropPrefix "config")) Config

data App = App
  { appLogFunc :: !LogFunc,
    appProcessContext :: !ProcessContext,
    appOptions :: !Options,
    appConfig :: !Config
    -- Add other app-specific configuration information here
  }

instance HasLogFunc App where
  logFuncL = lens appLogFunc (\x y -> x {appLogFunc = y})

instance HasProcessContext App where
  processContextL = lens appProcessContext (\x y -> x {appProcessContext = y})
