// api-spec-systemによって生成されたコード。編集しないでください。
package handler

import (
    "net/http"

    "github.com/zeromicro/go-zero/rest/httpx"
    "{{.ProjectPath}}/internal/logic"
    "{{.ProjectPath}}/internal/svc"
    "{{.ProjectPath}}/internal/types"
)

// {{.HandlerName}} は {{.Method}} {{.Path}} を処理します
func {{.HandlerName}}(svcCtx *svc.ServiceContext) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        {{if .HasRequest}}
        var req types.{{.RequestType}}
        if err := httpx.Parse(r, &req); err != nil {
            httpx.ErrorCtx(r.Context(), w, err)
            return
        }

        {{if .HasValidation}}
        if err := req.Validate(); err != nil {
            httpx.ErrorCtx(r.Context(), w, err)
            return
        }
        {{end}}
        {{end}}

        l := logic.New{{.LogicName}}(r.Context(), svcCtx)
        {{if .HasRequest}}
        resp, err := l.{{.LogicMethod}}(&req)
        {{else}}
        resp, err := l.{{.LogicMethod}}()
        {{end}}
        if err != nil {
            httpx.ErrorCtx(r.Context(), w, err)
        } else {
            httpx.OkJsonCtx(r.Context(), w, resp)
        }
    }
}