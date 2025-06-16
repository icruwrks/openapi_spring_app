# OpenAPI Generator で生成されたコードのテスト手法

このドキュメントでは、OpenAPI Generator で自動生成されたコードに対するテストコードの書き方について説明します。自動生成されたコードを直接修正せずに、適切にテストする方法を紹介します。

## テストの基本方針

1. **自動生成されたコードの直接テスト**：生成されたコードの基本動作を確認
2. **拡張クラスのテスト**：自作の拡張クラスの機能を検証
3. **統合テスト**：実際のAPIエンドポイントを通した動作確認

## 1. コントローラーのテスト

### 1.1 自動生成されたコントローラーのテスト

`PetApiController`などの自動生成されたコントローラーをテストする例:

```java
package org.openapitools.api.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.openapitools.api.PetApiController;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.ObjectMapper;

@WebMvcTest(PetApiController.class)
public class PetApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PetApiController petApiController;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGetPetById() throws Exception {
        // モックMVCを使ったテスト
        MvcResult result = mockMvc.perform(get("/pet/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();

        Pet pet = objectMapper.readValue(result.getResponse().getContentAsString(), Pet.class);
        assertNotNull(pet);
        assertEquals(1L, pet.getId());
    }

    @Test
    public void testGetPetByIdDirectly() {
        // コントローラーを直接呼び出すテスト
        ResponseEntity<Pet> response = petApiController.getPetById(1L);
        
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1L, response.getBody().getId());
    }
}
```

### 1.2 拡張したコントローラーのテスト

前述の「拡張クラスによる実装」で作成した`EnhancedPetApiController`をテストする例：

```java
package org.openapitools.extension.api.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.openapitools.extension.api.EnhancedPetApiController;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;

@SpringBootTest
public class EnhancedPetApiControllerTest {

    @Autowired
    private EnhancedPetApiController enhancedPetApiController;

    @Test
    public void testGetPetById() {
        // 拡張コントローラーの基本機能テスト
        ResponseEntity<Pet> response = enhancedPetApiController.getPetById(1L);
        
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals(1L, response.getBody().getId());
    }

    @Test
    public void testIsPetAdoptable() {
        // 拡張コントローラーの追加機能テスト
        boolean isAdoptable = enhancedPetApiController.isPetAdoptable(1L);
        assertTrue(isAdoptable); // 利用可能なペットの場合
        
        boolean isNotAdoptable = enhancedPetApiController.isPetAdoptable(2L);
        assertFalse(isNotAdoptable); // 利用不可能なペットの場合
    }
}
```

## 2. サービスレイヤーのテスト

サービスクラスをテストする例：

```java
package org.openapitools.extension.service.test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.openapitools.api.PetApiController;
import org.openapitools.extension.service.PetService;
import org.openapitools.model.Pet;
import org.springframework.http.ResponseEntity;

public class PetServiceTest {

    @Mock
    private PetApiController petApiController;

    private PetService petService;

    @BeforeEach
    public void setup() {
        MockitoAnnotations.openMocks(this);
        petService = new PetService();
        // モックコントローラをサービスにセット（Reflectionを使用するか、setterを用意）
        // この例ではReflectionを使用
        java.lang.reflect.Field field;
        try {
            field = petService.getClass().getDeclaredField("petApiController");
            field.setAccessible(true);
            field.set(petService, petApiController);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testIsPetAvailableForAdoption() {
        // テスト用のペットオブジェクトを作成
        Pet availablePet = new Pet();
        availablePet.setId(1L);
        availablePet.setName("Available Pet");
        availablePet.setStatus(Pet.StatusEnum.AVAILABLE);

        Pet pendingPet = new Pet();
        pendingPet.setId(2L);
        pendingPet.setName("Pending Pet");
        pendingPet.setStatus(Pet.StatusEnum.PENDING);

        // モックの振る舞いを定義
        when(petApiController.getPetById(1L)).thenReturn(ResponseEntity.ok(availablePet));
        when(petApiController.getPetById(2L)).thenReturn(ResponseEntity.ok(pendingPet));

        // テスト実行
        boolean isAvailable = petService.isPetAvailableForAdoption(1L);
        boolean isPending = petService.isPetAvailableForAdoption(2L);

        // 検証
        assertTrue(isAvailable);
        assertFalse(isPending);
    }
}
```

