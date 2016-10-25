{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import qualified "glualint-lib" GLuaFixer.LintSettings as Settings
import qualified "glualint-lib" GLuaFixer.AG.ASTLint as Lint
import           "glualint-lib" GLuaFixer.LintMessage (LintMessage (..), sortLintMessages)
import qualified "glualint-lib" GLuaFixer.Util as Util
import           "reflex-dom"   Reflex.Dom
import qualified "containers"   Data.Map as M
import           "base"         Data.List (intersperse)
import           "base"         Control.Monad (void)


data LintStatus =
    Good -- Good code, no problems!
  | Warnings [LintMessage] -- Shit compiles, but you should worry about some things
  | SyntaxErrors [LintMessage] -- Syntax errors!


type WWidget w = forall t m . (MonadWidget t m) => m (w t)

lintString :: String -> LintStatus
lintString str = do
  let defConfig = Settings.defaultLintSettings

  let parsed = Util.parseFile defConfig "input" str

  case parsed of
    Right ([], ast) -> case Lint.astWarnings defConfig ast of
      [] -> Good
      xs -> Warnings $ map ($"input") xs
    Right (warnings, _) -> Warnings warnings
    Left errs -> SyntaxErrors errs

prettyPrintMessages :: [LintMessage] -> [String]
prettyPrintMessages = intersperse "\n" . map show . sortLintMessages

displayMessage :: LintStatus -> [String]
displayMessage Good = []
displayMessage (Warnings msgs) = prettyPrintMessages msgs
displayMessage (SyntaxErrors msgs) = prettyPrintMessages msgs


main :: IO ()
main = mainWidget $ do
  rec
      lintStatus <- mapDyn lintString $ _textArea_value t
      lintResults <- mapDyn displayMessage lintStatus

      statusMessage lintStatus
      lintResultList lintResults

      t <- txtLuaInput

      return ()

  return ()

-- | Status message
statusMessage :: (MonadWidget t m) => Dynamic t LintStatus -> m ()
statusMessage lintStatus =
  let
    status :: LintStatus -> String
    status Good = "Your script is all good!"
    status (Warnings _) = "Your script will not throw syntax errors, but there are some warnings!"
    status (SyntaxErrors _) = "Your script is broken! Check out these errors!"
  in do
    txt <- mapDyn status lintStatus

    el "p" $ dynText txt

-- | Displays a list paragraphs with warnings and/or errors
lintResultList :: (MonadWidget t m) => Dynamic t [String] -> m ()
lintResultList lintResults = void $ el "div" $ simpleList lintResults (el "p" . dynText)

-- | Where you input your Lua
txtLuaInput :: WWidget TextArea
txtLuaInput =
  elAttr "div" (M.fromList [("style", "width: 100%; min-height: 500pt")]) $ textArea $
    def
    & textAreaConfig_initialValue .~ "-- Put your Lua here\n"
    & textAreaConfig_attributes .~ (constDyn $ "style" =: "width: 100%; min-height: 500pt")