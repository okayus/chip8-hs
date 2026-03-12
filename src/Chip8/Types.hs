-- | CHIP-8 ドメイン型定義
-- newtypeで値の取り違えをコンパイル時に防止する
module Chip8.Types
  ( -- * Domain types
    Address (..)
  , Byte (..)
  , Chip8Word16 (..)
  , Nibble (..)
  , RegisterIndex (..)
    -- * Smart constructors
  , mkAddress
  , mkByte
  , mkWord16
  , mkNibble
  , mkRegisterIndex
    -- * CPU state
  , CpuState (..)
  , createInitialCpuState
    -- * Constants
  , programStart
  , memorySize
  , stackSize
  , displayWidth
  , displayHeight
  , numRegisters
  ) where

import Data.Word (Word8, Word16)
import qualified Data.Vector.Unboxed as VU

-- | 12-bit memory address (0x000–0xFFF)
newtype Address = Address { unAddress :: Word16 }
  deriving (Eq, Ord, Show)

-- | 8-bit byte value
newtype Byte = Byte { unByte :: Word8 }
  deriving (Eq, Ord, Show)

-- | 16-bit word (opcode)
newtype Chip8Word16 = Chip8Word16 { unChip8Word16 :: Word16 }
  deriving (Eq, Ord, Show)

-- | 4-bit nibble (0x0–0xF)
newtype Nibble = Nibble { unNibble :: Word8 }
  deriving (Eq, Ord, Show)

-- | Register index (0–15, V0–VF)
newtype RegisterIndex = RegisterIndex { unRegisterIndex :: Word8 }
  deriving (Eq, Ord, Show)

-- | Smart constructor: Address は 0x000–0xFFF の範囲
mkAddress :: Word16 -> Either String Address
mkAddress n
  | n <= 0xFFF = Right (Address n)
  | otherwise  = Left $ "Invalid address: " ++ show n

-- | Smart constructor: Byte は 0x00–0xFF（常に有効）
mkByte :: Word8 -> Byte
mkByte = Byte

-- | Smart constructor: Word16 は 0x0000–0xFFFF（常に有効）
mkWord16 :: Word16 -> Chip8Word16
mkWord16 = Chip8Word16

-- | Smart constructor: Nibble は 0x0–0xF の範囲
mkNibble :: Word8 -> Either String Nibble
mkNibble n
  | n <= 0xF  = Right (Nibble n)
  | otherwise = Left $ "Invalid nibble: " ++ show n

-- | Smart constructor: RegisterIndex は 0–15 の範囲
mkRegisterIndex :: Word8 -> Either String RegisterIndex
mkRegisterIndex n
  | n <= 15   = Right (RegisterIndex n)
  | otherwise = Left $ "Invalid register index: " ++ show n

-- | CPU の全状態
data CpuState = CpuState
  { cpuRegisters   :: !(VU.Vector Word8)    -- ^ V0–VF (16 registers)
  , cpuPc          :: !Word16               -- ^ Program Counter
  , cpuI           :: !Word16               -- ^ Index Register
  , cpuSp          :: !Word8                -- ^ Stack Pointer
  , cpuStack       :: !(VU.Vector Word16)   -- ^ Stack (16 entries)
  , cpuDelayTimer  :: !Word8                -- ^ Delay Timer
  , cpuSoundTimer  :: !Word8                -- ^ Sound Timer
  , cpuWaitingKey   :: !(Maybe Word8)       -- ^ FX0A: waiting for key press (Just vx)
  } deriving (Show, Eq)

-- | CPU 初期状態を生成
createInitialCpuState :: CpuState
createInitialCpuState = CpuState
  { cpuRegisters  = VU.replicate numRegisters 0
  , cpuPc         = programStart
  , cpuI          = 0
  , cpuSp         = 0
  , cpuStack      = VU.replicate stackSize 0
  , cpuDelayTimer = 0
  , cpuSoundTimer = 0
  , cpuWaitingKey  = Nothing
  }

-- | Constants
programStart :: Word16
programStart = 0x200

memorySize :: Int
memorySize = 4096

stackSize :: Int
stackSize = 16

displayWidth :: Int
displayWidth = 64

displayHeight :: Int
displayHeight = 32

numRegisters :: Int
numRegisters = 16
