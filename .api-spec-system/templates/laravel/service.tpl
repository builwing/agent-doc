<?php
// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

namespace App\Services;

use App\Models\{{.ModelClass}};
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;

class {{.ServiceName}}
{
    {{range .Repositories}}
    private {{.RepositoryClass}} ${{.RepositoryProperty}};
    {{end}}

    public function __construct({{range $i, $r := .Repositories}}{{if $i}}, {{end}}{{$r.RepositoryClass}} ${{$r.RepositoryProperty}}{{end}})
    {
        {{range .Repositories}}
        $this->{{.RepositoryProperty}} = ${{.RepositoryProperty}};
        {{end}}
    }

    {{range .Methods}}
    /**
     * {{.Description}}
     *
     * @param array $data
     * @return {{.ReturnType}}
     */
    public function {{.MethodName}}({{.Parameters}}): {{.ReturnType}}
    {
        {{if .UseTransaction}}
        return DB::transaction(function () use ({{.ParameterNames}}) {
        {{end}}
            {{if .UseCache}}
            $cacheKey = '{{.CacheKey}}';
            
            return Cache::remember($cacheKey, {{.CacheTTL}}, function () use ({{.ParameterNames}}) {
            {{end}}
                // ビジネスロジックの実装
                {{.BusinessLogic}}
            {{if .UseCache}}
            });
            {{end}}
        {{if .UseTransaction}}
        });
        {{end}}
    }
    {{end}}

    /**
     * 関連キャッシュを無効化
     *
     * @param string $tag
     * @return void
     */
    protected function invalidateCache(string $tag): void
    {
        Cache::tags([$tag])->flush();
    }

    /**
     * サービスアクティビティをログに記録
     *
     * @param string $action
     * @param array $context
     * @return void
     */
    protected function logActivity(string $action, array $context = []): void
    {
        Log::info("{{.ServiceName}}: {$action}", $context);
    }
}