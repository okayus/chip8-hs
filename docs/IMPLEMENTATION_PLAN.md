# CHIP-8 エミュレータ (Haskell) 実装計画

## CHIP-8 システム仕様

### ハードウェア概要

| コンポーネント | 仕様 |
|---|---|
| メモリ (RAM) | 4,096 バイト (4 KB)。0x000–0x1FF はシステム予約、ROM は 0x200 から配置 |
| ディスプレイ | 64×32 ピクセル、モノクロ (1bit/pixel) |
| レジスタ | V0–VF (汎用 8bit × 16本)。VF はフラグレジスタ |
| プログラムカウンタ | PC: 16bit、初期値 0x200 |
| インデックスレジスタ | I: 16bit、メモリアドレス指定用 |
| スタック | 16 エントリ × 16bit、サブルーチン用 LIFO |
| タイマー | Delay Timer (DT) / Sound Timer (ST): 8bit、60Hz で減算 |
| 入力 | 16 キー (0x0–0xF)、4×4 hex キーパッド |
| オーディオ | 単一トーン、ST > 0 の間ビープ音 |

### フォントデータ

0x000–0x04F (80 バイト) に組み込みフォントスプライト (0–F) を配置。各文字 5 バイト × 16 文字。

### オペコード一覧 (35 命令)

| Opcode | ニーモニック | 動作 |
|---|---|---|
| 0x0000 | NOP | 何もしない |
| 0x00E0 | CLS | 画面クリア |
| 0x00EE | RET | サブルーチンから復帰 (スタック pop → PC) |
| 0x1NNN | JP addr | PC = NNN |
| 0x2NNN | CALL addr | スタック push PC, PC = NNN |
| 0x3XNN | SE Vx, byte | Vx == NN なら次命令スキップ |
| 0x4XNN | SNE Vx, byte | Vx != NN なら次命令スキップ |
| 0x5XY0 | SE Vx, Vy | Vx == Vy なら次命令スキップ |
| 0x6XNN | LD Vx, byte | Vx = NN |
| 0x7XNN | ADD Vx, byte | Vx += NN (キャリーなし) |
| 0x8XY0 | LD Vx, Vy | Vx = Vy |
| 0x8XY1 | OR Vx, Vy | Vx \|= Vy |
| 0x8XY2 | AND Vx, Vy | Vx &= Vy |
| 0x8XY3 | XOR Vx, Vy | Vx ^= Vy |
| 0x8XY4 | ADD Vx, Vy | Vx += Vy, VF = carry |
| 0x8XY5 | SUB Vx, Vy | Vx -= Vy, VF = NOT borrow |
| 0x8XY6 | SHR Vx | Vx >>= 1, VF = LSB |
| 0x8XY7 | SUBN Vx, Vy | Vx = Vy - Vx, VF = NOT borrow |
| 0x8XYE | SHL Vx | Vx <<= 1, VF = MSB |
| 0x9XY0 | SNE Vx, Vy | Vx != Vy なら次命令スキップ |
| 0xANNN | LD I, addr | I = NNN |
| 0xBNNN | JP V0, addr | PC = V0 + NNN |
| 0xCXNN | RND Vx, byte | Vx = random() & NN |
| 0xDXYN | DRW Vx, Vy, n | スプライト描画 (XOR)。衝突時 VF = 1 |
| 0xEX9E | SKP Vx | キー Vx 押下中ならスキップ |
| 0xEXA1 | SKNP Vx | キー Vx 非押下ならスキップ |
| 0xFX07 | LD Vx, DT | Vx = DT |
| 0xFX0A | LD Vx, K | キー入力待ち (ブロッキング) |
| 0xFX15 | LD DT, Vx | DT = Vx |
| 0xFX18 | LD ST, Vx | ST = Vx |
| 0xFX1E | ADD I, Vx | I += Vx |
| 0xFX29 | LD F, Vx | I = フォントアドレス (Vx * 5) |
| 0xFX33 | LD B, Vx | BCD 変換: RAM[I..I+2] = 百/十/一の位 |
| 0xFX55 | LD [I], Vx | V0–Vx を RAM[I..] に保存 |
| 0xFX65 | LD Vx, [I] | RAM[I..] から V0–Vx に読み込み |

---

## 実装フェーズ

### Phase 0: プロジェクトセットアップ

**ゴール**: Haskell プロジェクトの初期構成と開発環境の整備

- [x] Cabal プロジェクト初期化 (GHC2021, `-Wall -Wcompat`)
- [x] ディレクトリ構成: `src/Chip8/`, `test/Test/Chip8/`, `app/`, `docs/`
- [x] テストフレームワーク: tasty + tasty-hunit
- [x] GitHub リポジトリ作成 (パブリック)
- [x] main ブランチ保護設定
- [x] CLAUDE.md, README.md, 実装計画ドキュメント

### Phase 1: ドメイン型定義

**ゴール**: CHIP-8 のすべての値に型的な意味を与える

