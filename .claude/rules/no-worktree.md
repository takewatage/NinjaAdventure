# worktree を使わない

## 概要

このプロジェクトでは git worktree を作らず、メインのチェックアウト（リポジトリ直下）のファイルを直接編集する。`/run-tasks` など worktree を作る skill を使うときも、worktree の作成（Phase 2-1）は飛ばし、作業・計画書・確認はすべてリポジトリ直下で行う。

## 理由

ユーザーは Godot エディタでリポジトリ直下を開いて動作を確認する。worktree に入れた変更はそこに反映されず、「直したはずなのに動かない」状態になる（NA-89 で `test.tscn` の術ホイールが使えないと報告された）。worktree を開き直すには、そのたびに別のプロジェクトとして import し直す手間もかかる。

**Why:** ユーザーから「godot では worktree は使わなくて直接編集していいです」と指示があったため（2026-11-19）。

## 適用

- ブランチは作らず、リポジトリ直下の `main` で作業する（[no-branch.md](no-branch.md)）。
- 計画書（`.tasks/plans/`）もリポジトリ直下に置く。
- サブエージェントに作業させるときも、作業ディレクトリはリポジトリ直下を渡す。

## 関連ファイル

- [communication.md](communication.md) — 応答と作業報告のルール
- [no-branch.md](no-branch.md) — ブランチを分けずに main へ直接コミットする
