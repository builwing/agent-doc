// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

syntax = "v1"

info(
    title: "{{.Info.Title}}"
    desc: "{{.Info.Description}}"
    author: "api-spec-system"
    email: "admin@example.com"
    version: "{{.Info.Version}}"
)

{{if .Security}}
@server(
    jwt: Auth
    group: {{.Group}}
    prefix: {{.Prefix}}
    middleware: {{.Middleware}}
)
{{else}}
@server(
    group: {{.Group}}
    prefix: {{.Prefix}}
)
{{end}}

// リクエスト/レスポンス型
{{range .Schemas}}
type {{.Name}} {
    {{range .Properties}}
    {{.Name}} {{.Type}} `json:"{{.JsonTag}}"{{if .Validate}} validate:"{{.Validate}}"{{end}}`
    {{end}}
}
{{end}}

// サービス定義
service {{.ServiceName}} {
    {{range .Endpoints}}
    @doc "{{.Summary}}"
    @handler {{.Handler}}
    {{.Method}} {{.Path}} ({{.Request}}) returns ({{.Response}})
    {{end}}
}