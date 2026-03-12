module Main (main) where

import Test.Tasty

import qualified Test.Chip8.Types
import qualified Test.Chip8.Decode
import qualified Test.Chip8.Memory

main :: IO ()
main = defaultMain $ testGroup "CHIP-8 Emulator Tests"
  [ Test.Chip8.Types.tests
  , Test.Chip8.Decode.tests
  , Test.Chip8.Memory.tests
  ]
