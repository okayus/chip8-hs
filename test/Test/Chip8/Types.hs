module Test.Chip8.Types (tests) where

import Test.Tasty
import Test.Tasty.HUnit

import Chip8.Types

tests :: TestTree
tests = testGroup "Types"
  [ testGroup "mkAddress"
    [ testCase "0x000 は有効" $
        mkAddress 0x000 @?= Right (Address 0x000)
    , testCase "0xFFF は有効" $
        mkAddress 0xFFF @?= Right (Address 0xFFF)
    , testCase "0x200 は有効" $
        mkAddress 0x200 @?= Right (Address 0x200)
    , testCase "0x1000 は無効" $
        case mkAddress 0x1000 of
          Left _  -> pure ()
          Right _ -> assertFailure "Expected Left"
    ]
  , testGroup "mkNibble"
    [ testCase "0x0 は有効" $
        mkNibble 0x0 @?= Right (Nibble 0x0)
    , testCase "0xF は有効" $
        mkNibble 0xF @?= Right (Nibble 0xF)
    , testCase "0x10 は無効" $
        case mkNibble 0x10 of
          Left _  -> pure ()
          Right _ -> assertFailure "Expected Left"
    ]
  , testGroup "mkRegisterIndex"
    [ testCase "0 は有効" $
        mkRegisterIndex 0 @?= Right (RegisterIndex 0)
    , testCase "15 は有効" $
        mkRegisterIndex 15 @?= Right (RegisterIndex 15)
    , testCase "16 は無効" $
        case mkRegisterIndex 16 of
          Left _  -> pure ()
          Right _ -> assertFailure "Expected Left"
    ]
  , testGroup "createInitialCpuState"
    [ testCase "PC の初期値は 0x200" $
        cpuPc createInitialCpuState @?= 0x200
    , testCase "SP の初期値は 0" $
        cpuSp createInitialCpuState @?= 0
    , testCase "I の初期値は 0" $
        cpuI createInitialCpuState @?= 0
    , testCase "DT の初期値は 0" $
        cpuDelayTimer createInitialCpuState @?= 0
    , testCase "ST の初期値は 0" $
        cpuSoundTimer createInitialCpuState @?= 0
    ]
  ]
