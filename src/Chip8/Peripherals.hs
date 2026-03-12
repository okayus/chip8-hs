-- | ペリフェラルインターフェース定義
-- Display, Keyboard, Audio を抽象化し、テスト時にモック可能にする
module Chip8.Peripherals
  ( Display (..)
  , Keyboard (..)
  , Audio (..)
  , Peripherals (..)
  ) where

import Data.Word (Word8)

-- | ディスプレイインターフェース (64×32 モノクロ)
data Display = Display
  { displayClear    :: IO ()
  , displayGetPixel :: Int -> Int -> IO Bool
  , displaySetPixel :: Int -> Int -> Bool -> IO ()
  , displayRender   :: IO ()
  }

-- | キーボードインターフェース (16キー hex キーパッド)
data Keyboard = Keyboard
  { keyIsPressed    :: Word8 -> IO Bool
  , keyGetPressed   :: IO (Maybe Word8)
  }

-- | オーディオインターフェース
data Audio = Audio
  { audioStartBeep :: IO ()
  , audioStopBeep  :: IO ()
  }

-- | ペリフェラル統合
data Peripherals = Peripherals
  { perDisplay  :: Display
  , perKeyboard :: Keyboard
  , perAudio    :: Audio
  }
