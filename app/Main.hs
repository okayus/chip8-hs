module Main where

import qualified Data.ByteString as BS
import qualified Data.Vector.Unboxed as VU
import Data.IORef (newIORef, readIORef, writeIORef)
import qualified Data.Vector.Unboxed.Mutable as VUM
import System.Environment (getArgs)
import System.Exit (exitFailure)
import Control.Monad (forM_, when)

import Chip8.Types (CpuState (..), displayWidth, displayHeight)
import Chip8.Emulator (EmulatorState (..), newEmulatorState, loadProgram, tick)
import Chip8.Peripherals (Display (..), Keyboard (..), Audio (..), Peripherals (..))

main :: IO ()
main = do
  args <- getArgs
  case args of
    [romPath] -> runRom romPath
    _ -> do
      putStrLn "Usage: chip8-hs <rom-file>"
      putStrLn "Example: chip8-hs /path/to/MAZE"
      exitFailure

runRom :: FilePath -> IO ()
runRom romPath = do
  -- ROM 読み込み
  romBytes <- BS.readFile romPath
  let rom = VU.fromList (BS.unpack romBytes)

  -- ディスプレイバッファ (64×32 = 2048 pixels)
  displayBuf <- VUM.replicate (displayWidth * displayHeight) False

  -- ペリフェラル構築
  let display = Display
        { displayClear = do
            forM_ [0 .. displayWidth * displayHeight - 1] $ \i ->
              VUM.write displayBuf i False
        , displayGetPixel = \x y ->
            VUM.read displayBuf (y * displayWidth + x)
        , displaySetPixel = \x y val ->
            VUM.write displayBuf (y * displayWidth + x) val
        , displayRender = pure ()
        }

      keyboard = Keyboard
        { keyIsPressed = \_ -> pure False
        , keyGetPressed = pure Nothing
        }

      audio = Audio
        { audioStartBeep = pure ()
        , audioStopBeep = pure ()
        }

      peripherals = Peripherals
        { perDisplay = display
        , perKeyboard = keyboard
        , perAudio = audio
        }

  -- エミュレータ初期化 & ROM ロード
  emuRef <- newIORef (loadProgram newEmulatorState rom)

  putStrLn $ "CHIP-8 Emulator (Haskell) — Loading: " ++ romPath
  putStrLn $ "ROM size: " ++ show (VU.length rom) ++ " bytes"
  putStrLn ""

  -- 500 サイクル実行
  let maxCycles = 3000 :: Int
  errorRef <- newIORef Nothing
  forM_ [1..maxCycles] $ \_ -> do
    err <- readIORef errorRef
    when (err == Nothing) $ do
      emu <- readIORef emuRef
      result <- tick emu (pure (Just peripherals))
      case result of
        Left e -> writeIORef errorRef (Just e)
        Right emu' -> writeIORef emuRef emu'

  -- エラーチェック
  mErr <- readIORef errorRef
  case mErr of
    Just err -> putStrLn $ "Error: " ++ err
    Nothing -> pure ()

  -- ディスプレイ表示
  putStrLn $ "+" ++ replicate displayWidth '-' ++ "+"
  forM_ [0 .. displayHeight - 1] $ \y -> do
    putStr "|"
    forM_ [0 .. displayWidth - 1] $ \x -> do
      pixel <- VUM.read displayBuf (y * displayWidth + x)
      putChar (if pixel then '█' else ' ')
    putStrLn "|"
  putStrLn $ "+" ++ replicate displayWidth '-' ++ "+"

  -- CPU 状態表示
  emu <- readIORef emuRef
  let cpu = emuCpu emu
  putStrLn ""
  putStrLn $ "PC: 0x" ++ showHex16 (cpuPc cpu)
       ++ "  I: 0x" ++ showHex16 (cpuI cpu)
       ++ "  SP: " ++ show (cpuSp cpu)

showHex16 :: (Integral a) => a -> String
showHex16 n =
  let h = fromIntegral n :: Int
      toHex i
        | i < 10    = toEnum (i + fromEnum '0')
        | otherwise  = toEnum (i - 10 + fromEnum 'A')
  in [toHex ((h `div` 4096) `mod` 16)
     , toHex ((h `div` 256) `mod` 16)
     , toHex ((h `div` 16) `mod` 16)
     , toHex (h `mod` 16)]
