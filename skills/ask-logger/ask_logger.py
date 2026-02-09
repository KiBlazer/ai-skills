#!/usr/bin/env python3
"""
Ask Logger - Automatically logs user questions with timestamp and git context
"""

import os
import sys
from datetime import datetime
import subprocess
from pathlib import Path


def get_git_branch():
    """Get current git branch name, returns None if not in a git repo"""
    try:
        # Use shell=True on Windows for better compatibility
        use_shell = sys.platform == 'win32'
        result = subprocess.run(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
            shell=use_shell
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def get_project_name():
    """Get current project folder name"""
    return Path.cwd().name


def ensure_log_directory():
    """Create ask-logs directory if it doesn't exist"""
    log_dir = Path.home() / '.ai' / 'ask-logs'
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir


def get_log_file_path():
    """Get the path to today's log file"""
    log_dir = ensure_log_directory()
    today = datetime.now().strftime('%Y-%m-%d')
    return log_dir / f'{today}.md'


def log_question(question_text):
    """
    Log a question to the daily markdown file
    
    Args:
        question_text: The user's question to log
    """
    try:
        log_file = get_log_file_path()
        timestamp = datetime.now().strftime('%H:%M:%S')
        branch = get_git_branch()
        project = get_project_name()
        
        # Build the log entry
        entry = f"\n**Time:** {timestamp}\n"
        if branch:
            entry += f"**Branch:** {branch}\n"
        entry += f"**Project:** {project}\n"
        entry += f"**Question:** {question_text}\n"
        entry += "\n---\n"
        
        # Append to file
        with open(log_file, 'a', encoding='utf-8') as f:
            # If file is new/empty, add a header
            if log_file.stat().st_size == 0 if log_file.exists() else True:
                header = f"# Questions Log - {datetime.now().strftime('%Y-%m-%d')}\n\n"
                f.write(header)
            f.write(entry)
        
        return True
    except Exception as e:
        # Silent failure - don't interrupt the main workflow
        print(f"[ask-logger] Warning: Failed to log question: {e}", file=sys.stderr)
        return False


def main():
    """Main entry point for the script"""
    if len(sys.argv) < 2:
        print("Usage: ask_logger.py <question_text>", file=sys.stderr)
        sys.exit(1)
    
    question = ' '.join(sys.argv[1:])
    log_question(question)


if __name__ == '__main__':
    main()
