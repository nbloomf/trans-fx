-- | Module      : Control.FX.Functor.LeftZero
--   Description : Left zero semigroup with identity on a type
--   Copyright   : 2019, Automattic, Inc.
--   License     : BSD3
--   Maintainer  : Nathan Bloomfield (nbloomf@gmail.com)
--   Stability   : experimental
--   Portability : POSIX

{-# LANGUAGE TypeFamilies   #-}
{-# LANGUAGE InstanceSigs   #-}
{-# LANGUAGE KindSignatures #-}

module Control.FX.Functor.LeftZero (
    LeftZero(..)
  , Context(..)
) where



import Data.Typeable (Typeable)

import Control.FX.EqIn
import Control.FX.Functor.Class



-- | Type representing the left zero semigroup on @a@ with
-- an identity attached. As a functor @LeftZero@ is isomorphic
-- to @Maybe@.
data LeftZero
  (a :: *)
    = LeftZero a | LeftUnit
    deriving (Eq, Show, Typeable)



instance
  IsMaybe LeftZero
  where
    fromMaybe
      :: Maybe a
      -> LeftZero a
    fromMaybe x = case x of
      Nothing -> LeftUnit
      Just a  -> LeftZero a

    toMaybe
      :: LeftZero a
      -> Maybe a
    toMaybe x = case x of
      LeftUnit   -> Nothing
      LeftZero a -> Just a



instance Functor LeftZero where
  fmap
    :: (a -> b)
    -> LeftZero a
    -> LeftZero b
  fmap f x = case x of
    LeftZero a -> LeftZero (f a)
    LeftUnit   -> LeftUnit

instance Applicative LeftZero where
  pure
    :: a
    -> LeftZero a
  pure = LeftZero

  (<*>)
    :: LeftZero (a -> b)
    -> LeftZero a
    -> LeftZero b
  f' <*> x' =
    case f' of
      LeftUnit   -> LeftUnit
      LeftZero f -> case x' of
        LeftUnit   -> LeftUnit
        LeftZero x -> LeftZero (f x)

instance Semigroup (LeftZero a) where
  (<>)
    :: LeftZero a
    -> LeftZero a
    -> LeftZero a
  x <> y =
    case x of
      LeftUnit -> y
      _ -> x

instance Monoid (LeftZero a) where
  mempty
    :: LeftZero a
  mempty = LeftUnit

  mappend
    :: LeftZero a
    -> LeftZero a
    -> LeftZero a
  mappend = (<>)

instance Commutant LeftZero where
  commute
    :: ( Applicative f )
    => LeftZero (f a) -> f (LeftZero a)
  commute x =
    case x of
      LeftUnit   -> pure LeftUnit
      LeftZero x -> LeftZero <$> x

instance
  EqIn LeftZero
  where
    newtype Context LeftZero
      = LeftZeroCtx
          { unLeftZeroCtx :: ()
          } deriving (Eq, Show)

    eqIn
      :: (Eq a)
      => Context LeftZero
      -> LeftZero a
      -> LeftZero a
      -> Bool
    eqIn _ = (==)
