# CHIP-8 Emulator (Haskell)

Haskell で実装した CHIP-8 エミュレータ。newtype と代数的データ型による型安全な設計。

## 特徴

- **型安全**: newtype (`Address`, `Byte`, `Nibble`, `RegisterIndex`) で値の取り違えをコンパイル時に防止
- **代数的データ型**: 全 35 命令を ADT で表現し、GHC の網羅性チェックで漏れを検出
- **純粋関数**: `decode` は副作用のない純粋変換、CPU 状態操作も純粋なレコード更新
- **テスト**: tasty による構造化テスト (61 テスト)

## 必要環境

- GHC 9.6+
- Cabal 3.12+

## コマンド

```bash
cabal build       # ビルド
cabal test        # テスト実行
cabal run         # 実行
```

## アーキテクチャ

```
src/Chip8/
  Types.hs         # ドメイン型: Address, Byte, CpuState 等
  Instruction.hs   # 命令 ADT (全35命令の sum type)
  Font.hs          # 組み込みフォントスプライト (0-F)
  Decode.hs        # デコーダ: Word16 → Instruction
  Memory.hs        # 4KB RAM (Unboxed Vector)
  Cpu.hs           # CPU 状態操作 (fetch, register read/write, stack)
  Execute.hs       # 命令実行エンジン
  Emulator.hs      # fetch-decode-execute 統合ループ
  Peripherals.hs   # Display, Keyboard, Audio インターフェース
```

## 技術スタック

Haskell (GHC2021) / GHC 9.6.7 / Cabal / tasty / vector / bytestring
