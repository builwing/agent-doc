<?php
// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\{{.RequestClass}};
use App\Services\{{.ServiceClass}};
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class {{.ControllerName}} extends Controller
{
    private {{.ServiceClass}} $service;

    public function __construct({{.ServiceClass}} $service)
    {
        $this->service = $service;
    }

    {{range .Endpoints}}
    /**
     * {{.Summary}}
     * {{.Description}}
     *
     * @param {{if .HasRequest}}{{.RequestClass}} $request{{else}}Request $request{{end}}
     * @return JsonResponse
     */
    public function {{.MethodName}}({{if .HasRequest}}{{.RequestClass}} $request{{else}}Request $request{{end}}{{if .HasPathParams}}, {{.PathParams}}{{end}}): JsonResponse
    {
        try {
            {{if .HasValidation}}
            $validated = $request->validated();
            {{end}}
            
            $result = $this->service->{{.ServiceMethod}}({{if .HasRequest}}$validated{{end}}{{if .HasPathParams}}, {{.PathParamsCall}}{{end}});
            
            return response()->json($result, {{.SuccessStatus}});
        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::warning('{{.OperationId}}の検証が失敗しました', ['errors' => $e->errors()]);
            return response()->json([
                'message' => '検証に失敗しました',
                'errors' => $e->errors()
            ], 422);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            Log::warning('{{.OperationId}}のリソースが見つかりません', ['message' => $e->getMessage()]);
            return response()->json([
                'message' => 'リソースが見つかりません'
            ], 404);
        } catch (\Exception $e) {
            Log::error('{{.OperationId}}でエラーが発生しました', ['error' => $e->getMessage()]);
            return response()->json([
                'message' => 'エラーが発生しました',
                'error' => config('app.debug') ? $e->getMessage() : 'サーバー内部エラー'
            ], 500);
        }
    }
    {{end}}
}