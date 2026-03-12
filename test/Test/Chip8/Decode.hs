module Test.Chip8.Decode (tests) where

import Test.Tasty
import Test.Tasty.HUnit

import Chip8.Decode (decode)
import Chip8.Instruction

tests :: TestTree
tests = testGroup "Decode"
  [ testGroup "System"
    [ testCase "0x0000 → NOP" $
        decode 0x0000 @?= Right NOP
    , testCase "0x00E0 → CLS" $
        decode 0x00E0 @?= Right CLS
    , testCase "0x00EE → RET" $
        decode 0x00EE @?= Right RET
    ]
  , testGroup "Flow"
    [ testCase "0x1234 → JP 0x234" $
        decode 0x1234 @?= Right (JP 0x234)
    , testCase "0x2456 → CALL 0x456" $
        decode 0x2456 @?= Right (CALL 0x456)
    ]
  , testGroup "Conditional"
    [ testCase "0x3A42 → SEByte 0xA 0x42" $
        decode 0x3A42 @?= Right (SEByte 0xA 0x42)
    , testCase "0x4B10 → SNEByte 0xB 0x10" $
        decode 0x4B10 @?= Right (SNEByte 0xB 0x10)
    , testCase "0x5AB0 → SEVy 0xA 0xB" $
        decode 0x5AB0 @?= Right (SEVy 0xA 0xB)
    , testCase "0x9AB0 → SNEVy 0xA 0xB" $
        decode 0x9AB0 @?= Right (SNEVy 0xA 0xB)
    ]
  , testGroup "Load"
    [ testCase "0x6A42 → LDByte 0xA 0x42" $
        decode 0x6A42 @?= Right (LDByte 0xA 0x42)
    , testCase "0x7B10 → ADDByte 0xB 0x10" $
        decode 0x7B10 @?= Right (ADDByte 0xB 0x10)
    , testCase "0xA123 → LDI 0x123" $
        decode 0xA123 @?= Right (LDI 0x123)
    ]
  , testGroup "ALU (0x8XY_)"
    [ testCase "0x8AB0 → LDVy 0xA 0xB" $
        decode 0x8AB0 @?= Right (LDVy 0xA 0xB)
    , testCase "0x8AB1 → OR 0xA 0xB" $
        decode 0x8AB1 @?= Right (OR 0xA 0xB)
    , testCase "0x8AB2 → AND 0xA 0xB" $
        decode 0x8AB2 @?= Right (AND 0xA 0xB)
    , testCase "0x8AB3 → XOR 0xA 0xB" $
        decode 0x8AB3 @?= Right (XOR 0xA 0xB)
    , testCase "0x8AB4 → ADDVy 0xA 0xB" $
        decode 0x8AB4 @?= Right (ADDVy 0xA 0xB)
    , testCase "0x8AB5 → SUB 0xA 0xB" $
        decode 0x8AB5 @?= Right (SUB 0xA 0xB)
    , testCase "0x8A06 → SHR 0xA" $
        decode 0x8A06 @?= Right (SHR 0xA)
    , testCase "0x8AB7 → SUBN 0xA 0xB" $
        decode 0x8AB7 @?= Right (SUBN 0xA 0xB)
    , testCase "0x8A0E → SHL 0xA" $
        decode 0x8A0E @?= Right (SHL 0xA)
    ]
  , testGroup "Jump"
    [ testCase "0xB300 → JPV0 0x300" $
        decode 0xB300 @?= Right (JPV0 0x300)
    ]
  , testGroup "Random"
    [ testCase "0xCA42 → RND 0xA 0x42" $
        decode 0xCA42 @?= Right (RND 0xA 0x42)
    ]
  , testGroup "Display"
    [ testCase "0xDAB5 → DRW 0xA 0xB 0x5" $
        decode 0xDAB5 @?= Right (DRW 0xA 0xB 0x5)
    ]
  , testGroup "Key"
    [ testCase "0xEA9E → SKP 0xA" $
        decode 0xEA9E @?= Right (SKP 0xA)
    , testCase "0xEAA1 → SKNP 0xA" $
        decode 0xEAA1 @?= Right (SKNP 0xA)
    ]
  , testGroup "Timer/Memory (0xFX__)"
    [ testCase "0xFA07 → LDVxDT 0xA" $
        decode 0xFA07 @?= Right (LDVxDT 0xA)
    , testCase "0xFA0A → LDVxK 0xA" $
        decode 0xFA0A @?= Right (LDVxK 0xA)
    , testCase "0xFA15 → LDDTVx 0xA" $
        decode 0xFA15 @?= Right (LDDTVx 0xA)
    , testCase "0xFA18 → LDSTVx 0xA" $
        decode 0xFA18 @?= Right (LDSTVx 0xA)
    , testCase "0xFA1E → ADDIVx 0xA" $
        decode 0xFA1E @?= Right (ADDIVx 0xA)
    , testCase "0xFA29 → LDFVx 0xA" $
        decode 0xFA29 @?= Right (LDFVx 0xA)
    , testCase "0xFA33 → LDBVx 0xA" $
        decode 0xFA33 @?= Right (LDBVx 0xA)
    , testCase "0xFA55 → LDIVx 0xA" $
        decode 0xFA55 @?= Right (LDIVx 0xA)
    , testCase "0xFA65 → LDVxI 0xA" $
        decode 0xFA65 @?= Right (LDVxI 0xA)
    ]
  , testGroup "Invalid"
    [ testCase "0x0001 は不正" $
        case decode 0x0001 of
          Left _  -> pure ()
          Right _ -> assertFailure "Expected Left"
    , testCase "0x5AB1 は不正" $
        case decode 0x5AB1 of
          Left _  -> pure ()
          Right _ -> assertFailure "Expected Left"
    , testCase "0x8ABF は不正" $
        case decode 0x8ABF of
          Left _  -> pure ()
          Right _ -> assertFailure "Expected Left"
    ]
  ]
