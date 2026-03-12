-- | CHIP-8 命令セットの代数的データ型
-- 全35命令をADTで表現し、パターンマッチで網羅性を保証する
module Chip8.Instruction
  ( Instruction (..)
  ) where

import Data.Word (Word8, Word16)

-- | CHIP-8 の全35命令を表す代数的データ型
data Instruction
  = NOP                                    -- ^ 0x0000: 何もしない
  | CLS                                    -- ^ 0x00E0: 画面クリア
  | RET                                    -- ^ 0x00EE: サブルーチンから復帰
  | JP      !Word16                        -- ^ 0x1NNN: PC = NNN
  | CALL    !Word16                        -- ^ 0x2NNN: CALL NNN
  | SEByte  !Word8 !Word8                  -- ^ 0x3XNN: SE Vx, byte
  | SNEByte !Word8 !Word8                  -- ^ 0x4XNN: SNE Vx, byte
  | SEVy    !Word8 !Word8                  -- ^ 0x5XY0: SE Vx, Vy
  | LDByte  !Word8 !Word8                  -- ^ 0x6XNN: LD Vx, byte
  | ADDByte !Word8 !Word8                  -- ^ 0x7XNN: ADD Vx, byte
  | LDVy    !Word8 !Word8                  -- ^ 0x8XY0: LD Vx, Vy
  | OR      !Word8 !Word8                  -- ^ 0x8XY1: OR Vx, Vy
  | AND     !Word8 !Word8                  -- ^ 0x8XY2: AND Vx, Vy
  | XOR     !Word8 !Word8                  -- ^ 0x8XY3: XOR Vx, Vy
  | ADDVy   !Word8 !Word8                  -- ^ 0x8XY4: ADD Vx, Vy (carry)
  | SUB     !Word8 !Word8                  -- ^ 0x8XY5: SUB Vx, Vy
  | SHR     !Word8                         -- ^ 0x8XY6: SHR Vx
  | SUBN    !Word8 !Word8                  -- ^ 0x8XY7: SUBN Vx, Vy
  | SHL     !Word8                         -- ^ 0x8XYE: SHL Vx
  | SNEVy   !Word8 !Word8                  -- ^ 0x9XY0: SNE Vx, Vy
  | LDI     !Word16                        -- ^ 0xANNN: LD I, addr
  | JPV0    !Word16                        -- ^ 0xBNNN: JP V0, addr
  | RND     !Word8 !Word8                  -- ^ 0xCXNN: RND Vx, byte
  | DRW     !Word8 !Word8 !Word8           -- ^ 0xDXYN: DRW Vx, Vy, nibble
  | SKP     !Word8                         -- ^ 0xEX9E: SKP Vx
  | SKNP    !Word8                         -- ^ 0xEXA1: SKNP Vx
  | LDVxDT  !Word8                         -- ^ 0xFX07: LD Vx, DT
  | LDVxK   !Word8                         -- ^ 0xFX0A: LD Vx, K (blocking)
  | LDDTVx  !Word8                         -- ^ 0xFX15: LD DT, Vx
  | LDSTVx  !Word8                         -- ^ 0xFX18: LD ST, Vx
  | ADDIVx  !Word8                         -- ^ 0xFX1E: ADD I, Vx
  | LDFVx   !Word8                         -- ^ 0xFX29: LD F, Vx (font)
  | LDBVx   !Word8                         -- ^ 0xFX33: LD B, Vx (BCD)
  | LDIVx   !Word8                         -- ^ 0xFX55: LD [I], Vx (store)
  | LDVxI   !Word8                         -- ^ 0xFX65: LD Vx, [I] (load)
  deriving (Show, Eq)
