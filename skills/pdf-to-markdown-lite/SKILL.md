---
name: pdf-to-markdown-lite
description: 轻量级 PDF 转 Markdown 工具，使用 pymupdf4llm 方案，无需 GPU，擅长保留表格和文档布局。适用于将演示文档、报告等 PDF 1:1 还原为 Markdown 格式。
---

# PDF-to-Markdown-Lite

此 Skill 使用轻量级的 `pymupdf4llm` 库将 PDF 文件转换为 Markdown，旨在平衡性能与排版还原度。

## 适用场景
- 需要将 PDF 转为 Markdown 以便编辑或导入知识库。
- PDF 包含表格，且希望表格在 Markdown 中以管道符格式 (`|---|---|`) 保留。
- 环境受限（无 GPU，存储空间有限），无法运行大型 AI 解析模型。

## 依赖要求
- 虚拟环境路径：`/home/kingbo/.gemini/tmp/kingbo/pdf_lite_env`
- 依赖包：`pymupdf4llm`

## 使用方法

### 单个文件转换
使用内置脚本执行转换：
```bash
python3 scripts/convert.py path/to/input.pdf [path/to/output.md]
```

### 批量转换
Gemini CLI 可以自动发现目录下所有 PDF 并循环调用脚本：
1. 识别目标目录中的所有 `.pdf` 文件。
2. 调用 `scripts/convert.py` 进行转换。

## 注意事项
- 该方案对纯图片生成的 PDF（扫描件）效果有限，主要针对原生电子版 PDF。
- 转换后的图片不会被提取，仅保留文本和表格结构。
