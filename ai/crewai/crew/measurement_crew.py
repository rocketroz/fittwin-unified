"""
CrewAI configuration for the measurement-focused DMaaS workflow.

This mirrors the directives from the Manus import: a CEO agent orchestrates an
Architect, ML Engineer, DevOps, and Reviewer to validate measurements, produce
recommendations, and enforce security + budget guardrails.
"""

from __future__ import annotations

import os
from typing import List

from crewai import Agent, Crew, LLM, Task

from ai.crewai.tools.measurement_tools import recommend_sizes, validate_measurements


def _require_api_key() -> str:
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not found in environment.")
    return api_key


def _llm() -> LLM:
    return LLM(model=os.getenv("AGENT_MODEL", "gpt-4o-mini"), api_key=_require_api_key())


def create_measurement_crew() -> Crew:
    """Instantiate the measurement processing crew."""

    llm = _llm()

    ceo = Agent(
        role="CEO",
        goal="Ship the DMaaS MVP with <3% measurement error and <$500 infra spend.",
        backstory=(
            "You coordinate Architect, ML Engineer, and DevOps agents, escalate calibration needs when accuracy drops, "
            "and keep Supabase + TestFlight deliverables on track."
        ),
        llm=llm,
        verbose=True,
    )

    architect = Agent(
        role="Architect",
        goal="Design Supabase schemas and validate MediaPipe-derived measurements.",
        backstory=(
            "Plan the measurement ingestion pipeline. Call validate_measurements, retry once for obvious 422 fixes, "
            "and escalate unresolved issues to the CEO."
        ),
        tools=[validate_measurements],
        llm=llm,
        verbose=True,
    )

    ml_engineer = Agent(
        role="ML Engineer",
        goal="Produce sizing recommendations and accuracy estimates.",
        backstory=(
            "Build the proprietary sizing layer. Consume the Architect's normalized output, call recommend_sizes, "
            "and return concise JSON plus confidence notes."
        ),
        tools=[recommend_sizes],
        llm=llm,
        verbose=True,
    )

    devops = Agent(
        role="DevOps",
        goal="Own CI/CD, Supabase/TestFlight deployment, and budget tracking.",
        backstory=(
            "Wire GitHub Actions, Supabase migrations, and TestFlight distribution while safeguarding API keys "
            "and keeping spend under $500."
        ),
        llm=llm,
        verbose=True,
    )

    reviewer = Agent(
        role="Reviewer",
        goal="Audit security, data hygiene, and cost before sign-off.",
        backstory=(
            "Act as an autonomous reviewer ensuring RLS policies, API key handling, and cost constraints are satisfied "
            "before DevOps ships."
        ),
        llm=llm,
        verbose=True,
    )

    validate_task = Task(
        description=(
            "Validate MediaPipe landmarks or measurement payloads. Use validate_measurements. "
            "Attempt ONE repair on clear 422 hints (e.g., wrong unit) before escalating to the CEO."
        ),
        agent=architect,
        expected_output="Normalized measurements in centimeters plus confidence notes or an escalation summary.",
    )

    recommend_task = Task(
        description=(
            "Using the Architect's normalized output, call recommend_sizes and report the JSON result with confidence "
            "and model version metadata."
        ),
        agent=ml_engineer,
        expected_output="JSON recommendations containing processed measurements and model metadata.",
    )

    review_task = Task(
        description=(
            "Review validation + recommendation steps for security (RLS, API keys), accuracy (<3% error), and <$500 costs. "
            "Flag outstanding issues for the CEO/DevOps agents."
        ),
        agent=reviewer,
        expected_output="Approval summary or a list of blocking issues with remediation steps.",
    )

    tasks: List[Task] = [validate_task, recommend_task, review_task]
    agents: List[Agent] = [ceo, architect, ml_engineer, devops, reviewer]

    return Crew(agents=agents, tasks=tasks)
