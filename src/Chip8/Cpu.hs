-- | CPU 状態操作ヘルパー
module Chip8.Cpu
  ( getRegister
  , setRegister
  , advancePc
  , skipNext
  , pushStack
  , popStack
  , fetch
  ) where

import Data.Word (Word8, Word16)
import qualified Data.Vector.Unboxed as VU
import qualified Data.Vector.Unboxed.Mutable as VUM

import Chip8.Types (CpuState (..), stackSize)
import Chip8.Memory (Memory, readWord)

-- | レジスタ値を取得
getRegister :: CpuState -> Word8 -> Word8
getRegister cpu vx = cpuRegisters cpu VU.! fromIntegral vx

-- | レジスタ値を設定
setRegister :: CpuState -> Word8 -> Word8 -> CpuState
setRegister cpu vx val = cpu
  { cpuRegisters = VU.modify (\mv ->
      VUM.write mv (fromIntegral vx) val
    ) (cpuRegisters cpu)
  }

-- | PC を 2 バイト進める
advancePc :: CpuState -> CpuState
advancePc cpu = cpu { cpuPc = cpuPc cpu + 2 }

-- | 次の命令をスキップ（PC += 4）
skipNext :: CpuState -> CpuState
skipNext cpu = cpu { cpuPc = cpuPc cpu + 4 }

-- | スタックに push
pushStack :: CpuState -> Word16 -> Either String CpuState
pushStack cpu val
  | fromIntegral (cpuSp cpu) >= stackSize =
      Left "Stack overflow"
  | otherwise = Right cpu
      { cpuStack = VU.modify (\mv ->
          VUM.write mv (fromIntegral (cpuSp cpu)) val
        ) (cpuStack cpu)
      , cpuSp = cpuSp cpu + 1
      }

-- | スタックから pop
popStack :: CpuState -> Either String (CpuState, Word16)
popStack cpu
  | cpuSp cpu == 0 = Left "Stack underflow"
  | otherwise =
      let newSp = cpuSp cpu - 1
          val   = cpuStack cpu VU.! fromIntegral newSp
      in Right (cpu { cpuSp = newSp }, val)

-- | fetch: PC 位置から 16bit オペコードを読み出す
fetch :: CpuState -> Memory -> Word16
fetch cpu mem = readWord mem (cpuPc cpu)
