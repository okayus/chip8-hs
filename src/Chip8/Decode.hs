-- | オペコードデコーダ: Word16 → Instruction の純粋変換
module Chip8.Decode
  ( decode
  ) where

import Data.Word (Word8, Word16)
import Data.Bits (shiftR, (.&.))

import Chip8.Instruction

-- | 16bit オペコードを Instruction にデコード
decode :: Word16 -> Either String Instruction
decode opcode = case highNibble of
  0x0 -> case opcode of
    0x0000 -> Right NOP
    0x00E0 -> Right CLS
    0x00EE -> Right RET
    _      -> Left $ "Unknown opcode: " ++ showHex opcode
  0x1 -> Right $ JP nnn
  0x2 -> Right $ CALL nnn
  0x3 -> Right $ SEByte x nn
  0x4 -> Right $ SNEByte x nn
  0x5 -> case lowNibble of
    0x0 -> Right $ SEVy x y
    _   -> Left $ "Unknown opcode: " ++ showHex opcode
  0x6 -> Right $ LDByte x nn
  0x7 -> Right $ ADDByte x nn
  0x8 -> case lowNibble of
    0x0 -> Right $ LDVy x y
    0x1 -> Right $ OR x y
    0x2 -> Right $ AND x y
    0x3 -> Right $ XOR x y
    0x4 -> Right $ ADDVy x y
    0x5 -> Right $ SUB x y
    0x6 -> Right $ SHR x
    0x7 -> Right $ SUBN x y
    0xE -> Right $ SHL x
    _   -> Left $ "Unknown opcode: " ++ showHex opcode
  0x9 -> case lowNibble of
    0x0 -> Right $ SNEVy x y
    _   -> Left $ "Unknown opcode: " ++ showHex opcode
  0xA -> Right $ LDI nnn
  0xB -> Right $ JPV0 nnn
  0xC -> Right $ RND x nn
  0xD -> Right $ DRW x y n
  0xE -> case (nn) of
    0x9E -> Right $ SKP x
    0xA1 -> Right $ SKNP x
    _    -> Left $ "Unknown opcode: " ++ showHex opcode
  0xF -> case nn of
    0x07 -> Right $ LDVxDT x
    0x0A -> Right $ LDVxK x
    0x15 -> Right $ LDDTVx x
    0x18 -> Right $ LDSTVx x
    0x1E -> Right $ ADDIVx x
    0x29 -> Right $ LDFVx x
    0x33 -> Right $ LDBVx x
    0x55 -> Right $ LDIVx x
    0x65 -> Right $ LDVxI x
    _    -> Left $ "Unknown opcode: " ++ showHex opcode
  _ -> Left $ "Unknown opcode: " ++ showHex opcode
  where
    highNibble = fromIntegral (opcode `shiftR` 12) :: Word8
    lowNibble  = fromIntegral (opcode .&. 0x000F) :: Word8
    x          = fromIntegral ((opcode `shiftR` 8) .&. 0x0F) :: Word8
    y          = fromIntegral ((opcode `shiftR` 4) .&. 0x0F) :: Word8
    nn         = fromIntegral (opcode .&. 0x00FF) :: Word8
    n          = fromIntegral (opcode .&. 0x000F) :: Word8
    nnn        = opcode .&. 0x0FFF

showHex :: Word16 -> String
showHex w = "0x" ++ map toHexChar [fromIntegral (w `shiftR` 12) .&. 0xF
                                   , fromIntegral (w `shiftR` 8) .&. 0xF
                                   , fromIntegral (w `shiftR` 4) .&. 0xF
                                   , fromIntegral w .&. 0xF]
  where
    toHexChar :: Word16 -> Char
    toHexChar i
      | i < 10    = toEnum (fromIntegral i + fromEnum '0')
      | otherwise = toEnum (fromIntegral i - 10 + fromEnum 'A')
