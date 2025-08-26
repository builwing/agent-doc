<?php
// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{{.ControllerClass}};

/*
|--------------------------------------------------------------------------
| APIルート - {{.ServiceName}}
|--------------------------------------------------------------------------
|
| {{.ServiceName}} サービスのAPIルートです。
| これらのルートはOpenAPI仕様から自動生成されました。
|
*/

Route::prefix('api/{{.ApiVersion}}')->middleware(['api'{{if .RequiresAuth}}, 'auth:sanctum'{{end}}])->group(function () {
    {{range .Endpoints}}
    Route::{{.Method}}('{{.Path}}', [{{$.ControllerClass}}::class, '{{.MethodName}}'])
        ->name('{{.RouteName}}'){{if .Middleware}}
        ->middleware([{{range $i, $m := .Middleware}}{{if $i}}, {{end}}'{{$m}}'{{end}}]){{end}};
    {{end}}
});

// レート制限グループ（オプション）
{{if .HasRateLimiting}}
Route::middleware(['api', 'throttle:api'])->group(function () {
    // レート制限付きルートをここに追加
});
{{end}}