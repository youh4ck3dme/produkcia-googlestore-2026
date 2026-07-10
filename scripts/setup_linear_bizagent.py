#!/usr/bin/env python3
"""Vytvorí BizAgent projekt + backlog v Linear."""

from __future__ import annotations

import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LINEAR_API = "https://api.linear.app/graphql"

ENV_CANDIDATES = [
    ROOT / ".env.local",
    Path.home() / "HUB/JARVIS/jarvis-chat-main/.env.local",
]


def load_env_local() -> None:
    for path in ENV_CANDIDATES:
        if not path.is_file():
            continue
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            os.environ.setdefault(key, value)
        print(f"→ Načítané env z {path}")
        return


def gql(api_key: str, query: str, variables: dict | None = None) -> dict:
    payload = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(
        LINEAR_API,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": api_key,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode())
    if data.get("errors"):
        raise RuntimeError(json.dumps(data["errors"], indent=2))
    return data["data"]


def resolve_team_id(api_key: str) -> tuple[str, str]:
    if team_id := os.environ.get("LINEAR_TEAM_ID"):
        return team_id, team_id

    team_key = os.environ.get("LINEAR_TEAM_KEY", "YOU")
    data = gql(api_key, "query { teams { nodes { id key name } } }")
    teams = data["teams"]["nodes"]
    for team in teams:
        if team["key"].lower() == team_key.lower():
            return team["id"], f"{team['key']} ({team['name']})"
    for team in teams:
        if "biz" in team["name"].lower() or "agent" in team["name"].lower():
            return team["id"], f"{team['key']} ({team['name']})"
    team = teams[0]
    return team["id"], f"{team['key']} ({team['name']})"


def ensure_project(api_key: str, team_id: str, name: str, description: str) -> tuple[str, str]:
    existing = gql(
        api_key,
        "query($teamId: String!) { team(id: $teamId) { projects { nodes { id name url } } } }",
        {"teamId": team_id},
    )
    for project in existing["team"]["projects"]["nodes"]:
        if project["name"].lower() == name.lower():
            return project["id"], project["url"]

    created = gql(
        api_key,
        "mutation($input: ProjectCreateInput!) { projectCreate(input: $input) { project { id url } } }",
        {
            "input": {
                "teamIds": [team_id],
                "name": name,
                "description": description,
                "state": "started",
                "priority": 1,
            }
        },
    )
    project = created["projectCreate"]["project"]
    return project["id"], project["url"]


def create_issue(
    api_key: str,
    team_id: str,
    project_id: str,
    title: str,
    description: str,
    priority: int,
) -> str:
    data = gql(
        api_key,
        "mutation($input: IssueCreateInput!) { issueCreate(input: $input) { issue { identifier url } } }",
        {
            "input": {
                "teamId": team_id,
                "projectId": project_id,
                "title": title,
                "description": description,
                "priority": priority,
            }
        },
    )
    issue = data["issueCreate"]["issue"]
    print(f"  ✅ {issue['identifier']}: {title}")
    return issue["url"]


def main() -> int:
    load_env_local()
    api_key = os.environ.get("LINEAR_API_KEY")
    if not api_key:
        print("❌ Chýba LINEAR_API_KEY v .env.local", file=sys.stderr)
        return 1

    team_id, team_label = resolve_team_id(api_key)
    print(f"→ Team: {team_label}")

    project_name = "BizAgent — Play Store 2026"
    project_desc = (
        "Kanonický projekt: sk.bizagent.app | Supabase kpsnwpuydqqojwmrnkdy | "
        "GitHub produkcia-googlestore-2026 | main @ 287ce7a"
    )
    print(f"→ Projekt: {project_name}")
    project_id, project_url = ensure_project(api_key, team_id, project_name, project_desc)

    p0 = [
        ("P0: Live E2E test (login → faktúra → delete)", "bash scripts/run_with_supabase.sh"),
        ("P0: supabase db push (invoice_counters)", "supabase db push"),
        ("P0: Google OAuth redirect URI", "Google Console → Supabase callback URL"),
        ("P0: Edge function secrets (MISTRAL/Gemini)", "Supabase Dashboard → Secrets"),
        ("P0: Play Console listing sk.bizagent.app", "Nový listing + internal testing"),
        ("P0: Upload AAB", "bash scripts/prepare_play_upload.sh"),
        ("P0: Privacy + deletion URL v Play", "web-one-beta-76.vercel.app/privacy.html"),
        ("P0: Demo účet pre Play review", "DEMO_ACCOUNT_SECRETS.txt"),
        ("P0: Rotácia leaked secrets", "Rotovať demo heslo + API keys"),
    ]
    p1 = [
        ("P1: IČO cache → Supabase", "company_lookup_service.dart"),
        ("P1: Kategorizácia výdavkov → Supabase", "categorization_service.dart"),
        ("P1: Zmazať firestore_export_data_source", "Legacy po AGENT B"),
        ("P1: batchRefreshWatched → Supabase cron", "batchRefreshWatched.ts"),
        ("P1: IAP server-side verify", "Play Developer API"),
    ]

    print("→ P0 issues (Urgent)…")
    for title, desc in p0:
        create_issue(api_key, team_id, project_id, title, desc, priority=1)

    print("→ P1 issues (High)…")
    for title, desc in p1:
        create_issue(api_key, team_id, project_id, title, desc, priority=2)

    print(f"\n🎉 BizAgent je v Linear: {project_url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())