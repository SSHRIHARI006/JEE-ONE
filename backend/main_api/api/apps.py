import importlib.util
import os
import sys

from django.apps import AppConfig


class ApiConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "api"

    def ready(self):
        # In runserver with autoreload, log only in the serving child process.
        run_main = os.environ.get("RUN_MAIN")
        if run_main == "false":
            return

        try:
            from dotenv import load_dotenv

            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            load_dotenv(dotenv_path=os.path.join(base_dir, ".env"), override=False)

            anthropic_installed = bool(importlib.util.find_spec("anthropic"))
            api_key_present = bool((os.getenv("ANTHROPIC_API_KEY") or "").strip())
            model = (os.getenv("ANTHROPIC_MODEL") or "claude-3-haiku-20240307").strip()
            fast_model = (os.getenv("ANTHROPIC_FAST_MODEL") or "claude-3-haiku-20240307").strip()
            python_path = sys.executable

            import logging

            logger = logging.getLogger("jivan")
            logger.info(
                "[STARTUP GUARD] python=%s | anthropic_sdk=%s | api_key=%s | model=%s | fast_model=%s",
                python_path,
                "present" if anthropic_installed else "missing",
                "present" if api_key_present else "missing",
                model,
                fast_model,
            )
        except Exception as exc:
            # Keep startup resilient even if diagnostics fail.
            print(f"[STARTUP GUARD] failed: {exc}")