## 3. モデルの拡張クラスのテスト

拡張モデルクラスをテストする例：

```java
package org.openapitools.extension.model.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.openapitools.extension.model.EnhancedPet;
import org.openapitools.model.Pet;

public class EnhancedPetTest {

    @Test
    public void testIsAdoptable() {
        // 利用可能なペット
        Pet availablePet = new Pet();
        availablePet.setId(1L);
        availablePet.setName("Available Pet");
        availablePet.setStatus(Pet.StatusEnum.AVAILABLE);
        
        EnhancedPet enhancedAvailablePet = new EnhancedPet(availablePet);
        assertTrue(enhancedAvailablePet.isAdoptable());
        
        // 利用不可のペット
        Pet soldPet = new Pet();
        soldPet.setId(2L);
        soldPet.setName("Sold Pet");
        soldPet.setStatus(Pet.StatusEnum.SOLD);
        
        EnhancedPet enhancedSoldPet = new EnhancedPet(soldPet);
        assertFalse(enhancedSoldPet.isAdoptable());
    }
    
    @Test
    public void testCalculateApproximateAgeInHumanYears() {
        Pet pet = new Pet();
        pet.setId(1L);
        pet.setName("Test Pet");
        
        EnhancedPet enhancedPet = new EnhancedPet(pet);
        int humanYears = enhancedPet.calculateApproximateAgeInHumanYears();
        
        // 実装によりますが、例として7を返すと仮定
        assertEquals(7, humanYears);
    }
}
```

## 4. 統合テスト

実際のAPIエンドポイントをテストする統合テストの例：

```java
package org.openapitools.integration.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import org.junit.jupiter.api.Test;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
public class PetApiIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testGetPetById() {
        // 実際のAPIエンドポイントを呼び出す
        ResponseEntity<Pet> response = restTemplate.getForEntity(
                "http://localhost:" + port + "/pet/1", Pet.class);
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1L, response.getBody().getId());
    }

    @Test
    public void testCreatePet() {
        // 新しいペットを作成
        Pet newPet = new Pet();
        newPet.setName("New Test Pet");
        newPet.setStatus(Pet.StatusEnum.AVAILABLE);
        
        ResponseEntity<Pet> createResponse = restTemplate.postForEntity(
                "http://localhost:" + port + "/pet", newPet, Pet.class);
        
        assertEquals(HttpStatus.OK, createResponse.getStatusCode());
        assertNotNull(createResponse.getBody());
        assertNotNull(createResponse.getBody().getId());
        assertEquals("New Test Pet", createResponse.getBody().getName());
    }
}
```

## 5. モック化テクニック

OpenAPI Generatorで生成されたコードをテストする際の便利なモック化テクニックをいくつか紹介します。

### 5.1 DelegateパターンとMockito

Delegateパターンを使用した実装をテストする例：

```java
package org.openapitools.api.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.openapitools.api.PetApiDelegate;
import org.openapitools.api.PetApiDelegateImpl;
import org.openapitools.model.Pet;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;

@SpringBootTest
public class PetApiDelegateImplTest {

    @Mock
    private PetRepository petRepository; // 例：実装で使用されるリポジトリ

    @InjectMocks
    private PetApiDelegateImpl petApiDelegate;

    @Test
    public void testGetPetById() {
        // モックの振る舞いを設定
        Pet mockPet = new Pet();
        mockPet.setId(1L);
        mockPet.setName("Mock Pet");
        mockPet.setStatus(Pet.StatusEnum.AVAILABLE);
        
        when(petRepository.findById(anyLong())).thenReturn(java.util.Optional.of(mockPet));
        
        // テスト対象メソッドを呼び出し
        ResponseEntity<Pet> response = petApiDelegate.getPetById(1L);
        
        // 結果を検証
        assertNotNull(response);
        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("Mock Pet", response.getBody().getName());
    }
}
```

### 5.2 MockMvcによるAPIテスト

MockMvcを使用したより詳細なAPIテスト例：

