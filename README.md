# arc.app.hub

アプリの入口をひとまとめにするハブです。GitHub Pages で公開し、データは Supabase に保存します。

| ファイル | 役割 |
|---|---|
| `index.html` | 生徒用(閲覧のみ) |
| `admin.html` | 講師用(ログイン後に追加・編集・削除・並べ替え) |
| `config.js` | Supabase の接続設定 |
| `supabase/schema.sql` | テーブルと権限の作成 |
| `supabase/add_teacher.sql` | 講師アカウントの登録 |
| `sample-apps.json` | 管理画面から読み込める見本データ |
| `.github/workflows/keepalive.yml` | 無料プランの自動停止を防ぐ定期アクセス |

## セットアップ手順

### 1. Supabase プロジェクトを作る

1. [supabase.com](https://supabase.com) でプロジェクトを新規作成します(リージョンは Northeast Asia (Tokyo) が近いです)。
2. **SQL Editor** を開き、`supabase/schema.sql` の中身を貼り付けて **Run** します。

### 2. 講師アカウントを作る

1. **Authentication > Users > Add user** で、講師のメールアドレスとパスワードを入力し、**Auto Confirm User** にチェックして作成します。
2. `supabase/add_teacher.sql` のメールアドレスを書き換え、SQL Editor で **Run** します。最後に1行表示されれば成功です。
3. **Authentication > Sign In / Providers**(旧 Settings)で **Allow new users to sign up** を **オフ** にします。これで第三者がアカウントを作れなくなります。

### 3. config.js を書き換える

**Project Settings > API** で次の2つを確認し、`config.js` に貼り付けます。

- Project URL
- `anon` `public` キー

> `service_role` キーは絶対に貼らないでください。anon キーは公開前提で、権限は Supabase 側の設定(RLS)で守られています。

### 4. GitHub Pages で公開する

1. GitHub に `arc.app.hub` リポジトリを作り、このフォルダの中身をすべてアップロードします(`.github` フォルダも含めてください)。
2. **Settings > Pages** で、Source を **Deploy from a branch**、Branch を `main` / `/ (root)` にして保存します。
3. 数分後、次のURLで開けます。
   - 生徒用: `https://<ユーザー名>.github.io/arc.app.hub/`
   - 講師用: `https://<ユーザー名>.github.io/arc.app.hub/admin.html`

### 5. 初期データを登録する

講師用ページにログインし、「アプリを追加」で1件ずつ登録するか、「JSONを読み込む」で `sample-apps.json` と同じ形式のファイルを一括登録します。見本を試して、不要なものは削除してください。

### 6. 自動停止を防ぐ(推奨)

Supabase の無料プランは、約1週間アクセスがないとプロジェクトが一時停止します。

1. GitHub のリポジトリで **Settings > Secrets and variables > Actions** を開きます。
2. **New repository secret** で次の2つを登録します。
   - `SUPABASE_URL`: Project URL
   - `SUPABASE_ANON_KEY`: anon キー
3. **Actions** タブで `Supabase keepalive` を選び、**Run workflow** で一度手動実行して、成功(緑)になることを確認します。

> 公開リポジトリでは、60日間リポジトリに動きがないと GitHub が定期実行を自動で止めます。通知メールが届いたら Actions タブから再開してください。確実に運用したい場合は、Supabase の有料プランも選択肢です。

## 使い方(講師)

- **追加・編集**: 名前、URL、説明、カテゴリ、アイコン(絵文字または画像URL)、タグを入力します。URLの形式と重複はチェックされます。
- **並べ替え**: 行のドラッグ、または「↑」「↓」で変更します。変更は自動で保存されます。
- **表示/非表示**: 準備中のアプリは非表示にすると生徒画面から消えます(データ取得の段階で除外されます)。
- **バックアップ**: 「JSONを書き出す」で現在の内容を保存できます。月に1回程度の書き出しをおすすめします。

## 注意

- 公開ページなので、**パスワードや限定共有のURLなど、秘匿すべき情報はアプリのURL・説明に入れないでください。**
- 表示中のアプリは、URLを知っていれば誰でも取得できます。生徒だけに限定したい場合は、生徒側にもログインを入れる拡張が必要です。
- `admin.html` は検索エンジンに載らない設定にしていますが、URLを知っていればページ自体は開けます。ログインできるのは登録した講師のみです。
