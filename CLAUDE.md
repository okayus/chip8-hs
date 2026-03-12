# CHIP-8 Emulator — Haskell Implementation

## プロジェクト概要

CHIP-8 エミュレータの Haskell 実装。Haskell の型システムと代数的データ型を活用し、仕様違反をコンパイル時に排除することを目指す。

## 設計原則: 型で「意味」と「不変条件」を表現する

### 1. newtype でドメイン値を区別する

素の `Word8` / `Word16` ではなく、ドメイン上の意味を持つ newtype を定義する。

```haskell
-- NG: ただの Word16 — Address と opcode の取り違えを検出できない
readByte :: Word16 -> Word8

-- OK: newtype で意味を区別する
newtype Address       = Address Word16
newtype Byte          = Byte Word8
newtype Nibble        = Nibble Word8
newtype RegisterIndex = RegisterIndex Word8
```

### 2. 代数的データ型 (ADT) でオペコードを表現する

全 35 命令を sum type で表現し、パターンマッチの網羅性チェックが効く。

```haskell
data Instruction
  = CLS
  | RET
  | JP !Word16
  | CALL !Word16
  | SEByte !Word8 !Word8
  | ADDVy !Word8 !Word8
  | DRW !Word8 !Word8 !Word8
  -- ... 全35命令
```

`execute` 関数は `case instr of ...` で全パターンを処理。GHC の `-Wincomplete-patterns` で漏れを検出。

### 3. スマートコンストラクタで不変条件を強制する

```haskell
mkAddress :: Word16 -> Either String Address
mkAddress n
  | n <= 0xFFF = Right (Address n)
  | otherwise  = Left $ "Invalid address: " ++ show n
```

### 4. 純粋関数と副作用の分離

- **純粋関数**: `decode :: Word16 -> Either String Instruction` — 副作用なし、テスト容易
- **純粋 + 状態**: CPU 状態操作は純粋なレコード更新で表現
- **IO**: Display, Keyboard, Audio はレコード型インターフェースで抽象化

### 5. テストはドメインの「仕様書」

```haskell
testGroup "8XY4 (ADD VX, VY)"
  [ testCase "VX + VY がオーバーフローしない場合、VF = 0" $ ...
  , testCase "VX + VY がオーバーフローする場合、VF = 1" $ ...
  ]
```

## 開発フロー

- main ブランチへの直プッシュは禁止（ブランチ保護設定済み）
- Phase ごとにブランチを作成し、PR を通じてマージする

### ワークフロー

1. `main` から Phase ブランチを作成 (`phase/{番号}-{短い説明}`)
2. 実装 + テスト + ビルド を全て pass させる
3. PR を作成し、description に以下を記述:
   - 何を実装するか（スコープ）
   - モジュール構成・型設計の方針
   - テスト方針
4. セルフレビュー（diff を確認し、設計原則に沿っているか検証）
5. 問題なければ squash merge し、リモートブランチを削除
6. `main` を pull して次の Phase へ

### ブランチ命名規則

```
phase/{phase番号}-{短い説明}
例: phase/0-setup, phase/1-domain-types, phase/2-decoder
```

### チェックリスト (PR マージ前)

- `cabal build` — ビルド pass（警告なし: `-Wall -Wcompat`）
- `cabal test` — 全テスト pass
- diff のセルフレビュー完了

## 技術スタック

- **言語**: Haskell (GHC2021)
- **コンパイラ**: GHC 9.6.7
- **ビルド**: Cabal 3.12
- **テスト**: tasty + tasty-hunit
- **主要ライブラリ**: vector (Unboxed), bytestring, random, mtl

## ディレクトリ構成

```
src/
  Chip8/
    Types.hs         # ドメイン型定義 (Address, Byte, CpuState, etc.)
    Instruction.hs   # 命令 ADT (全35命令)
    Font.hs          # フォントスプライトデータ
    Decode.hs        # デコーダ (Word16 → Instruction)
    Memory.hs        # メモリ管理 (4KB RAM)
    Cpu.hs           # CPU 状態操作ヘルパー
    Execute.hs       # 命令実行エンジン
    Emulator.hs      # エミュレータ統合 (fetch-decode-execute loop)
    Peripherals.hs   # Display, Keyboard, Audio インターフェース
app/
  Main.hs            # 実行可能ファイルのエントリーポイント
test/
  Main.hs            # テストランナー
  Test/Chip8/        # モジュール別テスト
docs/
  IMPLEMENTATION_PLAN.md  # 実装計画
```

## コマンド

```bash
cabal build       # ビルド
cabal test        # テスト実行
cabal run         # 実行
cabal clean       # ビルド成果物を削除
```
