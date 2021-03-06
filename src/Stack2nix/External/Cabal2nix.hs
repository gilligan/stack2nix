module Stack2nix.External.Cabal2nix (
  cabal2nix
  ) where

import           Data.List               (stripPrefix, takeWhile)
import           Data.Maybe              (fromMaybe)
import           Data.Monoid             ((<>))
import           Data.Text               (Text, unpack)
import           Stack2nix.External.Util (runCmd)
import           System.FilePath         ((</>))

-- Requires cabal2nix >= 2.2 in PATH
cabal2nix :: FilePath -> Maybe Text -> Maybe FilePath -> Maybe FilePath -> IO ()
cabal2nix uri commit subpath odir = do
  result <- runCmd exe (args $ fromMaybe "." subpath)
  case result of
    Right stdout ->
      let basename = pname stdout <> ".nix"
          fname = maybe basename (</> basename) odir
      in
      writeFile fname stdout
    Left stderr  -> error stderr
  where
    exe = "cabal2nix"

    args :: FilePath -> [String]
    args dir = concat
      [ maybe [] (\c -> ["--revision", unpack c]) commit
      -- , maybe [] (\d -> ["--subpath", d]) subpath
      , ["--subpath", dir]
      , ["--no-check", "--no-haddock"]          -- TODO: only use on repos that need it.
      , [uri]
      ]

    pname :: String -> String
    pname = pname' . lines

    pname' :: [String] -> String
    pname' [] = error "nix expression generated by cabal2nix is missing the 'pname' attr"
    pname' (x:xs) =
      case stripPrefix "  pname = \"" x of
        Just x' -> takeWhile (/= '"') x'
        Nothing -> pname' xs
