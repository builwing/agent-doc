// api-spec-systemによって生成されたコード。編集しないでください。
package logic

import (
    "context"

    "{{.ProjectPath}}/internal/svc"
    "{{.ProjectPath}}/internal/types"

    "github.com/zeromicro/go-zero/core/logx"
)

type {{.LogicName}} struct {
    logx.Logger
    ctx    context.Context
    svcCtx *svc.ServiceContext
}

// New{{.LogicName}} は新しい {{.LogicName}} を作成します
func New{{.LogicName}}(ctx context.Context, svcCtx *svc.ServiceContext) *{{.LogicName}} {
    return &{{.LogicName}}{
        Logger: logx.WithContext(ctx),
        ctx:    ctx,
        svcCtx: svcCtx,
    }
}

// {{.LogicMethod}} は {{.Summary}} を処理します
func (l *{{.LogicName}}) {{.LogicMethod}}({{if .HasRequest}}req *types.{{.RequestType}}{{end}}) (*types.{{.ResponseType}}, error) {
    // TODO: ビジネスロジックを実装
    {{if .Cache.Enabled}}
    // キャッシュ設定: TTL={{.Cache.TTL}}秒
    {{end}}

    {{if .HasDatabase}}
    // データベース操作
    {{end}}

    {{if .HasWebSocket}}
    // WebSocket処理
    {{end}}

    return &types.{{.ResponseType}}{
        Code:    0,
        Message: "成功",
        Data:    nil,
    }, nil
}