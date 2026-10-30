"""Authentication adapters for the reward read API.

Production identity is supplied by the host's verified session service.
This module does not issue, sign, or validate production access tokens.
"""
from __future__ import annotations

import hmac
from typing import Callable, Mapping, Optional

TokenVerifier = Callable[[str], Optional[str]]


def development_token_verifier(tokens: Mapping[str, str]) -> TokenVerifier:
    """For local development only. Secrets must never ship with iOS clients."""
    clean = dict(tokens)
    if not clean or any(
        not isinstance(token, str) or len(token) < 32
        or not isinstance(user, str) or not user
        for token, user in clean.items()
    ):
        raise ValueError("Development tokens require 32+ characters and user IDs")

    def verify(token: str) -> Optional[str]:
        if not isinstance(token, str) or not token:
            return None
        matched_user = None
        for expected, user in clean.items():
            if hmac.compare_digest(expected, token):
                matched_user = user
        return matched_user

    return verify


def reject_all_tokens(_token: str) -> Optional[str]:
    """Fail closed until the host supplies a verified identity adapter."""
    return None
