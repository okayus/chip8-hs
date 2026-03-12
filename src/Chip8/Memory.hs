-- | CHIP-8 メモリ管理 (4KB RAM)
module Chip8.Memory
  ( Memory
  , newMemory
  , readByte
  , writeByte
  , readWord
  , loadRom
  , loadFont
  ) where

import Data.Word (Word8, Word16)
import qualified Data.Vector.Unboxed as VU
import qualified Data.Vector.Unboxed.Mutable as VUM
import Data.Bits (shiftL, (.|.))

import Chip8.Types (memorySize, programStart)
import Chip8.Font (fontData, fontStartAddress)

-- | 4KB メモリ（不変ベクタ）
newtype Memory = Memory { unMemory :: VU.Vector Word8 }
  deriving (Show, Eq)

-- | フォント初期配置済みメモリを生成
newMemory :: Memory
newMemory = Memory $ VU.modify (\mv -> do
    -- フォントデータを 0x000 から配置
    VU.imapM_ (\i b -> VUM.write mv (fromIntegral fontStartAddress + i) b) fontData
  ) (VU.replicate memorySize 0)

-- | 1バイト読み出し
readByte :: Memory -> Word16 -> Word8
readByte (Memory mem) addr = mem VU.! fromIntegral addr

-- | 1バイト書き込み
writeByte :: Memory -> Word16 -> Word8 -> Memory
writeByte (Memory mem) addr val = Memory $ VU.modify (\mv ->
    VUM.write mv (fromIntegral addr) val
  ) mem

-- | 16bit ワード読み出し（ビッグエンディアン）
readWord :: Memory -> Word16 -> Word16
readWord mem addr =
  let hi = fromIntegral (readByte mem addr) :: Word16
      lo = fromIntegral (readByte mem (addr + 1)) :: Word16
  in (hi `shiftL` 8) .|. lo

-- | ROM データを 0x200 からロード
loadRom :: Memory -> VU.Vector Word8 -> Memory
loadRom (Memory mem) rom = Memory $ VU.modify (\mv ->
    VU.imapM_ (\i b -> VUM.write mv (fromIntegral programStart + i) b) rom
  ) mem

-- | フォントデータをロード（newMemory で既に呼ばれるが、明示的にも使える）
loadFont :: Memory -> Memory
loadFont (Memory mem) = Memory $ VU.modify (\mv ->
    VU.imapM_ (\i b -> VUM.write mv (fromIntegral fontStartAddress + i) b) fontData
  ) mem
