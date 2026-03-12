-- | エミュレータ統合モジュール
-- fetch → decode → execute ループとタイマー管理
module Chip8.Emulator
  ( EmulatorState (..)
  , newEmulatorState
  , loadProgram
  , tick
  , tickTimers
  ) where

import Data.Word (Word8)
import qualified Data.Vector.Unboxed as VU

import Chip8.Types (CpuState (..), createInitialCpuState)
import Chip8.Memory (Memory, newMemory, loadRom)
import Chip8.Cpu (fetch)
import Chip8.Decode (decode)
import Chip8.Execute (execute, ExecuteResult (..))
import Chip8.Peripherals (Peripherals)

-- | エミュレータの全状態
data EmulatorState = EmulatorState
  { emuCpu    :: !CpuState
  , emuMemory :: !Memory
  } deriving (Show, Eq)

-- | 初期状態のエミュレータを生成
newEmulatorState :: EmulatorState
newEmulatorState = EmulatorState
  { emuCpu    = createInitialCpuState
  , emuMemory = newMemory
  }

-- | ROM プログラムをロード
loadProgram :: EmulatorState -> VU.Vector Word8 -> EmulatorState
loadProgram emu rom = emu { emuMemory = loadRom (emuMemory emu) rom }

-- | 1 CPU サイクル実行 (fetch → decode → execute)
tick :: EmulatorState -> IO (Maybe Peripherals) -> IO (Either String EmulatorState)
tick emu getPeripherals = do
  let cpu = emuCpu emu
      mem = emuMemory emu
  -- キー入力待ち中は命令実行をスキップ
  case cpuWaitingKey cpu of
    Just _vx -> pure $ Right emu
    Nothing -> do
      let opcode = fetch cpu mem
      case decode opcode of
        Left err -> pure $ Left err
        Right instr -> do
          result <- execute instr cpu mem getPeripherals
          pure $ case result of
            Left err -> Left err
            Right (ExecuteResult cpu' mem') ->
              Right emu { emuCpu = cpu', emuMemory = mem' }

-- | タイマー減算（60Hz でフレームごとに 1 回呼ぶ）
tickTimers :: EmulatorState -> EmulatorState
tickTimers emu =
  let cpu = emuCpu emu
      dt  = if cpuDelayTimer cpu > 0 then cpuDelayTimer cpu - 1 else 0
      st  = if cpuSoundTimer cpu > 0 then cpuSoundTimer cpu - 1 else 0
  in emu { emuCpu = cpu { cpuDelayTimer = dt, cpuSoundTimer = st } }