```java
package org.openapitools.api.test;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.openapitools.api.PetApiController;
import org.openapitools.api.PetApiDelegate;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;

@WebMvcTest(PetApiController.class)
public class PetApiMockMvcTest {

    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private PetApiDelegate petApiDelegate;
    
    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGetPetById() throws Exception {
        // モックの振る舞いを設定
        Pet mockPet = new Pet();
        mockPet.setId(1L);
        mockPet.setName("Mock Pet");
        mockPet.setStatus(Pet.StatusEnum.AVAILABLE);
        
        when(petApiDelegate.getPetById(anyLong())).thenReturn(ResponseEntity.ok(mockPet));
        
        // APIエンドポイントをテスト
        mockMvc.perform(get("/pet/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("Mock Pet"))
                .andExpect(jsonPath("$.status").value("available"));
    }
    
    @Test
    public void testCreatePet() throws Exception {
        // 新しいペットの作成
        Pet newPet = new Pet();
        newPet.setName("New Pet");
        newPet.setStatus(Pet.StatusEnum.AVAILABLE);
        
        Pet createdPet = new Pet();
        createdPet.setId(99L);
        createdPet.setName("New Pet");
        createdPet.setStatus(Pet.StatusEnum.AVAILABLE);
        
        when(petApiDelegate.addPet(newPet)).thenReturn(ResponseEntity.ok(createdPet));
        
        // APIエンドポイントをテスト
        mockMvc.perform(post("/pet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(newPet)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(99))
                .andExpect(jsonPath("$.name").value("New Pet"));
    }
}
```

## 6. バリデーションのテスト

OpenAPIで定義された制約（例：最小値、最大値、文字列長など）をテストする方法を説明します。

### 6.1 Bean Validationによるモデルのテスト

OpenAPI Generatorで生成されたモデルクラス（例：Pet.java）には`@Min`、`@Max`、`@Size`などのJava Bean Validationアノテーションが付与されています。これらのバリデーションをテストするには：

```java
package org.openapitools.model.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.Set;

import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorFactory;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.openapitools.model.Pet;

public class PetValidationTest {

    private Validator validator;

    @BeforeEach
    public void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    public void testIdValidation() {
        // 正常値（境界値）のテスト
        Pet validPet = new Pet("Valid Pet", Arrays.asList("https://example.com/photo.jpg"));
        validPet.setId(1L); // 最小値
        Set<ConstraintViolation<Pet>> violations = validator.validate(validPet);
        assertTrue(violations.isEmpty());

        validPet.setId(100000L); // 最大値
        violations = validator.validate(validPet);
        assertTrue(violations.isEmpty());

        // 範囲外の値（小さすぎる）のテスト
        Pet invalidPet = new Pet("Invalid Pet", Arrays.asList("https://example.com/photo.jpg"));
        invalidPet.setId(0L); // 最小値未満
        violations = validator.validate(invalidPet);
        assertEquals(1, violations.size());
        assertTrue(violations.iterator().next().getMessage().contains("1"));

        // 範囲外の値（大きすぎる）のテスト
        invalidPet.setId(100001L); // 最大値超過
        violations = validator.validate(invalidPet);
        assertEquals(1, violations.size());
        assertTrue(violations.iterator().next().getMessage().contains("100000"));
    }

    @Test
    public void testNameValidation() {
        // 最小長のテスト
        Pet validPet = new Pet("A", Arrays.asList("https://example.com/photo.jpg")); // 1文字（最小）
        Set<ConstraintViolation<Pet>> violations = validator.validate(validPet);
        assertTrue(violations.isEmpty());

        // 最大長のテスト
        String maxLengthName = "A".repeat(100); // 100文字（最大）
        validPet.setName(maxLengthName);
        violations = validator.validate(validPet);
        assertTrue(violations.isEmpty());

        // nullのテスト（必須項目）
        Pet invalidPet = new Pet(null, Arrays.asList("https://example.com/photo.jpg"));
        violations = validator.validate(invalidPet);
        assertEquals(1, violations.size());
        assertTrue(violations.iterator().next().getMessage().contains("null"));

        // 長すぎる名前のテスト
        String tooLongName = "A".repeat(101); // 101文字（最大超過）
        validPet.setName(tooLongName);
        violations = validator.validate(validPet);
        assertEquals(1, violations.size());
        assertTrue(violations.iterator().next().getMessage().contains("100"));
    }

    @Test
    public void testPhotoUrlsValidation() {
        // 必須項目のテスト
        Pet validPet = new Pet("Test Pet", Arrays.asList("https://example.com/photo.jpg"));
        Set<ConstraintViolation<Pet>> violations = validator.validate(validPet);
        assertTrue(violations.isEmpty());

        // nullのテスト（必須項目）
        Pet invalidPet = new Pet("Test Pet", null);
        violations = validator.validate(invalidPet);
        assertEquals(1, violations.size());
    }
}
```

