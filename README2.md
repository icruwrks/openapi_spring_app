# Spring Boot アプリケーション動作確認手順

## 1. アプリケーションのビルド

```bash
cd ./spring-app
mvn install
```

これにより `target/openapi-spring-1.0.11.jar` が生成されます。

## 2. アプリケーションの起動

```bash
java -jar target/openapi-spring-1.0.11.jar
```

アプリケーションは起動すると、デフォルトで8080ポートでリッスンします。

## 3. API動作確認コマンド

### OpenAPI仕様の確認

```bash
curl -s http://localhost:8080/v3/api-docs | head -30
```

### ペット関連API

#### 利用可能なペットを検索

```bash
curl -X GET "http://localhost:8080/api/v3/pet/findByStatus?status=available" -H "accept: application/json"
```

#### 特定IDのペットを取得

```bash
curl -X GET "http://localhost:8080/api/v3/pet/10" -H "accept: application/json"
```

#### 新しいペットを追加

```bash
curl -X POST "http://localhost:8080/api/v3/pet" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"kitty\",\"photoUrls\":[\"http://example.com/cat.jpg\"],\"category\":{\"id\":2,\"name\":\"Cats\"},\"status\":\"available\"}"
```

### ストア関連API

#### 在庫状況を確認

```bash
curl -X GET "http://localhost:8080/api/v3/store/inventory" \
  -H "accept: application/json"
```

#### 注文を作成

```bash
curl -X POST "http://localhost:8080/api/v3/store/order" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"id\":1,\"petId\":10,\"quantity\":1,\"shipDate\":\"2023-10-20T12:00:00.000Z\",\"status\":\"placed\",\"complete\":false}"
```

### ユーザー関連API

#### ユーザーを作成

```bash
curl -X POST "http://localhost:8080/api/v3/user" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"id\":1,\"username\":\"testuser\",\"firstName\":\"Test\",\"lastName\":\"User\",\"email\":\"test@example.com\",\"password\":\"password123\",\"phone\":\"1234567890\",\"userStatus\":0}"
```

## 4. Swagger UIで視覚的に操作

ブラウザで以下のURLにアクセスすると、Swagger UIを通じてAPIを視覚的に確認・テストできます。

```
http://localhost:8080/swagger-ui.html
```

## 注意事項

- このアプリケーションはメモリ内でデータを保持しているため、サーバーを再起動するとデータはリセットされます。
- このアプリケーションは[OpenAPI Petstore](https://github.com/swagger-api/swagger-petstore)のサンプル実装です。
- アプリケーションはSpring Boot 2.7.15をベースに構築されています。