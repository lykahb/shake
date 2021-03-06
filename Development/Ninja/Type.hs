{-# LANGUAGE RecordWildCards, PatternGuards #-}

-- | The IO in this module is only to evaluate an envrionment variable,
--   the 'Env' itself it passed around purely.
module Development.Ninja.Type(
    Str, FileStr,
    Expr(..), Env, newEnv, askVar, askExpr, addEnv, addBind, addBinds,
    Ninja(..), newNinja, Build(..), Rule(..),
    ) where

import Development.Ninja.Env
import qualified Data.ByteString.Char8 as BS
import Data.Maybe


type Str = BS.ByteString
type FileStr = Str


---------------------------------------------------------------------
-- EXPRESSIONS AND BINDINGS

data Expr = Exprs [Expr] | Lit Str | Var Str deriving (Show,Eq)

askExpr :: Env Str Str -> Expr -> IO Str
askExpr e = f
    where f (Exprs xs) = fmap BS.concat $ mapM f xs
          f (Lit x) = return x
          f (Var x) = askVar e x

askVar :: Env Str Str -> Str -> IO Str
askVar e x = fmap (fromMaybe BS.empty) $ askEnv e x

addBind :: Env Str Str -> Str -> Expr -> IO ()
addBind e k v = addEnv e k =<< askExpr e v

addBinds :: Env Str Str -> [(Str, Expr)] -> IO ()
addBinds e = mapM_ (uncurry $ addBind e)


---------------------------------------------------------------------
-- STRUCTURE

data Ninja = Ninja
    {rules :: [(Str,Rule)]
    ,singles :: [(FileStr,Build)]
    ,multiples :: [([FileStr], Build)]
    ,phonys :: ([(Str, [FileStr])])
    ,defaults :: [FileStr]
    ,pools :: [(Str, Int)]
    }
    deriving Show

newNinja :: Ninja
newNinja = Ninja [] [] [] [] [] []

data Build = Build
    {ruleName :: Str
    ,env :: Env Str Str
    ,depsNormal :: [FileStr]
    ,depsImplicit :: [FileStr]
    ,depsOrderOnly :: [FileStr]
    ,buildBind :: [(Str,Expr)]
    } deriving Show

data Rule = Rule
    {ruleBind :: [(Str,Expr)]
    } deriving Show
