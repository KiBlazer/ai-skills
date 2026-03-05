import sys
import os
import subprocess

def ensure_env():
    venv_path = "/home/kingbo/.gemini/tmp/kingbo/pdf_lite_env"
    if not os.path.exists(venv_path):
        print(f"Error: Virtual environment not found at {venv_path}")
        print("Please ensure the environment is set up with 'pymupdf4llm' installed.")
        sys.exit(1)
    return os.path.join(venv_path, "bin", "python3")

def convert(input_pdf, output_md=None):
    python_bin = ensure_env()
    if not output_md:
        output_md = input_pdf.rsplit('.', 1)[0] + ".md"
    
    # 构建嵌入式脚本执行转换
    code = f"""
import pymupdf4llm
try:
    md_text = pymupdf4llm.to_markdown('{input_pdf}')
    with open('{output_md}', 'w', encoding='utf-8') as f:
        f.write(md_text)
    print(f'Successfully converted {input_pdf} to {output_md}')
except Exception as e:
    print(f'Error: {{str(e)}}')
    exit(1)
"""
    result = subprocess.run([python_bin, "-c", code], capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 convert.py <input_pdf> [output_md]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    convert(input_file, output_file)
