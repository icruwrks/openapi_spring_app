# Jenkins CI/CD セットアップガイド

このプロジェクトには、Spring Boot アプリケーション (`spring-app`) のビルド、テスト、デプロイを自動化するための Jenkins パイプラインが含まれています。

## 📁 Jenkins関連ファイル

- `Jenkinsfile` - Jenkins パイプラインの定義
- `Dockerfile.jenkins` - CI/CD用のDockerfile
- `.jenkins/settings.xml` - Maven設定ファイル

## 🚀 Jenkins セットアップ

### 前提条件

Jenkins に以下のツールとプラグインが必要です：

#### 必要なツール
- **Maven** (バージョン 3.9.10)
- **JDK** (Java 17)
- **Docker** (オプション、コンテナ化デプロイ時)
- **SonarQube Scanner** (コード品質解析時)

#### 必要なプラグイン
```
- Pipeline Plugin
- Git Plugin
- Maven Integration Plugin
- JUnit Plugin
- Jacoco Plugin
- SonarQube Scanner Plugin
- Docker Pipeline Plugin (オプション)
- Slack Notification Plugin (オプション)
```

### Jenkins での設定手順

1. **新しいパイプライン ジョブの作成**
   ```
   New Item → Pipeline → プロジェクト名を入力
   ```

2. **Git リポジトリの設定**
   ```
   Pipeline → Definition: Pipeline script from SCM
   SCM: Git
   Repository URL: [あなたのリポジトリURL]
   Branch: */main (またはデフォルトブランチ)
   Script Path: Jenkinsfile
   ```

3. **ツールの設定**
   
   Jenkins の Global Tool Configuration で以下を設定：
     **Maven**
   ```
   Name: maven-3.9.10
   Install automatically: チェック
   Version: 3.9.10
   ```
   
   **JDK**
   ```
   Name: JDK17_Default
   Install automatically: チェック
   Version: Eclipse Temurin 17
   ```

4. **環境変数の設定**
   
   必要に応じて以下の環境変数を設定：
   ```
   SONAR_TOKEN=your_sonar_token
   NEXUS_USERNAME=your_nexus_username
   NEXUS_PASSWORD=your_nexus_password
   DOCKER_USERNAME=your_docker_username
   DOCKER_PASSWORD=your_docker_password
   ```

## 🔄 パイプライン ステージ

### 1. Checkout
- Git リポジトリからソースコードを取得

### 2. Environment Info
- ビルド環境の情報を表示

### 3. Validate
- プロジェクト構造とpom.xmlを検証

### 4. Clean
- 前回のビルド成果物をクリーンアップ

### 5. Compile
- Java ソースコードをコンパイル

### 6. Test
- ユニットテストを実行
- テストレポートとカバレッジレポートを生成

### 7. Package
- JAR ファイルを作成

### 8. Verify
- 生成されたパッケージを検証

### 9. Archive Artifacts
- ビルド成果物をアーカイブ

### 10. SonarQube Analysis (条件付き)
- メインブランチと開発ブランチでコード品質解析を実行

### 11. Deploy to Dev (条件付き)
- develop ブランチから開発環境にデプロイ

### 12. Deploy to Staging (条件付き)
- main ブランチからステージング環境にデプロイ

### 13. Integration Tests (条件付き)
- 結合テストを実行

## 🐳 Docker を使用したビルド

Docker を使用してビルドする場合：

```bash
# ビルド
docker build -f Dockerfile.jenkins -t openapi-spring-app .

# 実行
docker run -p 8080:8080 openapi-spring-app
```

## 📊 ビルド成果物

パイプライン実行後、以下が生成されます：

- **JAR ファイル**: `spring-app/target/openapi-spring-*.jar`
- **テストレポート**: `spring-app/target/surefire-reports/`
- **カバレッジレポート**: `spring-app/target/site/jacoco/`

## 🔧 カスタマイズ

### ブランチ戦略の変更

異なるブランチ戦略を使用する場合は、Jenkinsfile の `when` 条件を修正してください：

```groovy
when {
    branch 'your-branch-name'
}
```

### デプロイメント設定

デプロイメントステージをカスタマイズするには：

1. `Deploy to Dev` や `Deploy to Staging` ステージの内容を修正
2. 環境固有の設定ファイルを追加
3. Kubernetes、Docker Compose、またはその他のデプロイメントツールに合わせて調整

### 通知設定

Slack や Email 通知を有効にするには：

1. 該当するプラグインをインストール
2. Jenkinsfile の `post` セクションでコメントアウトされた通知コードを有効化
3. 適切な認証情報を設定

### Java バージョンのアップグレード

現在のプロジェクトはJava 8で設定されていますが、JDK 17を最大限活用するには以下の変更を推奨します：

**pom.xmlの更新例:**
```xml
<properties>
    <java.version>17</java.version>
    <maven.compiler.source>${java.version}</maven.compiler.source>
    <maven.compiler.target>${java.version}</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <springdoc.version>2.0.2</springdoc.version>
    <swagger-ui.version>4.18.2</swagger-ui.version>
</properties>
```

**Spring Boot バージョンの更新例:**
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.1.0</version>
    <relativePath/>
</parent>
```

**注意**: Spring Boot 3.x にアップグレードする場合は、javax パッケージが jakarta に変更されているため、コードの修正が必要になる場合があります。

## 🚨 トラブルシューティング

### よくある問題

**Maven の依存関係解決エラー**
```
解決策: .jenkins/settings.xml のリポジトリ設定を確認
```

**Java バージョンの不一致**
```
解決策: pom.xml のjava.versionプロパティとJenkinsのJDK設定を確認
```

**テスト失敗**
```
解決策: ローカルでテストを実行し、環境固有の問題を特定
```

**Docker ビルドエラー**
```
解決策: Docker デーモンが実行中かつ適切な権限があることを確認
```

## 📝 ログとモニタリング

- **ビルドログ**: Jenkins コンソール出力で確認
- **テストレポート**: Jenkins の Test Results
- **カバレッジレポート**: Jenkins の Coverage Reports
- **SonarQube**: コード品質メトリクス

## 🤝 貢献

パイプラインの改善提案がある場合は、プルリクエストを作成してください。

---

**注意**: 本番環境にデプロイする前に、すべての設定とセキュリティ要件を確認してください。
