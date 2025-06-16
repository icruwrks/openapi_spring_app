# OpenAPI初心者ガイド

## OpenAPIとは

OpenAPI仕様（旧Swagger仕様）は、REST APIを記述するための標準フォーマットです。OpenAPIを使うことで、人間にも機械にも読みやすい形式でAPIを文書化し、クライアントやサーバーのコードを自動生成できます。

## このプロジェクトの構成

このプロジェクトは、OpenAPI仕様を使ったペットストアAPIの実装例です。以下の主要コンポーネントで構成されています：

```
aws-copilot-java-app/
├── openapi.yaml            # メインのOpenAPI定義ファイル
├── components/             # APIコンポーネント（スキーマ、リクエストボディなど）
│   ├── schemas/           # データモデル定義
│   └── requestBodies/     # リクエストボディ定義
├── paths/                 # APIパス（エンドポイント）定義
├── spring-app/            # Spring Bootによるサーバー実装
└── sample-app/            # クライアントアプリケーション実装
```

## OpenAPI仕様の基本

OpenAPI仕様は主に以下の要素で構成されています：

1. **メタ情報**: APIのタイトル、バージョン、説明などの基本情報
2. **パス**: APIが公開するエンドポイントと、そのHTTPメソッド
3. **コンポーネント**: データモデル（スキーマ）やリクエスト/レスポンス定義
4. **セキュリティ**: 認証方式の定義

## このプロジェクトのOpenAPI仕様

このプロジェクトの`openapi.yaml`ファイルには、ペットストアAPIの仕様が定義されています。主に以下の機能があります：

- ペット管理（追加、検索、更新、削除）
- ストア管理（注文、在庫確認）
- ユーザー管理（作成、ログイン、更新）

## モジュール分割されたOpenAPI仕様

大規模なAPI定義では、OpenAPI仕様を複数のファイルに分割することが一般的です。このプロジェクトでは：

- `components/schemas/`: データモデル（Pet, User, Orderなど）の定義
- `components/requestBodies/`: リクエストボディの定義
- `paths/`: 各APIエンドポイントの定義（例：`pet.yaml`, `user.yaml`）

## コード生成

OpenAPIの最大の利点の一つは、API定義からコードを自動生成できることです：

1. **サーバーコード生成**: `spring-app`ディレクトリには、OpenAPI定義から生成されたSpring Bootサーバーがあります
2. **クライアントコード生成**: `sample-app`ディレクトリには、同じ定義から生成されたJavaクライアントがあります

## サーバー実装（spring-app）

`spring-app`は、OpenAPI Generatorを使って自動生成されたSpring Bootアプリケーションです：

- コントローラーはOpenAPI定義のパスに基づいて生成されています
- データモデルはOpenAPIのスキーマから生成されています
- Swagger UIが組み込まれており、APIをブラウザでテストできます

## サーバーの実行方法

```bash
cd spring-app
mvn install
java -jar target/openapi-spring-1.0.11.jar
```

サーバーは8080ポートで起動し、以下のURLでSwagger UIにアクセスできます：
```
http://localhost:8080/swagger-ui.html
```

## APIの使用例

起動したサーバーに対し、curlコマンドでAPIを呼び出す例：

### 利用可能なペットを検索
```bash
curl -X GET "http://localhost:8080/api/v3/pet/findByStatus?status=available" -H "accept: application/json"
```

### 新しいペットを追加
```bash
curl -X POST "http://localhost:8080/api/v3/pet" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"kitty\",\"photoUrls\":[\"http://example.com/cat.jpg\"],\"category\":{\"id\":2,\"name\":\"Cats\"},\"status\":\"available\"}"
```

## OpenAPIのメリット

1. **ドキュメントと実装の一体化**: API仕様がそのままドキュメントになり、常に最新状態を保てます
2. **コード生成**: サーバーとクライアントのコードを自動生成でき、開発工数を削減できます
3. **ツールサポート**: Swagger UIなど、多くのツールが利用可能です
4. **言語非依存**: 様々なプログラミング言語でコード生成が可能です

## OpenAPIを始める手順

1. OpenAPI仕様ファイル（YAML or JSON）を作成する
2. [Swagger Editor](https://editor.swagger.io/)などでバリデーション
3. OpenAPI Generatorを使ってコード生成
   ```bash
   # サーバーコード生成の例（Spring Boot）
   openapi-generator-cli generate -i openapi.yaml -g spring -o my-spring-app
   
   # クライアントコード生成の例（Java）
   openapi-generator-cli generate -i openapi.yaml -g java -o my-java-client
   ```
4. 生成されたコードを必要に応じてカスタマイズ
5. 実装・テスト・デプロイ

## 参考リンク

- [OpenAPI Initiative](https://www.openapis.org/)
- [OpenAPI仕様](https://spec.openapis.org/oas/latest.html)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Swagger Editor](https://editor.swagger.io/)