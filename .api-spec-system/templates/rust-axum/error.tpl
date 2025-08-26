// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use std::fmt;
use tracing::error;

/// Axum用のIntoResponseを実装したアプリケーションエラー型
#[derive(Debug)]
pub enum AppError {
    /// データベースエラー
    Database(sqlx::Error),
    
    /// 検証エラー
    Validation(String),
    
    /// Not Foundエラー
    NotFound(String),
    
    /// 認証エラー
    Unauthorized,
    
    /// アクセス禁止
    Forbidden,
    
    /// 不正なリクエスト
    BadRequest(String),
    
    /// サーバー内部エラー
    Internal(String),
    
    /// 競合エラー
    Conflict(String),
    
    /// レート制限超過
    RateLimitExceeded,
    
    /// サービス利用不可
    ServiceUnavailable,
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::Database(e) => write!(f, "Database error: {}", e),
            AppError::Validation(msg) => write!(f, "Validation error: {}", msg),
            AppError::NotFound(msg) => write!(f, "Not found: {}", msg),
            AppError::Unauthorized => write!(f, "Unauthorized"),
            AppError::Forbidden => write!(f, "Forbidden"),
            AppError::BadRequest(msg) => write!(f, "Bad request: {}", msg),
            AppError::Internal(msg) => write!(f, "Internal error: {}", msg),
            AppError::Conflict(msg) => write!(f, "Conflict: {}", msg),
            AppError::RateLimitExceeded => write!(f, "Rate limit exceeded"),
            AppError::ServiceUnavailable => write!(f, "Service unavailable"),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_message) = match self {
            AppError::Database(ref e) => {
                error!("データベースエラー: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "データベースエラーが発生しました")
            }
            AppError::Validation(ref msg) => {
                (StatusCode::BAD_REQUEST, msg.as_str())
            }
            AppError::NotFound(ref msg) => {
                (StatusCode::NOT_FOUND, msg.as_str())
            }
            AppError::Unauthorized => {
                (StatusCode::UNAUTHORIZED, "認証が必要です")
            }
            AppError::Forbidden => {
                (StatusCode::FORBIDDEN, "アクセスが禁止されています")
            }
            AppError::BadRequest(ref msg) => {
                (StatusCode::BAD_REQUEST, msg.as_str())
            }
            AppError::Internal(ref msg) => {
                error!("内部エラー: {}", msg);
                (StatusCode::INTERNAL_SERVER_ERROR, "サーバー内部エラー")
            }
            AppError::Conflict(ref msg) => {
                (StatusCode::CONFLICT, msg.as_str())
            }
            AppError::RateLimitExceeded => {
                (StatusCode::TOO_MANY_REQUESTS, "レート制限を超過しました")
            }
            AppError::ServiceUnavailable => {
                (StatusCode::SERVICE_UNAVAILABLE, "サービスが利用できません")
            }
        };

        let body = Json(json!({
            "error": {
                "message": error_message,
                "status": status.as_u16(),
            }
        }));

        (status, body).into_response()
    }
}

// 一般的なエラー型のFrom実装
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        AppError::Database(err)
    }
}

impl From<validator::ValidationErrors> for AppError {
    fn from(err: validator::ValidationErrors) -> Self {
        AppError::Validation(format!("検証エラー: {}", err))
    }
}

{{if .HasCustomErrors}}
{{range .CustomErrors}}
/// {{.Description}}
#[derive(Debug)]
pub struct {{.Name}} {
    pub message: String,
}

impl From<{{.Name}}> for AppError {
    fn from(err: {{.Name}}) -> Self {
        AppError::{{.ErrorType}}(err.message)
    }
}
{{end}}
{{end}}

/// AppError用のResult型エイリアス
pub type Result<T> = std::result::Result<T, AppError>;