### 6.2 コントローラーのエンドポイントでのバリデーションテスト

API呼び出しを通じてバリデーションをテストする例：

```java
package org.openapitools.api.test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Arrays;

import org.junit.jupiter.api.Test;
import org.openapitools.api.PetApiController;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;

@WebMvcTest(PetApiController.class)
public class PetApiValidationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testInvalidPetId() throws Exception {
        // idが範囲外のペット
        Pet invalidPet = new Pet("Invalid Pet", Arrays.asList("https://example.com/photo.jpg"));
        invalidPet.setId(0L); // 最小値（1）未満
        
        mockMvc.perform(post("/pet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidPet)))
                .andExpect(status().isBadRequest()); // 400 Bad Request を期待
    }

    @Test
    public void testInvalidPetName() throws Exception {
        // 名前が長すぎるペット
        String tooLongName = "A".repeat(101); // 101文字（最大は100文字）
        Pet invalidPet = new Pet(tooLongName, Arrays.asList("https://example.com/photo.jpg"));
        
        mockMvc.perform(post("/pet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidPet)))
                .andExpect(status().isBadRequest()); // 400 Bad Request を期待
    }

    @Test
    public void testValidPet() throws Exception {
        // 正常なペット
        Pet validPet = new Pet("Valid Pet", Arrays.asList("https://example.com/photo.jpg"));
        validPet.setId(100L); // 範囲内
        
        mockMvc.perform(post("/pet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(validPet)))
                .andExpect(status().isOk()); // 200 OK を期待
    }
}
```

### 6.3 バリデーションエラー応答の詳細なテスト

Spring Boot のデフォルトの例外ハンドラーは、バリデーションエラーを適切なエラーメッセージとともに返します。これらのレスポンスを詳細にテストする例：

```java
package org.openapitools.api.test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Arrays;

import org.junit.jupiter.api.Test;
import org.openapitools.api.PetApiController;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;

@WebMvcTest(PetApiController.class)
public class PetApiValidationErrorResponseTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testPetWithMultipleValidationErrors() throws Exception {
        // 複数のバリデーションエラーを持つペット
        Pet invalidPet = new Pet("", null); // 名前が空、photoUrlsがnull
        invalidPet.setId(0L);              // id範囲外
        
        mockMvc.perform(post("/pet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidPet)))
                .andExpect(status().isBadRequest())
                // エラーレスポンスの構造を検証
                .andExpect(jsonPath("$.errors").isArray())
                .andExpect(jsonPath("$.errors[?(@.field == 'id')]").exists())
                .andExpect(jsonPath("$.errors[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.errors[?(@.field == 'photoUrls')]").exists());
    }

    @Test
    public void testValidationErrorMessages() throws Exception {
        // エラーメッセージの内容を検証
        String tooLongName = "A".repeat(101);
        Pet invalidPet = new Pet(tooLongName, Arrays.asList("https://example.com/photo.jpg"));
        
        mockMvc.perform(post("/pet")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidPet)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors[0].field").value("name"))
                .andExpect(jsonPath("$.errors[0].message").value(message -> message.contains("100")));
    }
}
```

### 6.4 統合テストでのバリデーション検証

統合テスト環境でバリデーションを検証する例：

```java
package org.openapitools.integration.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.openapitools.model.Pet;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
public class PetApiValidationIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testPetValidationErrors() {
        // 無効なペットの作成
        Pet invalidPet = new Pet("", Arrays.asList("https://example.com/photo.jpg")); // 名前が空
        invalidPet.setId(0L); // ID範囲外
        
        ResponseEntity<Map> response = restTemplate.postForEntity(
                "http://localhost:" + port + "/pet", invalidPet, Map.class);
        
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        Map<String, Object> responseBody = response.getBody();
        assertTrue(responseBody.containsKey("errors"));
    }

    @Test
    public void testValidPetAccepted() {
        // 有効なペット
        Pet validPet = new Pet("Valid Pet", Arrays.asList("https://example.com/photo.jpg"));
        validPet.setId(100L);
        
        ResponseEntity<Pet> response = restTemplate.postForEntity(
                "http://localhost:" + port + "/pet", validPet, Pet.class);
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("Valid Pet", response.getBody().getName());
        assertEquals(100L, response.getBody().getId());
    }
}
```

