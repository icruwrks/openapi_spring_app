pipeline {
    agent any
      tools {
        maven '3.9.10' // Jenkinsで設定されているMavenツール名
        jdk 'JDK17_Default' // Jenkinsで設定されているJDKツール名
    }
      environment {
        // プロジェクト固有の環境変数
        PROJECT_NAME = 'openapi-spring-app'
        MAVEN_OPTS = '-Xmx1024m'
        JAVA_HOME = tool('JDK17_Default')
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
    }
    
    options {
        // ビルド履歴を最大10個まで保持
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // タイムアウトを30分に設定
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'ソースコードをチェックアウト中...'
                checkout scm
            }
        }
        
        stage('Environment Info') {
            steps {
                echo 'ビルド環境情報を表示中...'
                script {
                    sh '''
                        echo "Java Version:"
                        java -version
                        echo "Maven Version:"
                        mvn -version
                        echo "Working Directory:"
                        pwd
                        echo "Directory Contents:"
                        ls -la
                    '''
                }
            }
        }
        
        stage('Validate') {
            steps {
                echo 'プロジェクト構造を検証中...'
                dir('spring-app') {
                    sh '''
                        echo "pom.xmlの存在確認:"
                        ls -la pom.xml
                        echo "Maven プロジェクトの検証:"
                        mvn validate
                    '''
                }
            }
        }
        
        stage('Clean') {
            steps {
                echo 'プロジェクトをクリーン中...'
                dir('spring-app') {
                    sh 'mvn clean'
                }
            }
        }
        
        stage('Compile') {
            steps {
                echo 'ソースコードをコンパイル中...'
                dir('spring-app') {
                    sh 'mvn compile'
                }
            }
        }
        
        stage('Test') {
            steps {
                echo 'ユニットテストを実行中...'
                dir('spring-app') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    // テスト結果を公開
                    dir('spring-app') {
                        publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: 'target/site/jacoco',
                            reportFiles: 'index.html',
                            reportName: 'JaCoCo Coverage Report'
                        ])
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'アプリケーションをパッケージ中...'
                dir('spring-app') {
                    sh 'mvn package -DskipTests'
                }
            }
        }
        
        stage('Verify') {
            steps {
                echo 'パッケージを検証中...'
                dir('spring-app') {
                    sh '''
                        echo "生成されたJARファイル:"
                        ls -la target/*.jar
                        echo "JARファイルの内容確認:"
                        jar tf target/openapi-spring-*.jar | head -20
                    '''
                }
            }
        }
        
        stage('Archive Artifacts') {
            steps {
                echo 'アーティファクトをアーカイブ中...'
                dir('spring-app') {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                    archiveArtifacts artifacts: 'target/surefire-reports/**', allowEmptyArchive: true
                }
            }
        }
        
        stage('SonarQube Analysis') {
            when {
                anyOf {
                    branch 'main'
                    //branch 'develop'
                    changeRequest()
                }
            }
            steps {
                echo 'SonarQube解析を実行中...'
                dir('spring-app') {
                    script {
                        def sonarScanner = tool 'SonarQubeScanner'
                        withSonarQubeEnv('SonarQube') {
                            sh """
                                ${sonarScanner}/bin/sonar-scanner \
                                -Dsonar.projectKey=${PROJECT_NAME} \
                                -Dsonar.projectName=${PROJECT_NAME} \
                                -Dsonar.sources=src/main/java \
                                -Dsonar.tests=src/test/java \
                                -Dsonar.java.binaries=target/classes \
                                -Dsonar.java.test.binaries=target/test-classes \
                                -Dsonar.junit.reportPaths=target/surefire-reports
                            """
                        }
                    }
                }
            }
        }
        
        // stage('Deploy to Dev') {
        //     when {
        //         branch 'develop'
        //     }
        //     steps {
        //         echo '開発環境にデプロイ中...'
        //         dir('spring-app') {
        //             script {
        //                 // 開発環境へのデプロイロジックをここに追加
        //                 sh '''
        //                     echo "開発環境デプロイ準備中..."
        //                     # 例: Docker イメージの作成
        //                     # docker build -t openapi-spring-app:dev .
        //                     # docker push your-registry/openapi-spring-app:dev
                            
        //                     # 例: Kubernetes デプロイメント
        //                     # kubectl apply -f k8s/dev-deployment.yaml
                            
        //                     echo "開発環境デプロイ完了"
        //                 '''
        //             }
        //         }
        //     }
        // }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                echo 'ステージング環境にデプロイ中...'
                dir('spring-app') {
                    script {
                        // ステージング環境へのデプロイロジックをここに追加
                        sh '''
                            echo "ステージング環境デプロイ準備中..."
                            # ステージング環境固有のデプロイ処理
                            echo "ステージング環境デプロイ完了"
                        '''
                    }
                }
            }
        }
        
        // stage('Integration Tests') {
        //     when {
        //         anyOf {
        //             branch 'main'
        //             branch 'develop'
        //         }
        //     }
        //     steps {
        //         echo '結合テストを実行中...'
        //         dir('spring-app') {
        //             sh '''
        //                 echo "結合テスト準備中..."
        //                 # 結合テストのロジックをここに追加
        //                 # mvn verify -Pintegration-tests
        //                 echo "結合テスト完了"
        //             '''
        //         }
        //     }
        // }
    }
    
    post {
        always {
            echo 'パイプライン完了後の処理を実行中...'
            // ワークスペースのクリーンアップ
            cleanWs()
        }
        
        success {
            echo 'ビルドが成功しました！'
            // 成功時の通知（例: Slack、Email）
            script {
                if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'develop') {
                    // slackSend channel: '#build-notifications',
                    //           color: 'good',
                    //           message: ":white_check_mark: ${PROJECT_NAME} - Build #${env.BUILD_NUMBER} succeeded on ${env.BRANCH_NAME}"
                }
            }
        }
        
        failure {
            echo 'ビルドが失敗しました。'
            // 失敗時の通知
            // script {
            //     // slackSend channel: '#build-notifications',
            //     //           color: 'danger',
            //     //           message: ":x: ${PROJECT_NAME} - Build #${env.BUILD_NUMBER} failed on ${env.BRANCH_NAME}"
                
            //     // emailext (
            //     //     subject: "Build Failed: ${PROJECT_NAME} - ${env.BRANCH_NAME}",
            //     //     body: "Build #${env.BUILD_NUMBER} failed. Please check the console output for details.",
            //     //     to: "${env.CHANGE_AUTHOR_EMAIL}"
            //     // )
            // }
        }
        
        unstable {
            echo 'ビルドは不安定です。'
            // 不安定時の通知
        }
        
        changed {
            echo 'ビルド状態が変更されました。'
            // 状態変更時の通知
        }
    }
}
