# OpenAPI Generator で生成されたコードの拡張方法

このドキュメントでは、OpenAPI Generator で生成されたコードに機能を追加する推奨方法について説明します。

## 基本原則

OpenAPI Generator で生成されたコードは、基本的に直接修正しないことが推奨されています。これには以下の理由があります：

1. **再生成による上書き**：OpenAPIの定義ファイルが更新された際に、コードを再生成すると手動の変更が失われます
2. **保守性の低下**：手動で変更を加えると、APIの仕様と実装の間に不整合が生じる可能性があります
3. **バージョン管理の複雑化**：生成コードに変更を加えると、再生成時の差分が大きくなりマージ作業が困難になります

## モデルクラスの拡張

`Pet.java`のようなモデルクラスを拡張する場合、以下のアプローチを取ることができます：

### 1. ラッパークラスを作成する方法

```java
package org.openapitools.extension.model;

import org.openapitools.model.Pet;

public class EnhancedPet {
    private final Pet originalPet;
    
    public EnhancedPet(Pet pet) {
        this.originalPet = pet;
    }
    
    // 拡張機能を追加
    public boolean isAdoptable() {
        return originalPet.getStatus() == Pet.StatusEnum.AVAILABLE;
    }
    
    // 年齢計算など、追加ビジネスロジック
    public int calculateApproximateAgeInHumanYears() {
        // ロジックを実装
        return 7; // 例えば、7歳相当とする
    }
    
    // オリジナルのペットオブジェクトへのアクセス
    public Pet getOriginalPet() {
        return originalPet;
    }
}
```

## API実装の拡張

API実装クラス（例：`PetApiController`）を拡張するためのアプローチはいくつかあります：

### 1. 拡張クラスによる実装

API実装クラスを継承して機能を拡張します：

```java
package org.openapitools.extension.api;

import org.openapitools.api.PetApiController;
import org.openapitools.model.Pet;
import org.springframework.stereotype.Component;
import org.springframework.http.ResponseEntity;

@Component
public class EnhancedPetApiController extends PetApiController {
    
    // 元のメソッドをオーバーライド
    @Override
    public ResponseEntity<Pet> getPetById(Long petId) {
        // 基本実装を呼び出し
        ResponseEntity<Pet> response = super.getPetById(petId);
        
        // 追加機能を実装
        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
            Pet pet = response.getBody();
            // 追加処理
            enhancePet(pet);
        }
        
        return response;
    }
    
    // 独自の処理を追加
    private void enhancePet(Pet pet) {
        // 例：特定の条件でステータスを変更するなど
    }
    
    // 新しい機能を追加
    public boolean isPetAdoptable(Long petId) {
        ResponseEntity<Pet> response = getPetById(petId);
        if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
            return response.getBody().getStatus() == Pet.StatusEnum.AVAILABLE;
        }
        return false;
    }
}
```

### 2. サービスレイヤーによる機能拡張

Controller とは別に、サービスクラスを作成してビジネスロジックを実装します：

```java
package org.openapitools.extension.service;

import org.openapitools.model.Pet;
import org.openapitools.api.PetApiController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PetService {
    
    @Autowired
    private PetApiController petApiController;
    
    public boolean isPetAvailableForAdoption(Long petId) {
        var petResponse = petApiController.getPetById(petId);
        if (petResponse.getStatusCode().is2xxSuccessful() && petResponse.getBody() != null) {
            Pet pet = petResponse.getBody();
            return pet.getStatus() == Pet.StatusEnum.AVAILABLE;
        }
        return false;
    }
    
    // その他のビジネスロジック
}
```

### 3. Delegateパターンの活用

OpenAPI Generator の `delegatePattern` オプションを使用して、Delegate インターフェースを実装する方法：

#### 設定変更

`openapitools.json` に以下の設定を追加します：

```json
{
  "delegatePattern": true
}
```

#### 実装方法

```java
package org.openapitools.api;

import org.openapitools.model.Pet;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;

@Component
public class PetApiDelegateImpl implements PetApiDelegate {
    
    @Override
    public ResponseEntity<Pet> getPetById(Long petId) {
        // ここに実装を書く
        Pet pet = new Pet("Sample Pet", Arrays.asList("https://example.com/photo.jpg"));
        pet.setId(petId);
        pet.setStatus(Pet.StatusEnum.AVAILABLE);
        return ResponseEntity.ok(pet);
    }
    
    // 他のメソッドもオーバーライド
}
```

## 実際の開発ワークフロー

1. OpenAPI仕様を更新する（`openapi.yaml`ファイル）
2. OpenAPI Generator でコードを再生成する
3. 独自の拡張クラスやサービスで機能を実装する
   - これらのクラスは再生成時に上書きされない
   - プロジェクト固有のビジネスロジックはこれらのクラスに配置する

## ベストプラクティス

1. 生成されたコードは変更せず、「読み取り専用」として扱う
2. 拡張やカスタマイズは別のパッケージ内で行う
3. 生成されたコードのバージョンを管理し、更新の際は差分を確認する
4. テストコードで生成されたコードと拡張機能の連携を検証する

以上のアプローチにより、OpenAPI仕様の更新に伴うコード再生成と、独自の機能拡張を両立させることができます。