### 6.5 バリデーションのカスタマイズとテスト

拡張クラスでバリデーションを追加・カスタマイズした場合のテスト例：

```java
package org.openapitools.extension.model;

import java.util.List;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.Pattern;

import org.openapitools.model.Pet;

// Petモデルを拡張し、追加バリデーションを行うクラス
public class EnhancedPetWithValidation {
    
    private final Pet originalPet;
    
    @NotEmpty(message = "ペットの名前には少なくとも1つのアルファベットが必要です")
    @Pattern(regexp = ".*[a-zA-Z]+.*", message = "ペットの名前には少なくとも1つのアルファベットが必要です")
    private String enhancedName;
    
    public EnhancedPetWithValidation(Pet pet) {
        this.originalPet = pet;
        this.enhancedName = pet.getName();
    }
    
    // 追加バリデーション付きのgetterとsetter
    public String getEnhancedName() {
        return enhancedName;
    }
    
    public void setEnhancedName(String enhancedName) {
        this.enhancedName = enhancedName;
        originalPet.setName(enhancedName);
    }
    
    // オリジナルのPetへのアクセス
    public Pet getOriginalPet() {
        return originalPet;
    }
}
```

このカスタムバリデーションをテストする例：

```java
package org.openapitools.extension.model.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.Set;

import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorFactory;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.openapitools.extension.model.EnhancedPetWithValidation;
import org.openapitools.model.Pet;

public class EnhancedPetValidationTest {

    private Validator validator;

    @BeforeEach
    public void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    public void testEnhancedNameValidation() {
        // 有効な名前（アルファベットを含む）
        Pet pet = new Pet("ValidName123", Arrays.asList("https://example.com/photo.jpg"));
        EnhancedPetWithValidation enhancedPet = new EnhancedPetWithValidation(pet);
        
        Set<ConstraintViolation<EnhancedPetWithValidation>> violations = validator.validate(enhancedPet);
        assertTrue(violations.isEmpty());
        
        // 無効な名前（数字のみ）
        enhancedPet.setEnhancedName("12345");
        violations = validator.validate(enhancedPet);
        assertEquals(1, violations.size());
        assertTrue(violations.iterator().next().getMessage().contains("アルファベット"));
        
        // 無効な名前（空文字）
        enhancedPet.setEnhancedName("");
        violations = validator.validate(enhancedPet);
        assertEquals(2, violations.size()); // NotEmpty と Pattern の両方に違反
    }
}
```

## テスト実行のベストプラクティス

1. **テスト用のアプリケーション設定**：テスト環境用の設定を用意する
   ```java
   @TestConfiguration
   public class TestConfig {
       // テスト用のビーンやモックなど
   }
   ```

2. **データベースのモック**：テストデータベースやインメモリデータベースを使用する
   ```java
   @SpringBootTest(properties = {
       "spring.datasource.url=jdbc:h2:mem:testdb",
       "spring.datasource.driver-class-name=org.h2.Driver"
   })
   ```

3. **CI/CD環境での自動テスト実行**：テストを自動化パイプラインに組み込む
   ```xml
   <!-- pom.xml -->
   <build>
       <plugins>
           <plugin>
               <groupId>org.apache.maven.plugins</groupId>
               <artifactId>maven-surefire-plugin</artifactId>
               <version>3.0.0-M5</version>
           </plugin>
       </plugins>
   </build>
   ```

## 開発ワークフロー

1. OpenAPI仕様を更新する
2. OpenAPI Generatorでコードを再生成する
3. 必要に応じて拡張クラスを更新する
4. 各層（コントローラー、サービス、モデル）のテストを追加・更新する
5. 統合テストを実行して全体の動作を確認する

これにより、OpenAPI Generatorの自動生成コードを安全に活用しながら、継続的な開発とテストが可能になります。