module Test.Chip8.Memory (tests) where

import Test.Tasty
import Test.Tasty.HUnit
import qualified Data.Vector.Unboxed as VU

import Chip8.Memory
import Chip8.Font (fontData)

tests :: TestTree
tests = testGroup "Memory"
  [ testGroup "newMemory"
    [ testCase "フォントデータが 0x000 から配置されている" $
        let mem = newMemory
        in readByte mem 0x000 @?= (fontData VU.! 0)
    , testCase "フォントデータ末尾 (0x04F) が正しい" $
        let mem = newMemory
        in readByte mem 0x04F @?= (fontData VU.! 79)
    , testCase "0x200 は初期値 0" $
        readByte newMemory 0x200 @?= 0
    ]
  , testGroup "readByte / writeByte"
    [ testCase "書き込んだ値を読み出せる" $
        let mem = writeByte newMemory 0x300 0x42
        in readByte mem 0x300 @?= 0x42
    , testCase "他のアドレスに影響しない" $
        let mem = writeByte newMemory 0x300 0x42
        in readByte mem 0x301 @?= 0
    ]
  , testGroup "readWord"
    [ testCase "ビッグエンディアンで読み出す" $
        let mem = writeByte (writeByte newMemory 0x200 0xAB) 0x201 0xCD
        in readWord mem 0x200 @?= 0xABCD
    ]
  , testGroup "loadRom"
    [ testCase "ROM が 0x200 からロードされる" $
        let rom = VU.fromList [0x12, 0x34, 0x56]
            mem = loadRom newMemory rom
        in do
          readByte mem 0x200 @?= 0x12
          readByte mem 0x201 @?= 0x34
          readByte mem 0x202 @?= 0x56
    , testCase "ROM ロード後もフォントは保持される" $
        let rom = VU.fromList [0xFF]
            mem = loadRom newMemory rom
        in readByte mem 0x000 @?= (fontData VU.! 0)
    ]
  ]
