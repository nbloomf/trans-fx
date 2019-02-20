-- | Module      : Control.FX.Functor.Pair
--   Description : Pair type
--   Copyright   : 2019, Automattic, Inc.
--   License     : BSD3
--   Maintainer  : Nathan Bloomfield (nbloomf@gmail.com)
--   Stability   : experimental
--   Portability : POSIX

{-# LANGUAGE InstanceSigs   #-}
{-# LANGUAGE KindSignatures #-}

module Control.FX.Functor.Pair (
    Pair(..)
) where



import Data.Typeable (Typeable)

import Control.FX.Functor.Class



-- | Tuple type, isomorphic to @(a,b)@. This is here so we can
-- have a partially applied tuple type @Pair a@ without syntax hacks.
data Pair
  (a :: *)
  (b :: *)
    = Pair
       { slot1 :: a, slot2 :: b
       } deriving (Eq, Show, Typeable)

instance
  Functor (Pair c)
  where
    fmap
      :: (a -> b)
      -> Pair c a
      -> Pair c b
    fmap f (Pair c a) = Pair c (f a)

instance
  Commutant (Pair c)
  where
    commute
      :: ( Applicative f )
      => Pair c (f a)
      -> f (Pair c a)
    commute (Pair c x) = fmap (Pair c) x

instance
  Bifunctor Pair
  where
    bimap1
      :: (a -> c)
      -> Pair a b
      -> Pair c b
    bimap1 f (Pair a b) = Pair (f a) b

    bimap2
      :: (b -> c)
      -> Pair a b
      -> Pair a c
    bimap2 f (Pair a b) = Pair a (f b)
