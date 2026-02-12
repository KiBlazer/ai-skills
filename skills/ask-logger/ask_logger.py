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
    """Create log directory if it doesn't exist"""
    # Create standard user directory which is usually allowed in sandboxes
    log_dir = os.path.expanduser("~/Documents/ask-logs")
    os.makedirs(log_dir, exist_ok=True)
    return Path(log_dir)


def get_log_file_path():
    """Get the path to today's log file"""
    log_dir = ensure_log_directory()
    today = datetime.now().strftime('%Y-%m-%d')
    return log_dir / f'{today}.md'


def log_question(question_text, session_id=None, status='', type_=''):
    """
    Log a question to the daily markdown file.

    Args:
        question_text: The user's question to log (typically from stdin).
        session_id: Optional session/conversation ID (CLI --session-id=).
        status: Optional status (e.g. pending/resolved/skipped), for later tagging.
        type_: Optional type/tags (e.g. 配置/代码/需求/调试/讨论), for later tagging.
    """
    try:
        log_file = get_log_file_path()
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        branch = get_git_branch()
        project = get_project_name()

        # Build the log entry (fixed order for parsing)
        entry = f"\n**Time:** {timestamp}\n"
        if session_id:
            entry += f"**Session:** {session_id}\n"
        entry += f"**Status:** {status}\n"
        entry += f"**Type:** {type_}\n"
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
        # Enhanced error handling
        import getpass
        current_user = getpass.getuser()
        print(f"[ask-logger] Error: {e}", file=sys.stderr)
        print(f"[ask-logger] Debug: Current User={current_user}, Path={log_file}", file=sys.stderr)
        
        # Try fallback to /tmp
        try:
            tmp_dir = Path("/tmp/ai-ask-logs")
            tmp_dir.mkdir(mode=0o777, parents=True, exist_ok=True)
            fallback_file = tmp_dir / f"{datetime.now().strftime('%Y-%m-%d')}.md"
            
            with open(fallback_file, 'a', encoding='utf-8') as f:
                 f.write(f"\n**[Fallback Log]**\n{entry}")
            print(f"[ask-logger] Success: Logged to fallback location: {fallback_file}", file=sys.stderr)
            return True
        except Exception as fallback_e:
            print(f"[ask-logger] Critical: Fallback also failed: {fallback_e}", file=sys.stderr)
            return False


def _get_session_id():
    """Session ID: CLI --session-id= wins; else generic env ASK_LOGGER_SESSION_ID or AI_SESSION_ID (any tool can set)."""
    for arg in sys.argv[1:]:
        if arg.startswith('--session-id='):
            val = arg.split('=', 1)[1].strip()
            return val if val else None
    raw = os.environ.get('ASK_LOGGER_SESSION_ID') or os.environ.get('AI_SESSION_ID')
    return (raw or '').strip() or None


def main():
    """Main entry point. Question content is read from stdin only (tool-agnostic)."""
    session_id = _get_session_id()

    question = sys.stdin.read()
    if not question.strip():
        print("Usage: pipe question content to stdin, e.g. echo '...' | ask_logger.py [--session-id=UUID]", file=sys.stderr)
        sys.exit(1)

    log_question(question.strip(), session_id=session_id)


if __name__ == '__main__':
    main()
