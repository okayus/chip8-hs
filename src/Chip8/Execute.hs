-- | 命令実行エンジン
-- デコード済み Instruction を CPU 状態に適用する
module Chip8.Execute
  ( execute
  , ExecuteResult (..)
  ) where

import Data.Word (Word8, Word16)
import Data.Bits (shiftL, shiftR, (.&.), (.|.), xor)
import Data.IORef (newIORef, readIORef, writeIORef)
import Control.Monad (forM_, when)
import System.Random (randomIO)

import Chip8.Instruction
import Chip8.Types (CpuState (..), displayWidth, displayHeight)
import Chip8.Cpu
import Chip8.Memory (Memory, readByte, writeByte)
import Chip8.Peripherals (Peripherals (..), Display (..), Keyboard (..))

-- | 命令実行結果
data ExecuteResult = ExecuteResult
  { erCpu    :: !CpuState
  , erMemory :: !Memory
  } deriving (Show, Eq)

-- | 命令を実行し、更新された CPU 状態とメモリを返す
-- IO が必要な命令（DRW, SKP, SKNP, LDVxK, RND）用に Maybe Peripherals を受け取る
execute :: Instruction -> CpuState -> Memory -> IO (Maybe Peripherals) -> IO (Either String ExecuteResult)
execute instr cpu mem getPeripherals = case instr of
  NOP -> pure $ Right $ result (advancePc cpu) mem

  CLS -> do
    mper <- getPeripherals
    case mper of
      Nothing -> pure $ Right $ result (advancePc cpu) mem
      Just per -> do
        displayClear (perDisplay per)
        pure $ Right $ result (advancePc cpu) mem

  RET -> pure $ case popStack cpu of
    Left err -> Left err
    Right (cpu', addr) -> Right $ result (cpu' { cpuPc = addr }) mem

  JP addr -> pure $ Right $ result (cpu { cpuPc = addr }) mem

  CALL addr -> pure $ case pushStack cpu (cpuPc cpu + 2) of
    Left err -> Left err
    Right cpu' -> Right $ result (cpu' { cpuPc = addr }) mem

  SEByte vx byte ->
    let val = getRegister cpu vx
    in pure $ Right $ result (if val == byte then skipNext cpu else advancePc cpu) mem

  SNEByte vx byte ->
    let val = getRegister cpu vx
    in pure $ Right $ result (if val /= byte then skipNext cpu else advancePc cpu) mem

  SEVy vx vy ->
    let valX = getRegister cpu vx
        valY = getRegister cpu vy
    in pure $ Right $ result (if valX == valY then skipNext cpu else advancePc cpu) mem

  LDByte vx byte -> pure $ Right $ result (advancePc $ setRegister cpu vx byte) mem

  ADDByte vx byte ->
    let val = getRegister cpu vx
        res = val + byte
    in pure $ Right $ result (advancePc $ setRegister cpu vx res) mem

  LDVy vx vy -> pure $ Right $ result (advancePc $ setRegister cpu vx (getRegister cpu vy)) mem

  OR vx vy ->
    let res = getRegister cpu vx .|. getRegister cpu vy
        cpu' = setRegister (setRegister cpu vx res) 0xF 0
    in pure $ Right $ result (advancePc cpu') mem

  AND vx vy ->
    let res = getRegister cpu vx .&. getRegister cpu vy
        cpu' = setRegister (setRegister cpu vx res) 0xF 0
    in pure $ Right $ result (advancePc cpu') mem

  XOR vx vy ->
    let res = getRegister cpu vx `xor` getRegister cpu vy
        cpu' = setRegister (setRegister cpu vx res) 0xF 0
    in pure $ Right $ result (advancePc cpu') mem

  ADDVy vx vy ->
    let valX = fromIntegral (getRegister cpu vx) :: Word16
        valY = fromIntegral (getRegister cpu vy) :: Word16
        sum' = valX + valY
        carry = if sum' > 0xFF then 1 else 0
        cpu' = setRegister (setRegister cpu vx (fromIntegral (sum' .&. 0xFF))) 0xF carry
    in pure $ Right $ result (advancePc cpu') mem

  SUB vx vy ->
    let valX = getRegister cpu vx
        valY = getRegister cpu vy
        notBorrow = if valX >= valY then 1 else 0
        cpu' = setRegister (setRegister cpu vx (valX - valY)) 0xF notBorrow
    in pure $ Right $ result (advancePc cpu') mem

  SHR vx ->
    let val = getRegister cpu vx
        lsb = val .&. 1
        cpu' = setRegister (setRegister cpu vx (val `shiftR` 1)) 0xF lsb
    in pure $ Right $ result (advancePc cpu') mem

  SUBN vx vy ->
    let valX = getRegister cpu vx
        valY = getRegister cpu vy
        notBorrow = if valY >= valX then 1 else 0
        cpu' = setRegister (setRegister cpu vx (valY - valX)) 0xF notBorrow
    in pure $ Right $ result (advancePc cpu') mem

  SHL vx ->
    let val = getRegister cpu vx
        msb = (val `shiftR` 7) .&. 1
        cpu' = setRegister (setRegister cpu vx (val `shiftL` 1)) 0xF msb
    in pure $ Right $ result (advancePc cpu') mem

  SNEVy vx vy ->
    let valX = getRegister cpu vx
        valY = getRegister cpu vy
    in pure $ Right $ result (if valX /= valY then skipNext cpu else advancePc cpu) mem

  LDI addr -> pure $ Right $ result (advancePc cpu { cpuI = addr }) mem

  JPV0 addr ->
    let v0 = fromIntegral (getRegister cpu 0) :: Word16
    in pure $ Right $ result (cpu { cpuPc = addr + v0 }) mem

  RND vx mask -> do
    randByte <- randomIO :: IO Word8
    let val = randByte .&. mask
        cpu' = setRegister cpu vx val
    pure $ Right $ result (advancePc cpu') mem

  DRW vx vy n -> do
    mper <- getPeripherals
    case mper of
      Nothing -> pure $ Right $ result (advancePc cpu) mem
      Just per -> do
        let xPos = fromIntegral (getRegister cpu vx) `mod` displayWidth
            yPos = fromIntegral (getRegister cpu vy) `mod` displayHeight
            spriteI = cpuI cpu
        collision <- drawSprite per mem spriteI xPos yPos (fromIntegral n)
        let vf = if collision then 1 else 0
            cpu' = setRegister cpu 0xF vf
        pure $ Right $ result (advancePc cpu') mem

  SKP vx -> do
    mper <- getPeripherals
    case mper of
      Nothing -> pure $ Right $ result (advancePc cpu) mem
      Just per -> do
        pressed <- keyIsPressed (perKeyboard per) (getRegister cpu vx)
        pure $ Right $ result (if pressed then skipNext cpu else advancePc cpu) mem

  SKNP vx -> do
    mper <- getPeripherals
    case mper of
      Nothing -> pure $ Right $ result (advancePc cpu) mem
      Just per -> do
        pressed <- keyIsPressed (perKeyboard per) (getRegister cpu vx)
        pure $ Right $ result (if not pressed then skipNext cpu else advancePc cpu) mem

  LDVxDT vx -> pure $ Right $ result (advancePc $ setRegister cpu vx (cpuDelayTimer cpu)) mem

  LDVxK vx -> pure $ Right $ result (cpu { cpuWaitingKey = Just vx }) mem

  LDDTVx vx -> pure $ Right $ result (advancePc cpu { cpuDelayTimer = getRegister cpu vx }) mem

  LDSTVx vx -> pure $ Right $ result (advancePc cpu { cpuSoundTimer = getRegister cpu vx }) mem

  ADDIVx vx ->
    let val = fromIntegral (getRegister cpu vx) :: Word16
    in pure $ Right $ result (advancePc cpu { cpuI = cpuI cpu + val }) mem

  LDFVx vx ->
    let digit = fromIntegral (getRegister cpu vx) :: Word16
    in pure $ Right $ result (advancePc cpu { cpuI = digit * 5 }) mem

  LDBVx vx ->
    let val = getRegister cpu vx
        hundreds = val `div` 100
        tens     = (val `div` 10) `mod` 10
        ones     = val `mod` 10
        i        = cpuI cpu
        mem' = writeByte (writeByte (writeByte mem i hundreds) (i+1) tens) (i+2) ones
    in pure $ Right $ result (advancePc cpu) mem'

  LDIVx vx ->
    let i = cpuI cpu
        mem' = foldr (\reg m -> writeByte m (i + fromIntegral reg) (getRegister cpu reg))
                     mem [0..vx]
    in pure $ Right $ result (advancePc cpu) mem'

  LDVxI vx ->
    let i = cpuI cpu
        cpu' = foldr (\reg c -> setRegister c reg (readByte mem (i + fromIntegral reg)))
                     cpu [0..vx]
    in pure $ Right $ result (advancePc cpu') mem

  where
    result c m = ExecuteResult c m

-- | スプライト描画（XOR方式）
drawSprite :: Peripherals -> Memory -> Word16 -> Int -> Int -> Int -> IO Bool
drawSprite per mem spriteAddr xPos yPos height = do
  let disp = perDisplay per
  collisionRef <- newIORef False
  forM_ [0..height-1] $ \row -> do
    let y = (yPos + row) `mod` displayHeight
    let spriteByte = readByte mem (spriteAddr + fromIntegral row)
    forM_ [0..7] $ \col -> do
      let x = (xPos + col) `mod` displayWidth
      let bit = (spriteByte `shiftR` (7 - col)) .&. 1
      when (bit == 1) $ do
        old <- displayGetPixel disp x y
        when old $ writeIORef collisionRef True
        displaySetPixel disp x y (not old)
  readIORef collisionRef
