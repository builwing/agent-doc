// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

use axum::{
    extract::{Path, Query, State, Json},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post, put, delete},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tower::ServiceBuilder;
use tower_http::{
    cors::CorsLayer,
    trace::TraceLayer,
    validate_request::ValidateRequestHeaderLayer,
};
use tracing::{info, error, warn};

use crate::{
    models::*,
    services::{{.ServiceModule}},
    error::AppError,
    state::AppState,
};

{{range .Endpoints}}
/// {{.Summary}}
/// {{.Description}}
pub async fn {{.HandlerName}}(
    State(state): State<Arc<AppState>>,
    {{if .HasPathParams}}Path({{.PathParams}}): Path<{{.PathParamsType}}>,{{end}}
    {{if .HasQueryParams}}Query(query): Query<{{.QueryParamsType}}>,{{end}}
    {{if .HasBody}}Json(payload): Json<{{.RequestType}}>,{{end}}
) -> Result<impl IntoResponse, AppError> {
    {{if .RequiresAuth}}
    // TODO: 認証チェックを追加
    {{end}}
    
    {{if .HasValidation}}
    // リクエストデータを検証
    payload.validate()?;
    {{end}}
    
    // サービスメソッドを呼び出し
    let result = {{.ServiceModule}}::{{.ServiceMethod}}(
        &state,
        {{if .HasPathParams}}{{.PathParamsCall}},{{end}}
        {{if .HasQueryParams}}query,{{end}}
        {{if .HasBody}}payload,{{end}}
    ).await?;
    
    {{if .HasLogging}}
    info!("{{.OperationId}} 正常に完了しました");
    {{end}}
    
    Ok((StatusCode::{{.SuccessStatus}}, Json(result)))
}
{{end}}

pub fn create_router(state: Arc<AppState>) -> Router {
    Router::new()
        {{range .Routes}}
        .route("{{.Path}}", {{.Method}}({{.Handler}}))
        {{end}}
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(CorsLayer::permissive())
                {{if .RequiresAuth}}
                .layer(ValidateRequestHeaderLayer::bearer("password"))
                {{end}}
        )
        .with_state(state)
}