- [x] newtype 定義 (`Address`, `Byte`, `Nibble`, `RegisterIndex`, `Chip8Word16`)
- [x] スマートコンストラクタ (`mkAddress`, `mkByte`, `mkNibble`, `mkRegisterIndex`)
- [x] `CpuState` レコード型 (レジスタ, PC, I, SP, スタック, タイマー)
- [x] `Instruction` ADT (全 35 命令)
- [x] フォントデータ定数 (`Chip8.Font`)
- [x] テスト: スマートコンストラクタの境界値テスト (15 テスト)

### Phase 2: デコーダ

**ゴール**: `Word16` → `Instruction` の純粋変換

- [x] `decode :: Word16 -> Either String Instruction`
- [x] 不明オペコードに対する `Left` エラー
- [x] テスト: 全 35 命令のデコードテスト + 不正オペコード (35 テスト)

### Phase 3: CPU 状態とメモリ

**ゴール**: CPU の状態モデルとメモリアクセスの実装

- [x] `Memory` 型 (Unboxed Vector ベース 4KB RAM)
- [x] `newMemory` — フォント初期配置済みメモリ生成
- [x] `readByte`, `writeByte`, `readWord` — メモリ読み書き
- [x] `loadRom` — ROM データを 0x200 からロード
- [x] `fetch` — PC 位置から 16bit オペコード読み出し
- [x] `pushStack`, `popStack` — スタック操作 + 境界チェック
- [x] テスト: メモリ読み書き、ROM ロード、フォント配置 (11 テスト)

### Phase 4: 命令実行エンジン

**ゴール**: デコード済み `Instruction` を CPU 状態に適用する

- [x] ペリフェラルインターフェース定義 (`Display`, `Keyboard`, `Audio`)
- [x] `execute :: Instruction -> CpuState -> Memory -> IO ... -> IO (Either String ExecuteResult)`
- [x] 算術命令 (ADD, SUB, SHR, SHL) とキャリー/ボロー処理
- [x] 条件スキップ命令 (SE, SNE)
- [x] メモリ操作命令 (LD [I], BCD)
- [x] 描画命令 (DRW) — XOR 描画、衝突検出、ラップアラウンド
- [x] キー入力命令 (SKP, SKNP, LD Vx K)
- [x] タイマー命令 (LD DT, LD ST)
- [ ] テスト: 各命令の正常系・境界系テスト (モックペリフェラル使用)

### Phase 5: エミュレータ統合

**ゴール**: fetch → decode → execute ループの統合

- [x] `EmulatorState` 型 (CPU + Memory の統合)
- [x] `tick` — 1 CPU サイクル実行 (fetch → decode → execute)
- [x] `tickTimers` — タイマー減算 (フレームごとに 1 回)
- [x] `loadProgram` — ROM 読み込み
- [ ] テスト: 小さな ROM プログラムの統合テスト

### Phase 6: ターミナルフロントエンド

**ゴール**: ターミナル上で動作する UI

Haskell の特性を活かし、ブラウザではなくターミナルベースの UI を想定。

- [ ] `brick` ライブラリによるターミナル UI
- [ ] 64×32 のブロック文字描画
- [ ] キー入力ハンドリング
- [ ] ROM ファイル読み込み (コマンドライン引数)
- [ ] メインループ (60Hz タイマー + 10 ticks/frame)

### Phase 7: 仕上げ

- [ ] サンプル ROM の動作確認
- [ ] デバッグモード (レジスタ表示、ステップ実行)
- [ ] パフォーマンス最適化 (必要に応じて IORef / MutableVector)
- [ ] README 仕上げ

---

## キーボードマッピング

```
CHIP-8:           キーボード:
1 2 3 C           1 2 3 4
4 5 6 D     →     Q W E R
7 8 9 E           A S D F
A 0 B F           Z X C V
```

## 実行サイクル

```
1フレーム (60Hz):
  ├── 10回繰り返し: tick() = fetch → decode → execute
  ├── tickTimers() — DT, ST を 1 減算
  └── render() — 画面バッファをターミナルに描画
```

## Haskell 固有の設計判断

### なぜ Unboxed Vector を使うか

- メモリ (4KB) とレジスタ (16 byte) は頻繁にアクセスされるため、ボクシングのオーバーヘッドを避ける
- `Data.Vector.Unboxed` は `Word8` / `Word16` に対してゼロコスト抽象化を提供

### 純粋関数 vs IO

- `decode`: 完全に純粋。テスト最容易。
- `Cpu` ヘルパー: 純粋なレコード更新。
- `execute`: ペリフェラル操作のため IO。ただし `Maybe Peripherals` で非 IO テストも可能。
- `Memory`: 不変ベクタによる「関数型」メモリ。パフォーマンスが問題になれば `IOVector` に移行可能。

### エラーハンドリング

- スマートコンストラクタ: `Either String a`
- デコーダ: `Either String Instruction`
- スタック操作: `Either String CpuState`
- 将来的に `ExceptT` への移行も検討可能
