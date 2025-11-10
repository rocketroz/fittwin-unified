from __future__ import annotations

import os
from typing import Any, Dict

from crewai import Agent, Crew, LLM, Task

from ai.crewai.client.api import dmaas_latest


def _latest_dmaat_snapshot() -> Dict[str, Any]:
    """Fetch the latest DMaaS payload but never raise if the API is down."""

    try:
        return dmaas_latest()
    except Exception as exc:  # pragma: no cover - defensive fallback for CLI usage
        return {"error": f"Could not reach /dmaas/latest: {exc}"}


def main() -> None:
    """Kick off the default two-agent planning crew."""

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not found in environment.")

    llm = LLM(model=os.getenv("AGENT_MODEL", "gpt-4o-mini"), api_key=api_key)

    planner = Agent(
        role="Planner",
        goal="Inspect /dmaas/latest output and outline next steps for the iPhone upload feature.",
        backstory="You operate like a staff engineer who aligns product and infra constraints.",
        llm=llm,
        verbose=True,
    )

    executor = Agent(
        role="Executor",
        goal="Transform plans into numbered, immediately actionable steps.",
        backstory="You write precise do-this-now instructions with commands and files spelled out.",
        llm=llm,
        verbose=True,
    )

    data_snapshot = _latest_dmaat_snapshot()

    analyze_task = Task(
        description=(
            "Summarize this /dmaas/latest payload and list two implications for the iPhone upload feature:\n\n"
            f"{data_snapshot}"
        ),
        agent=planner,
        expected_output="One short paragraph plus two bullet points on feature implications.",
    )

    checklist_task = Task(
        description="Convert the planner notes into a numbered checklist with 3–5 concrete steps.",
        agent=executor,
        expected_output="A numbered checklist that references files, commands, or endpoints.",
    )

    result = Crew(agents=[planner, executor], tasks=[analyze_task, checklist_task]).kickoff()
    print("\n=== Crew Output ===\n")
    print(result)


if __name__ == "__main__":
    main()
