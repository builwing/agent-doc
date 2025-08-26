<?php
// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class {{.RequestName}} extends FormRequest
{
    /**
     * ユーザーがこのリクエストを実行する権限があるかを判定します。
     */
    public function authorize(): bool
    {
        // TODO: 認可ロジックを実装
        return true;
    }

    /**
     * リクエストに適用される検証ルールを取得します。
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            {{range .Fields}}
            '{{.Name}}' => [{{range $i, $rule := .Rules}}{{if $i}}, {{end}}'{{$rule}}'{{end}}],
            {{end}}
        ];
    }

    /**
     * バリデーターエラー用のカスタムメッセージを取得します。
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            {{range .Fields}}
            {{range .Messages}}
            '{{.Field}}.{{.Rule}}' => '{{.Message}}',
            {{end}}
            {{end}}
        ];
    }

    /**
     * バリデーターエラー用のカスタム属性を取得します。
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            {{range .Fields}}
            '{{.Name}}' => '{{.Label}}',
            {{end}}
        ];
    }

    /**
     * 検証失敗時の処理を行います。
     *
     * @param Validator $validator
     * @return void
     *
     * @throws HttpResponseException
     */
    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            response()->json([
                'message' => '入力データが無効です。',
                'errors' => $validator->errors()
            ], 422)
        );
    }

    /**
     * 検証用にデータを準備します。
     */
    protected function prepareForValidation(): void
    {
        {{if .HasPreparation}}
        // データ準備ロジックをここに追加
        // 例: $this->merge(['slug' => Str::slug($this->title)]);
        {{end}}
    }
}