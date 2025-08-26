// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

use serde::{Deserialize, Serialize};
use validator::{Validate, ValidationError};
use chrono::{DateTime, Utc};

{{range .Models}}
/// {{.Description}}
#[derive(Debug, Clone, Serialize, Deserialize{{if .HasValidation}}, Validate{{end}})]
#[serde(rename_all = "camelCase")]
pub struct {{.Name}} {
    {{range .Fields}}
    {{if .Description}}/// {{.Description}}{{end}}
    {{if .Validation}}{{.ValidationTags}}{{end}}
    {{if .Optional}}#[serde(skip_serializing_if = "Option::is_none")]{{end}}
    pub {{.RustName}}: {{if .Optional}}Option<{{.RustType}}>{{else}}{{.RustType}}{{end}},
    {{end}}
}

{{if .HasImpl}}
impl {{.Name}} {
    /// {{.Name}}の新しいインスタンスを作成
    pub fn new({{.ConstructorParams}}) -> Self {
        Self {
            {{range .Fields}}
            {{.RustName}},
            {{end}}
        }
    }
    
    {{range .Methods}}
    /// {{.Description}}
    pub fn {{.MethodName}}(&{{.SelfParam}}) -> {{.ReturnType}} {
        {{.Body}}
    }
    {{end}}
}
{{end}}
{{end}}

// リクエスト型
{{range .Requests}}
#[derive(Debug, Clone, Deserialize{{if .HasValidation}}, Validate{{end}})]
#[serde(rename_all = "camelCase")]
pub struct {{.Name}} {
    {{range .Fields}}
    {{if .Validation}}{{.ValidationTags}}{{end}}
    {{if .Optional}}#[serde(skip_serializing_if = "Option::is_none")]{{end}}
    pub {{.RustName}}: {{if .Optional}}Option<{{.RustType}}>{{else}}{{.RustType}}{{end}},
    {{end}}
}
{{end}}

// レスポンス型
{{range .Responses}}
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct {{.Name}} {
    {{range .Fields}}
    {{if .Optional}}#[serde(skip_serializing_if = "Option::is_none")]{{end}}
    pub {{.RustName}}: {{if .Optional}}Option<{{.RustType}}>{{else}}{{.RustType}}{{end}},
    {{end}}
}
{{end}}

// クエリパラメータ型
{{range .QueryParams}}
#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct {{.Name}} {
    {{range .Fields}}
    {{if .Optional}}#[serde(skip_serializing_if = "Option::is_none")]{{end}}
    pub {{.RustName}}: {{if .Optional}}Option<{{.RustType}}>{{else}}{{.RustType}}{{end}},
    {{end}}
}
{{end}}