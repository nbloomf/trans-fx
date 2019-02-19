{-#
  LANGUAGE
    Rank2Types,
    KindSignatures,
    FlexibleInstances,
    QuantifiedConstraints,
    MultiParamTypeClasses,
    FunctionalDependencies
#-}

module Control.FX.Monad.Trans.Trans.Class (
    MonadTransTrans(..)
  , MonadTransFunctor(..)
  , RunMonadTransTrans(..)
  , Unit(..), Dub(..), Sing(..)
) where



import Data.Typeable (Typeable)

import Control.FX.Functor
import Control.FX.Monad
import Control.FX.Monad.Trans



class
  ( forall t. (MonadTrans t) => MonadTrans (u t)
  , forall t m. (Monad m, MonadTrans t) => Monad (u t m)
  ) => MonadTransTrans
    (u :: ((* -> *) -> (* -> *)) -> (* -> *) -> * -> *)
  where
    liftT
      :: (Monad m, MonadTrans t)
      => t m a -> u t m a

instance MonadTransTrans ApplyT where
  liftT = ApplyT

class
  ( MonadTransTrans u
  , forall t. (MonadFunctor t) => MonadFunctor (u t)
  ) => MonadTransFunctor u
  where
    hoistT
      :: (Monad m, MonadFunctor t1, MonadFunctor t2)
      => (forall n w. (Monad n) => t1 n w -> t2 n w) -> u t1 m a -> u t2 m a

    raiseT
      :: (Monad m1, Monad m2, MonadFunctor t)
      => (forall w. m1 w -> m2 w) -> u t m1 a -> u t m2 a

instance MonadTransFunctor ApplyT where
  hoistT f = ApplyT . f . unApplyT
  raiseT f = ApplyT . hoist f . unApplyT

class
  ( MonadTransTrans u, Commutant f
  ) => RunMonadTransTrans z u f | u -> z f
  where
    runTT
      :: (Monad m, MonadTrans t)
      => z m -> u t m a -> t m (f a)



data Unit (a :: * -> *)
  = Unit
  deriving (Eq, Show, Typeable)

data Dub
  (z1 :: (* -> *) -> *)
  (z2 :: (* -> *) -> *)
  (m :: * -> *)
    = Dub (z1 m) (z2 m)

data Sing
  (z :: (* -> *) -> *)
  (y :: *)
  (m :: * -> *)
    = Sing (z m) y
