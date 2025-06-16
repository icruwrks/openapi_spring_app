# アプリの作成

## openapi-generator のインストール

- https://openapi-generator.tech/docs/installation/　を参考にインストールやランタイムで実行してください


```
sudo npm install @openapitools/openapi-generator-cli -g
```

```
npx @openapitools/openapi-generator-cli <command> [options]
```

## openapi.yaml を作成する

- サンプルは https://editor.swagger.io/ からダウンロードした

## コードを生成する

- OpenAPI Generator を利用する例
- openapi.yamlから、sample-app にコード出力するコマンド例

```
sudo npx @openapitools/openapi-generator-cli generate -i openapi.yaml -g java -o ./sample-app
sudo npx @openapitools/openapi-generator-cli generate -i openapi.yaml -g spring -o ./spring-app
```

# HTMLドキュメントの作成

## Redocly のインストール

- https://redocly.com/docs/cli/installation を参考にインストールやランタイムで実行してください

```
npx @redocly/cli <command> [options]
```

## HTMLの生成

```
npx @redocly/cli build-docs openapi.yaml --output=openapi.html
```

# OpenAPI 開発に便利なプラグイン例(VSCode)

## ツール等
- https://zenn.dev/s_t_pool/articles/954dfe51b950c18d08e9

## ファイルが大きくなる場合は、こちらのように分割を検討する
- メモ：ディレクトリ構成は記事によって違うので、検討の余地がある
- https://zenn.dev/yamatonokuni/articles/f7801d8dcbebad
- https://qiita.com/tMinamiii/items/5b1a921e82b4c7979cd1
- https://blog.nnn.dev/entry/2022/04/20/110000
- https://note.com/navitime_tech/n/n6cf3581cef1e

# 分割したファイルを結合する

コードの生成や、プレビュー等がうまくいかないときに、結合した状態のファイルを確認したい場合は、以下のように結合することができます。

```
npx @redocly/cli bundle openapi.yaml --output=openapi_bundle.yaml
```

# アプリ実行

```
sudo chown -R i-moriya. .
cd ./spring-app
mvn install
java -jar target/openapi-spring-1.0.11.jar 
```


# テスト実行

``
cd spring-app
mvn test
``


## Dockerコンテナ

```bash
# Rancher Desktop 使用時にArmを有効化する
docker run --privileged --rm tonistiigi/binfmt --install linux/arm64

# arm 版
docker build --platform linux/arm64 -f Dockerfile -t spring_server .

docker run --platform linux/arm64 -i -p 8080:8080 spring_server
```