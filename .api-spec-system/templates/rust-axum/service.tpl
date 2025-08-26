// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

use std::sync::Arc;
use axum::http::StatusCode;
use sqlx::{PgPool, postgres::PgPoolOptions};
use tracing::{info, error, warn};

use crate::{
    models::*,
    error::AppError,
    state::AppState,
};

{{range .Services}}
/// {{.Description}}
pub struct {{.Name}} {
    pool: PgPool,
}

impl {{.Name}} {
    /// {{.Name}}の新しいインスタンスを作成
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
    
    {{range .Methods}}
    /// {{.Description}}
    pub async fn {{.MethodName}}(
        &self,
        {{.Parameters}}
    ) -> Result<{{.ReturnType}}, AppError> {
        {{if .UseTransaction}}
        let mut tx = self.pool.begin().await?;
        {{end}}
        
        {{.BusinessLogic}}
        
        {{if .UseTransaction}}
        tx.commit().await?;
        {{end}}
        
        Ok(result)
    }
    {{end}}
}
{{end}}

// ハンドラー用サービス関数
{{range .HandlerFunctions}}
/// {{.Description}}
pub async fn {{.Name}}(
    state: &Arc<AppState>,
    {{.Parameters}}
) -> Result<{{.ReturnType}}, AppError> {
    {{if .UseCache}}
    // 最初にキャッシュを確認
    if let Some(cached) = state.cache.get("{{.CacheKey}}").await {
        return Ok(cached);
    }
    {{end}}
    
    // ビジネスロジックの実装
    {{.Implementation}}
    
    {{if .UseCache}}
    // キャッシュに保存
    state.cache.set("{{.CacheKey}}", &result, {{.CacheTTL}}).await;
    {{end}}
    
    {{if .HasMetrics}}
    // メトリクスを更新
    state.metrics.{{.MetricName}}.inc();
    {{end}}
    
    Ok(result)
}
{{end}}