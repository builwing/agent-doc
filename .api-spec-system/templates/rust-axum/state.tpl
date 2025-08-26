// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

use std::sync::Arc;
use sqlx::PgPool;
use tokio::sync::RwLock;
use std::collections::HashMap;
use std::time::{Duration, Instant};

/// すべてのハンドラーで共有されるアプリケーション状態
#[derive(Clone)]
pub struct AppState {
    /// データベース接続プール
    pub pool: PgPool,
    
    /// インメモリキャッシュ
    pub cache: Arc<Cache>,
    
    /// アプリケーションメトリクス
    pub metrics: Arc<Metrics>,
    
    {{if .HasRedis}}
    /// Redisクライアント
    pub redis: redis::Client,
    {{end}}
    
    {{if .HasS3}}
    /// S3クライアント
    pub s3: aws_sdk_s3::Client,
    {{end}}
    
    {{if .HasCustomServices}}
    {{range .CustomServices}}
    /// {{.Description}}
    pub {{.FieldName}}: Arc<{{.ServiceType}}>,
    {{end}}
    {{end}}
}

impl AppState {
    /// 新しいアプリケーション状態を作成
    pub async fn new(database_url: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let pool = PgPool::connect(database_url).await?;
        
        Ok(Self {
            pool,
            cache: Arc::new(Cache::new()),
            metrics: Arc::new(Metrics::new()),
            {{if .HasRedis}}
            redis: redis::Client::open("redis://127.0.0.1/")?
            {{end}}
            {{if .HasS3}}
            s3: {
                let config = aws_config::load_from_env().await;
                aws_sdk_s3::Client::new(&config)
            },
            {{end}}
            {{if .HasCustomServices}}
            {{range .CustomServices}}
            {{.FieldName}}: Arc::new({{.ServiceType}}::new()),
            {{end}}
            {{end}}
        })
    }
}

/// シンプルなインメモリキャッシュ実装
pub struct Cache {
    store: RwLock<HashMap<String, CacheEntry>>,
}

struct CacheEntry {
    value: Vec<u8>,
    expires_at: Instant,
}

impl Cache {
    pub fn new() -> Self {
        Self {
            store: RwLock::new(HashMap::new()),
        }
    }

    /// キャッシュから値を取得
    pub async fn get(&self, key: &str) -> Option<Vec<u8>> {
        let store = self.store.read().await;
        
        if let Some(entry) = store.get(key) {
            if entry.expires_at > Instant::now() {
                return Some(entry.value.clone());
            }
        }
        
        None
    }

    /// TTL付きでキャッシュに値を設定
    pub async fn set(&self, key: String, value: Vec<u8>, ttl_seconds: u64) {
        let mut store = self.store.write().await;
        
        store.insert(key, CacheEntry {
            value,
            expires_at: Instant::now() + Duration::from_secs(ttl_seconds),
        });
    }

    /// キャッシュから値を削除
    pub async fn delete(&self, key: &str) {
        let mut store = self.store.write().await;
        store.remove(key);
    }

    /// 期限切れエントリをクリア
    pub async fn cleanup(&self) {
        let mut store = self.store.write().await;
        let now = Instant::now();
        
        store.retain(|_, entry| entry.expires_at > now);
    }
}

/// アプリケーションメトリクス
pub struct Metrics {
    {{range .MetricFields}}
    pub {{.Name}}: Arc<RwLock<{{.Type}}>>,
    {{end}}
    pub request_count: Arc<RwLock<u64>>,
    pub error_count: Arc<RwLock<u64>>,
}

impl Metrics {
    pub fn new() -> Self {
        Self {
            {{range .MetricFields}}
            {{.Name}}: Arc::new(RwLock::new({{.InitValue}})),
            {{end}}
            request_count: Arc::new(RwLock::new(0)),
            error_count: Arc::new(RwLock::new(0)),
        }
    }

    pub async fn increment_requests(&self) {
        let mut count = self.request_count.write().await;
        *count += 1;
    }

    pub async fn increment_errors(&self) {
        let mut count = self.error_count.write().await;
        *count += 1;
    }

    pub async fn get_stats(&self) -> HashMap<String, u64> {
        let mut stats = HashMap::new();
        
        stats.insert("requests".to_string(), *self.request_count.read().await);
        stats.insert("errors".to_string(), *self.error_count.read().await);
        
        {{range .MetricFields}}
        stats.insert("{{.Name}}".to_string(), *self.{{.Name}}.read().await as u64);
        {{end}}
        
        stats
    }
}