{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Main (main) where

import Import
import Options.Generic
import RIO.Process
import Run
import Dhall

modifiers :: Modifiers
modifiers = defaultModifiers
    { shortNameModifier = firstLetter
    }

data Args w = Args
  { verbose :: w ::: Bool <?> "Run in verbose mode"
  }
  deriving (Generic)

instance ParseRecord (Args Wrapped ) where
    parseRecord = parseRecordWithModifiers modifiers

deriving instance Show (Args Unwrapped)

main :: IO ()
main = do
  (Args v) <- unwrapRecord "NZH program"
  lo <- logOptionsHandle stderr v
  pc <- mkDefaultProcessContext
  conf <- input auto "./nzh.dhall"
  withLogFunc lo $ \lf ->
    let app =
          App
            { appLogFunc = lf,
              appProcessContext = pc,
              appOptions = Options v NoOp,
              appConfig = conf
            }
     in runRIO app run
