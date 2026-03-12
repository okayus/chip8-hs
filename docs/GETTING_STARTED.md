# 動作確認ガイド

このドキュメントでは、CHIP-8 エミュレータ (Haskell) のビルド・テスト・実行方法を説明します。

---

## 前提環境

以下のツールがインストールされている必要があります。

| ツール | バージョン | 確認コマンド |
|---|---|---|
| GHC | 9.6 以上 | `ghc --version` |
| Cabal | 3.12 以上 | `cabal --version` |

[GHCup](https://www.haskell.org/ghcup/) で一括インストールできます。

```bash
# まだ入れていない場合
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

---

## 1. ビルド

```bash
cd chip8-hs
cabal build
```

初回は依存ライブラリのダウンロード・コンパイルに数分かかります。
2 回目以降は変更したファイルだけ再コンパイルされるので高速です。

### ビルド成功時の出力例

```
Building library for chip8-hs-0.1.0.0...
[1 of 9] Compiling Chip8.Font
[2 of 9] Compiling Chip8.Instruction
...
Building executable 'chip8-hs' for chip8-hs-0.1.0.0...
```

### ビルドエラーが出たら

| よくあるエラー | 原因 | 対処 |
|---|---|---|
| `Could not resolve dependencies` | パッケージリストが古い | `cabal update` を実行 |
| `Module 'Xxx' is not a member of the package` | cabal ファイルにモジュールが未登録 | `chip8-hs.cabal` の `exposed-modules` を確認 |
| `Not in scope: 'xxx'` | import 漏れ | エラーメッセージの通りに import を追加 |

---

## 2. テスト実行

```bash
cabal test
```

### テスト成功時の出力例

```
CHIP-8 Emulator Tests
  Types
    mkAddress
      0x000 は有効:       OK
      0xFFF は有効:       OK
      0x1000 は無効:      OK
    ...
  Decode
    System
      0x0000 → NOP:       OK
      0x00E0 → CLS:       OK
    ...
  Memory
    newMemory
      フォントデータが 0x000 から配置されている: OK
    ...

All 61 tests passed (0.00s)
```

### テスト構成

| テストモジュール | 何をテストしているか | テスト数 |
|---|---|---|
| `Test.Chip8.Types` | newtype のスマートコンストラクタ、CPU 初期状態 | 15 |
| `Test.Chip8.Decode` | 全 35 命令のデコード + 不正オペコード | 35 |
| `Test.Chip8.Memory` | メモリ読み書き、ROM ロード、フォント配置 | 11 |
| `Test.Chip8.Execute` | 命令実行（Phase 4 で追加予定） | 0 |
| `Test.Chip8.Emulator` | 統合テスト（Phase 5 で追加予定） | 0 |

テストファイルは `test/Test/Chip8/` 以下にあります。

---

## 3. ROM を実行する

### 基本コマンド

```bash
cabal run chip8-hs -- <ROMファイルのパス>
```

`--` はcabal自体のオプションとプログラムの引数を区切るために必要です。

### 実行例: MAZE ROM

MAZE は入力不要で画面に迷路を描画するだけなので、動作確認に最適です。

```bash
cabal run chip8-hs -- /home/okayu/dev/challenge/chip8/chip8-book/roms/MAZE
```

#### 期待される出力

```
CHIP-8 Emulator (Haskell) — Loading: .../MAZE
ROM size: 34 bytes

+----------------------------------------------------------------+
|█     █ █     █ █     █   █   █   █ █     █   █ █   █     █   █ |
| █   █   █   █   █   █   █   █   █   █   █   █   █   █   █   █  |
|  █ █     █ █     █ █   █   █   █     █ █   █     █   █ █   █   |
...（64×32 の迷路パターンが全画面に表示される）...
+----------------------------------------------------------------+

PC: 0x0218  I: 0x021A  SP: 0
```

- `█` がピクセル ON、スペースがピクセル OFF
- 最下部に CPU レジスタの状態が表示されます
- 実行ごとに乱数で異なるパターンが生成されます

### その他の ROM

```bash
# ミサイル — ターゲットとミサイルのスプライトが表示される
cabal run chip8-hs -- /home/okayu/dev/challenge/chip8/chip8-book/roms/MISSILE

# Pong — スコア「00:00」とパドルが表示される（キー入力未対応のため静止画）
cabal run chip8-hs -- /home/okayu/dev/challenge/chip8/chip8-book/roms/PONG
```

### ROM が見つからない場合

引数なしで実行するとヘルプが表示されます。

```bash
cabal run chip8-hs
# => Usage: chip8-hs <rom-file>
```

---

## 4. よく使うコマンドまとめ

| やりたいこと | コマンド |
|---|---|
| ビルド | `cabal build` |
| テスト実行 | `cabal test` |
| ROM 実行 | `cabal run chip8-hs -- <ROM>` |
| ビルド成果物を削除 | `cabal clean` |
| パッケージリスト更新 | `cabal update` |
| GHCi で対話的にモジュールを試す | `cabal repl` |

---

## 5. GHCi でモジュールを対話的に試す

Haskell の REPL（対話環境）で各モジュールを直接触ることができます。

```bash
cabal repl
```

### 例: デコーダを試す

```haskell
ghci> import Chip8.Decode
ghci> decode 0x00E0
Right CLS

ghci> decode 0x6A42
Right (LDByte 10 66)

ghci> decode 0xFFFF
Left "Unknown opcode: 0xFFFF"
```

### 例: メモリを試す

```haskell
ghci> import Chip8.Memory
ghci> let mem = newMemory
ghci> readByte mem 0x000   -- フォントデータの先頭
240                        -- 0xF0 = "0" の 1 行目

ghci> let mem2 = writeByte mem 0x300 0x42
ghci> readByte mem2 0x300
66                         -- 0x42
ghci> readByte mem 0x300
0                          -- 元のメモリは変わらない（不変データ）
```

> **ポイント**: Haskell のデータは不変（immutable）です。`writeByte` は新しいメモリを返し、元のメモリは変化しません。TypeScript の `const arr = [...old]` で新しい配列を作るイメージです。

### 例: スマートコンストラクタを試す

```haskell
ghci> import Chip8.Types
ghci> mkAddress 0x200
Right (Address 512)

ghci> mkAddress 0x1000
Left "Invalid address: 4096"

ghci> mkNibble 0xF
Right (Nibble 15)

ghci> mkNibble 0x10
Left "Invalid nibble: 16"
```

---

## 6. 現在の実装状況

| Phase | 内容 | 状態 |
|---|---|---|
| 0 | プロジェクトセットアップ | ✅ 完了 |
| 1 | ドメイン型定義 | ✅ 完了 |
| 2 | デコーダ | ✅ 完了 |
| 3 | CPU 状態とメモリ | ✅ 完了 |
| 4 | 命令実行エンジン | ✅ 実装済み（テスト追加予定） |
| 5 | エミュレータ統合 | ✅ 実装済み（テスト追加予定） |
| 6 | ターミナルフロントエンド | 🔲 未着手 |
| 7 | 仕上げ | 🔲 未着手 |

詳細は [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) を参照してください。
