#!/usr/bin/env bash
# 各エージェントにContext7使用指示を追加

AGENTS=("api" "logic" "next" "expo" "infra" "qa" "uiux" "security" "docs")

for agent in "${AGENTS[@]}"; do
    agent_file=".claude/agents/${agent}.md"
    
    if [ -f "$agent_file" ]; then
        # バックアップを作成
        cp "$agent_file" "${agent_file}.bak"
        
        # Context7指示を追加（既存の内容の前に）
        temp_file=$(mktemp)
        
        # YAMLフロントマターを保持
        sed -n '/^---$/,/^---$/p' "$agent_file" > "$temp_file"
        
        # Context7指示を追加
        echo "" >> "$temp_file"
        cat .claude/pm/prompts/context7_template.txt >> "$temp_file"
        echo "" >> "$temp_file"
        echo "---" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # 元のコンテンツ（フロントマター以降）を追加
        sed '1,/^---$/d' "$agent_file" | sed '1,/^---$/d' >> "$temp_file"
        
        # ファイルを置き換え
        mv "$temp_file" "$agent_file"
        
        echo "✅ ${agent}エージェントにContext7指示を追加しました"
    fi
done
