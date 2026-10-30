"""Read-only WSGI API for authenticated reward balances and transactions.

Only identities configured in REWARD_API_TOKENS_JSON can read their own ledger.
This is an integration scaffold, not a production identity provider.
"""
import json
import os
from urllib.parse import unquote

from reward_ledger import RewardLedger
from auth import development_token_verifier, reject_all_tokens


def create_app(ledger, tokens=None, *, authenticate=None):
    if tokens is not None and authenticate is not None:
        raise ValueError("Choose one authentication implementation")
    verifier = authenticate if authenticate is not None else (
        development_token_verifier(tokens) if tokens is not None
        else reject_all_tokens
    )
    def app(environ, start_response):
        def reply(code, obj):
            body = json.dumps(obj, separators=(",", ":")).encode("utf-8")
            start_response(code, [
                ("Content-Type", "application/json; charset=utf-8"),
                ("Content-Length", str(len(body))),
                ("Cache-Control", "no-store"),
            ])
            return [body]

        if environ.get("REQUEST_METHOD") == "GET" and environ.get("PATH_INFO") == "/healthz":
            return reply("200 OK", {"status": "ok"})
        if environ.get("REQUEST_METHOD") != "GET":
            return reply("405 Method Not Allowed", {"error": "method_not_allowed"})
        authorization = environ.get("HTTP_AUTHORIZATION", "")
        if not authorization.startswith("Bearer "):
            return reply("401 Unauthorized", {"error": "unauthorized"})
        supplied = authorization[len("Bearer "):]
        try:
            user_id = verifier(supplied)
        except Exception:
            # Identity-provider failures must not grant ledger access.
            user_id = None
        if user_id is None:
            return reply("401 Unauthorized", {"error": "unauthorized"})
        path = environ.get("PATH_INFO", "")
        if path == "/v1/rewards/points":
            return reply("200 OK", ledger.snapshot(user_id))
        prefix = "/v1/rewards/transactions/"
        if path.startswith(prefix):
            transaction_id = unquote(path[len(prefix):])
            if not transaction_id or "/" in transaction_id or ".." in transaction_id:
                return reply("400 Bad Request", {"error": "invalid_transaction_id"})
            result = ledger.status(user_id, transaction_id)
            if result is None:
                return reply("404 Not Found", {"error": "not_found"})
            return reply("200 OK", result)
        return reply("404 Not Found", {"error": "not_found"})

    return app


if __name__ == "__main__":
    from wsgiref.simple_server import make_server

    tokens = json.loads(os.environ.get("REWARD_API_TOKENS_JSON", "{}"))
    if not isinstance(tokens, dict):
        raise SystemExit("REWARD_API_TOKENS_JSON must be a JSON object")
    try:
        verifier = development_token_verifier(tokens)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    ledger = RewardLedger(os.environ.get("REWARD_DATABASE", "rewards.sqlite3"))
    # Container mode may bind all interfaces; Compose must publish on loopback only.
    bind_host = os.environ.get("REWARD_BIND_HOST", "127.0.0.1")
    with make_server(bind_host, int(os.environ.get("PORT", "8765")),
                     create_app(ledger, authenticate=verifier)) as server:
        print(f"Reward ledger API listening locally on {server.server_port}")
        server.serve_forever()
