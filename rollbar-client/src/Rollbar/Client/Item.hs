{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Rollbar.Client.Item where

import Data.Aeson
import Data.Text

data Item = Item
  { itemData :: Data
  } deriving (Eq, Show)

instance ToJSON Item where
  toJSON Item{..} = object
    [ "data" .= itemData
    ]

data Data = Data
  { dataEnvironment :: Text
  , dataBody :: Body
  -- level
  -- timestamp
  -- code_version
  -- platform
  -- language
  -- framework
  -- context
  -- request
  -- person
  -- server
  -- client
  -- custom
  -- fingerprint
  -- title
  -- uuid
  , dataNotifier :: Maybe Notifier
  } deriving (Eq, Show)

instance ToJSON Data where
  toJSON Data{..} = object
    [ "environment" .= dataEnvironment
    , "body" .= dataBody
    ]

data Body = Body
  { -- telemetry
    bodyPayload :: Payload
  } deriving (Eq, Show)

instance ToJSON Body where
  toJSON Body{..} = object
    [ case bodyPayload of
        (PayloadTrace trace) -> ("trace", toJSON trace)
        (PayloadTraceChain traceChain) -> ("trace_chain", toJSON traceChain)
    ]

data Telemetry = Telemetry
  deriving (Eq, Show)

data Payload
  = PayloadTrace Trace
  | PayloadTraceChain [Trace]
  deriving (Eq, Show)

data Trace = Trace
  { traceFrames :: [Frame]
  , traceException :: Exception
  } deriving (Eq, Show)

instance ToJSON Trace where
  toJSON Trace{..} = object
    [ "frames" .= traceFrames
    , "exception" .= traceException
    ]

data Frame = Frame
  { frameFilename :: Text
  , frameLineno :: Maybe Integer
  , frameColno :: Maybe Integer
  , frameMethod :: Maybe Text
  , frameCode :: Maybe Text
  , frameClassName :: Maybe Text
  , frameContext :: Maybe Context
  -- argspec
  -- varargspec
  -- keywordspec
  -- locals
  } deriving (Eq, Show)

instance ToJSON Frame where
  toJSON Frame{..} = object
    [ "filename" .= frameFilename
    , "lineno" .= frameLineno
    , "colno" .= frameColno
    , "method" .= frameMethod
    , "code" .= frameCode
    , "class_name" .= frameClassName
    , "context" .= frameContext
    ]

data Context = Context
  { contextPre :: [Text]
  , contextPost :: [Text]
  } deriving (Eq, Show)


instance ToJSON Context where
  toJSON Context{..} = object
    [ "pre" .= contextPre
    , "post" .= contextPost
    ]

data Exception = Exception
  { exceptionClass :: Text
  , exceptionMessage :: Maybe Text
  , exceptionDescription :: Maybe Text
  } deriving (Eq, Show)

instance ToJSON Exception where
  toJSON Exception{..} = object
    [ "class" .= exceptionClass
    , "message" .= exceptionMessage
    , "description" .= exceptionDescription
    ]

data Notifier = Notifier
  { notifierName :: Text
  , notifierVersion :: Text
  } deriving (Eq, Show)

newtype ItemId = ItemId Text
  deriving (Eq, Show)

instance FromJSON ItemId where
  parseJSON = withObject "ItemId" $ \o ->
    ItemId <$> o .: "uuid"

mkItem :: Text -> Payload -> Item
mkItem environment payload = Item Data
  { dataEnvironment = environment
  , dataBody = Body
      { bodyPayload = payload
      }
  , dataNotifier = Just Notifier
      { notifierName = "rollbar-client"
      , notifierVersion = "0.1.0.0"
      }
  }

mkPayloadTrace :: [Frame] -> Exception -> Payload
mkPayloadTrace frames exception = PayloadTrace Trace
  { traceFrames = frames
  , traceException = exception
  }

mkException :: Text -> Exception
mkException eclass= Exception
  { exceptionClass = eclass
  , exceptionMessage = Nothing
  , exceptionDescription = Nothing
  }