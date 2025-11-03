"""CrewAI measurement crew aligned with the Manus implementation package."""

from __future__ import annotations

import os

from crewai import Agent, Crew, LLM, Task

from agents.tools.measurement_tools import recommend_size, validate_measurements


def create_measurement_crew() -> Crew:
    """Instantiate the measurement processing crew with strategic directives."""

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not found in environment.")

    llm = LLM(model=os.getenv("AGENT_MODEL", "gpt-4o-mini"), api_key=api_key)

    ceo = Agent(
        role="CEO",
        goal=(
            "Maintain <3% measurement error, keep Supabase integration on track, and escalate calibration"
            " efforts whenever confidence drops below 97%."
        ),
        backstory=(
            "Lead the FitTwin DMaaS MVP delivery. Coordinate the Architect and ML Engineer, enforce RLS policies,"
            " and keep the project under the five-day / $500 guardrails."
        ),
        llm=llm,
        verbose=True,
    )

    architect = Agent(
        role="Architect",
        goal="Implement Supabase schema and geometric equations for MediaPipe-based measurement calculation.",
        backstory=(
            "Design the ingestion + normalization flow, store photos/landmarks/measurements with provenance, and call"
            " validate_measurements first. Attempt one obvious fix on 422 errors before escalating."
        ),
        tools=[validate_measurements],
        llm=llm,
        verbose=True,
    )

    ml_engineer = Agent(
        role="ML Engineer",
        goal="Produce measurement accuracy estimates and sizing recommendations from normalized data.",
        backstory=(
            "Build proprietary heuristics on top of normalized MediaPipe outputs, call recommend_size, and surface"
            " confidence/flags back to the CEO."
        ),
        tools=[recommend_size],
        llm=llm,
        verbose=True,
    )

    tasks = [
        Task(
            description=(
                "Architect: call validate_measurements on the latest payload, fix obvious unit/name issues once,"
                " and summarize the normalized measurements with provenance IDs."
            ),
            agent=architect,
            expected_output="Normalized measurement JSON + notes on any fixes applied.",
        ),
        Task(
            description=(
                "ML Engineer: take the Architect output, estimate accuracy, call recommend_size, and return the"
                " recommended sizes plus confidence numbers for tops/bottoms."
            ),
            agent=ml_engineer,
            expected_output="JSON with recommended_size, alternatives, and confidence summary.",
        ),
        Task(
            description=(
                "CEO: review Architect + ML results, highlight risks (accuracy <97%, missing landmarks, budget hits) and"
                " outline next actions."
            ),
            agent=ceo,
            expected_output="Bullet list of risks + next steps for the team.",
        ),
    ]

    return Crew(agents=[ceo, architect, ml_engineer], tasks=tasks)


if __name__ == "__main__":
    crew = create_measurement_crew()
    result = crew.kickoff()
    print("\n=== Measurement Crew Output ===\n")
    print(result)
