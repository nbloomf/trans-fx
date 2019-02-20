-- | Module      : Control.FX.Monad.Trans.ExceptT
--   Description : Concrete exception monad transformer
--   Copyright   : 2019, Automattic, Inc.
--   License     : BSD3
--   Maintainer  : Nathan Bloomfield (nbloomf@gmail.com)
--   Stability   : experimental
--   Portability : POSIX

{-# LANGUAGE Rank2Types            #-}
{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE StandaloneDeriving    #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Control.FX.Monad.Trans.ExceptT (
    ExceptT(..)
) where



import Data.Typeable (Typeable)
import Control.Applicative (liftA2)

import Control.FX.EqIn
import Control.FX.Functor
import Control.FX.Monad
import Control.FX.Monad.Trans.Class



-- | Concrete exception monad transformer
newtype ExceptT
  (mark :: * -> *)
  (e :: *)
  (m :: * -> *)
  (a :: *)
    = ExceptT
        { unExceptT :: m (Except mark e a)
        } deriving (Typeable)

instance
  ( EqIn h (m (Except mark e a)), MonadIdentity mark
  ) => EqIn (mark (),h) (ExceptT mark e m a)
  where
    eqIn
      :: (mark (), h)
      -> ExceptT mark e m a
      -> ExceptT mark e m a
      -> Bool
    eqIn (_,h) (ExceptT x) (ExceptT y) =
      eqIn h x y

deriving instance
  ( Show (m (Except k e a))
  ) => Show (ExceptT k e m a)

instance
  ( Monad m, MonadIdentity mark
  ) => Functor (ExceptT mark e m)
  where
    fmap
      :: (a -> b)
      -> ExceptT mark e m a
      -> ExceptT mark e m b
    fmap f = ExceptT . fmap (fmap f) . unExceptT

instance
  ( Monad m, MonadIdentity mark
  ) => Applicative (ExceptT mark e m)
  where
    pure
      :: a
      -> ExceptT mark e m a
    pure = ExceptT . pure . pure

    (<*>)
      :: ExceptT mark e m (a -> b)
      -> ExceptT mark e m a
      -> ExceptT mark e m b
    (ExceptT f) <*> (ExceptT x) =
      ExceptT $ liftA2 (<*>) f x

instance
  ( Monad m, MonadIdentity mark
  ) => Monad (ExceptT mark e m)
  where
    return
      :: a
      -> ExceptT mark e m a
    return = ExceptT . return . Accept

    (>>=)
      :: ExceptT mark e m a
      -> (a -> ExceptT mark e m b)
      -> ExceptT mark e m b
    (ExceptT x) >>= f =
      ExceptT $ do
        a' <- x
        case a' of
          Except e -> return (Except e)
          Accept a -> unExceptT $ f a

instance
  ( Central c, MonadIdentity mark
  ) => Commutant (ExceptT mark e c)
  where
    commute
      :: ( Applicative f )
      => ExceptT mark e c (f a)
      -> f (ExceptT mark e c a)
    commute = fmap ExceptT . commute . fmap commute . unExceptT

instance
  ( Central c, MonadIdentity mark
  ) => Central (ExceptT mark e c)

instance
  ( MonadIdentity mark
  ) => MonadTrans (ExceptT mark e) where
  lift
    :: ( Monad m )
    => m a
    -> ExceptT mark e m a
  lift x = ExceptT (x >>= (return . pure))

instance
  ( MonadIdentity mark
  ) => MonadFunctor (ExceptT mark e) where
  hoist
    :: ( Monad m, Monad n )
    => ( forall u. m u -> n u )
    -> ExceptT mark e m a
    -> ExceptT mark e n a
  hoist f = ExceptT . f . unExceptT

instance
  ( MonadIdentity mark
  ) => RunMonadTrans (mark ()) (ExceptT mark e) (Except mark e)
  where
    runT
      :: mark ()
      -> ExceptT mark e m a
      -> m (Except mark e a)
    runT _ (ExceptT x) = x



{- Effect Instance -}

instance
  ( Monad m, MonadIdentity mark
  ) => MonadExcept mark e (ExceptT mark e m)
  where
    throw
      :: mark e
      -> ExceptT mark e m a
    throw = ExceptT . return . Except . unwrap

    catch
      :: ExceptT mark e m a
      -> (mark e -> ExceptT mark e m a)
      -> ExceptT mark e m a
    catch (ExceptT x) h = ExceptT $ do
      a <- x
      case a of
        Except e -> unExceptT $ h (pure e)
        Accept z -> return (Accept z)



{- Specialized Lifts -}

instance
  ( MonadIdentity mark
  ) => LiftDraft (mark ()) (ExceptT mark e) (Except mark e)
  where
    liftDraft
      :: ( Monad m )
      => Draft w m (Except mark e a)
      -> Draft w (ExceptT mark e m) a
    liftDraft draft =
      ExceptT . fmap commute . draft . unExceptT

instance
  ( MonadIdentity mark
  ) => LiftLocal (mark ()) (ExceptT mark e) (Except mark e)
  where
    liftLocal
      :: ( Monad m )
      => Local r m (Except mark e a)
      -> Local r (ExceptT mark e m) a
    liftLocal local f =
      ExceptT . local f . unExceptT
