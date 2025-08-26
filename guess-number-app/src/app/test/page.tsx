export default function TestPage() {
  return (
    <div className="min-h-screen p-8">
      <h1 className="text-4xl font-bold text-primary-600 mb-4">Tailwind CSS テストページ</h1>
      
      <div className="space-y-4">
        <div className="bg-primary-100 p-4 rounded-lg">
          <p className="text-primary-900">プライマリカラーのテスト</p>
        </div>
        
        <div className="bg-success-100 p-4 rounded-lg border-2 border-success-500">
          <p className="text-success-900">サクセスカラーのテスト</p>
        </div>
        
        <button className="bg-primary-600 text-white px-6 py-3 rounded-lg hover:bg-primary-700 transition-colors">
          ボタンのテスト
        </button>
        
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-red-500 text-white p-4 rounded">赤</div>
          <div className="bg-green-500 text-white p-4 rounded">緑</div>
          <div className="bg-blue-500 text-white p-4 rounded">青</div>
        </div>
      </div>
    </div>
  );
}