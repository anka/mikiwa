---
name: write-spec
description: Write a feature spec or PRD from a problem statement or feature idea. Use when turning a vague idea or user request into a structured document, scoping a feature with goals and non-goals, defining success metrics and acceptance criteria, or breaking a big ask into a phased spec.
argument-hint: "<feature or problem statement>"
---

# Write Spec

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../../CONNECTORS.md).

Write a feature specification or product requirements document (PRD).

## Usage

```
/write-spec $ARGUMENTS
```

## Workflow

### 1. Understand the Feature

Ask the user what they want to spec. Accept any of:
- A feature name ("SSO support")
- A problem statement ("Enterprise customers keep asking for centralized auth")
- A user request ("Users want to export their data as CSV")
- A vague idea ("We should do something about onboarding drop-off")

### 2. Gather Context

Ask the user for the following. Be conversational — do not dump all questions at once. Ask the most important ones first and fill in gaps as you go:

- **User problem**: What problem does this solve? Who experiences it?
- **Target users**: Which user segment(s) does this serve?
- **Success metrics**: How will we know this worked?
- **Constraints**: Technical constraints, timeline, regulatory requirements, dependencies
- **Prior art**: Has this been attempted before? Are there existing solutions?

### 3. Generate the PRD

Produce the PRD as a **single JSON-LD object** following the schema defined in **Output Format** below. Every section maps to a named field in the object — see **PRD Structure** for guidance on what each field should contain.

Sections to populate:

- `problemStatement` — user problem, affected users, cost of inaction (2-3 sentences)
- `goals` — 3-5 specific, measurable outcomes tied to user or business metrics
- `nonGoals` — 3-5 things explicitly out of scope, each with a rationale
- `userStories` — standard format grouped by persona, ordered by priority
- `requirements` — split into `mustHave` (P0), `niceToHave` (P1), `futureConsiderations` (P2), each with acceptance criteria
- `successMetrics` — `leading` and `lagging` indicators with targets and measurement methods
- `openQuestions` — unresolved questions tagged with owner and blocking status
- `timeline` — hard deadlines, dependencies, and suggested phasing

### 4. Review and Iterate

After generating the PRD:
- Ask the user if any sections need adjustment
- Offer to expand on specific sections
- Offer to create follow-up artifacts (design brief, engineering ticket breakdown, stakeholder pitch)

## PRD Structure

### Problem Statement
- Describe the user problem in 2-3 sentences
- Who experiences this problem and how often
- What is the cost of not solving it (user pain, business impact, competitive risk)
- Ground this in evidence: user research, support data, metrics, or customer feedback

### Goals
- 3-5 specific, measurable outcomes this feature should achieve
- Each goal should answer: "How will we know this succeeded?"
- Distinguish between user goals (what users get) and business goals (what the company gets)
- Goals should be outcomes, not outputs ("reduce time to first value by 50%" not "build onboarding wizard")

### Non-Goals
- 3-5 things this feature explicitly will NOT do
- Adjacent capabilities that are out of scope for this version
- For each non-goal, briefly explain why it is out of scope (not enough impact, too complex, separate initiative, premature)
- Non-goals prevent scope creep during implementation and set expectations with stakeholders

### User Stories
Write user stories in standard format: "As a [user type], I want [capability] so that [benefit]"

Guidelines:
- The user type should be specific enough to be meaningful ("enterprise admin" not just "user")
- The capability should describe what they want to accomplish, not how
- The benefit should explain the "why" — what value does this deliver
- Include edge cases: error states, empty states, boundary conditions
- Include different user types if the feature serves multiple personas
- Order by priority — most important stories first

Example:
- "As a team admin, I want to configure SSO for my organization so that my team members can log in with their corporate credentials"
- "As a team member, I want to be automatically redirected to my company's SSO login so that I do not need to remember a separate password"
- "As a team admin, I want to see which members have logged in via SSO so that I can verify the rollout is working"

### Requirements

**Must-Have (P0)**: The feature cannot ship without these. These represent the minimum viable version of the feature. Ask: "If we cut this, does the feature still solve the core problem?" If no, it is P0.

**Nice-to-Have (P1)**: Significantly improves the experience but the core use case works without them. These often become fast follow-ups after launch.

**Future Considerations (P2)**: Explicitly out of scope for v1 but we want to design in a way that supports them later. Documenting these prevents accidental architectural decisions that make them hard later.

For each requirement:
- Write a clear, unambiguous description of the expected behavior
- Include acceptance criteria (see below)
- Note any technical considerations or constraints
- Flag dependencies on other teams or systems

### Open Questions
- Questions that need answers before or during implementation
- Tag each with who should answer (engineering, design, legal, data, stakeholder)
- Distinguish between blocking questions (must answer before starting) and non-blocking (can resolve during implementation)

### Timeline Considerations
- Hard deadlines (contractual commitments, events, compliance dates)
- Dependencies on other teams' work or releases
- Suggested phasing if the feature is too large for one release

## User Story Writing

Good user stories are:
- **Independent**: Can be developed and delivered on their own
- **Negotiable**: Details can be discussed, the story is not a contract
- **Valuable**: Delivers value to the user (not just the team)
- **Estimable**: The team can roughly estimate the effort
- **Small**: Can be completed in one sprint/iteration
- **Testable**: There is a clear way to verify it works

### Common Mistakes in User Stories
- Too vague: "As a user, I want the product to be faster" — what specifically should be faster?
- Solution-prescriptive: "As a user, I want a dropdown menu" — describe the need, not the UI widget
- No benefit: "As a user, I want to click a button" — why? What does it accomplish?
- Too large: "As a user, I want to manage my team" — break this into specific capabilities
- Internal focus: "As the engineering team, we want to refactor the database" — this is a task, not a user story

## Requirements Categorization

### MoSCoW Framework
- **Must have**: Without these, the feature is not viable. Non-negotiable.
- **Should have**: Important but not critical for launch. High-priority fast follows.
- **Could have**: Desirable if time permits. Will not delay delivery if cut.
- **Won't have (this time)**: Explicitly out of scope. May revisit in future versions.

### Tips for Categorization
- Be ruthless about P0s. The tighter the must-have list, the faster you ship and learn.
- If everything is P0, nothing is P0. Challenge every must-have: "Would we really not ship without this?"
- P1s should be things you are confident you will build soon, not a wish list.
- P2s are architectural insurance — they guide design decisions even though you are not building them now.

## Success Metrics Definition

### Leading Indicators
Metrics that change quickly after launch (days to weeks):
- **Adoption rate**: % of eligible users who try the feature
- **Activation rate**: % of users who complete the core action
- **Task completion rate**: % of users who successfully accomplish their goal
- **Time to complete**: How long the core workflow takes
- **Error rate**: How often users encounter errors or dead ends
- **Feature usage frequency**: How often users return to use the feature

### Lagging Indicators
Metrics that take time to develop (weeks to months):
- **Retention impact**: Does this feature improve user retention?
- **Revenue impact**: Does this drive upgrades, expansion, or new revenue?
- **NPS / satisfaction change**: Does this improve how users feel about the product?
- **Support ticket reduction**: Does this reduce support load?
- **Competitive win rate**: Does this help win more deals?

### Setting Targets
- Targets should be specific: "50% adoption within 30 days" not "high adoption"
- Base targets on comparable features, industry benchmarks, or explicit hypotheses
- Set a "success" threshold and a "stretch" target
- Define the measurement method: what tool, what query, what time window
- Specify when you will evaluate: 1 week, 1 month, 1 quarter post-launch

## Acceptance Criteria

Write acceptance criteria in Given/When/Then format or as a checklist:

**Given/When/Then**:
- Given [precondition or context]
- When [action the user takes]
- Then [expected outcome]

Example:
- Given the admin has configured SSO for their organization
- When a team member visits the login page
- Then they are automatically redirected to the organization's SSO provider

**Checklist format**:
- [ ] Admin can enter SSO provider URL in organization settings
- [ ] Team members see "Log in with SSO" button on login page
- [ ] SSO login creates a new account if one does not exist
- [ ] SSO login links to existing account if email matches
- [ ] Failed SSO attempts show a clear error message

### Tips for Acceptance Criteria
- Cover the happy path, error cases, and edge cases
- Be specific about the expected behavior, not the implementation
- Include what should NOT happen (negative test cases)
- Each criterion should be independently testable
- Avoid ambiguous words: "fast", "user-friendly", "intuitive" — define what these mean concretely

## Scope Management

### Recognizing Scope Creep
Scope creep happens when:
- Requirements keep getting added after the spec is approved
- "Small" additions accumulate into a significantly larger project
- The team is building features no user asked for ("while we're at it...")
- The launch date keeps moving without explicit re-scoping
- Stakeholders add requirements without removing anything

### Preventing Scope Creep
- Write explicit non-goals in every spec
- Require that any scope addition comes with a scope removal or timeline extension
- Separate "v1" from "v2" clearly in the spec
- Review the spec against the original problem statement — does everything serve it?
- Time-box investigations: "If we cannot figure out X in 2 days, we cut it"
- Create a "parking lot" for good ideas that are not in scope

## Output Format

Emit the PRD as a single, valid **JSON-LD** object. Do not wrap it in markdown — output only the raw JSON-LD block. Use the following schema exactly; omit optional fields only if genuinely unknown (never emit `null` for required fields).

```json
{
  "@context": {
    "@vocab": "https://schema.org/",
    "spec": "https://mikiwa.app/spec/v1#"
  },
  "@type": "TechArticle",
  "@id": "urn:spec:<kebab-case-feature-name>",
  "name": "<Feature name>",
  "description": "<One-sentence summary>",
  "dateCreated": "<ISO 8601 date>",
  "version": "1.0",

  "spec:problemStatement": {
    "description": "<2-3 sentences describing the problem>",
    "affectedUsers": "<Who experiences this and how often>",
    "costOfInaction": "<User pain, business impact, competitive risk>"
  },

  "spec:goals": [
    {
      "description": "<Measurable outcome>",
      "type": "user | business",
      "target": "<Specific target, e.g. '50% reduction in time-to-value within 30 days'>"
    }
  ],

  "spec:nonGoals": [
    {
      "description": "<What this will NOT do>",
      "rationale": "<Why it is out of scope>"
    }
  ],

  "spec:userStories": [
    {
      "persona": "<Specific user type>",
      "capability": "<What they want to accomplish>",
      "benefit": "<Why — the value delivered>",
      "priority": 0
    }
  ],

  "spec:requirements": {
    "mustHave": [
      {
        "id": "R-P0-001",
        "description": "<Expected behavior>",
        "acceptanceCriteria": [
          {
            "given": "<Precondition>",
            "when": "<Action>",
            "then": "<Expected outcome>"
          }
        ],
        "technicalNotes": "<Optional: constraints or dependencies>",
        "dependencies": []
      }
    ],
    "niceToHave": [
      {
        "id": "R-P1-001",
        "description": "<Expected behavior>",
        "acceptanceCriteria": [],
        "technicalNotes": "",
        "dependencies": []
      }
    ],
    "futureConsiderations": [
      {
        "id": "R-P2-001",
        "description": "<Out-of-scope capability to design for>",
        "rationale": "<Why deferred>"
      }
    ]
  },

  "spec:successMetrics": {
    "leading": [
      {
        "name": "<Metric name>",
        "description": "<What it measures>",
        "target": "<Specific target>",
        "measurementMethod": "<Tool / query / time window>",
        "evaluationAt": "<e.g. '30 days post-launch'>"
      }
    ],
    "lagging": [
      {
        "name": "<Metric name>",
        "description": "<What it measures>",
        "target": "<Specific target>",
        "measurementMethod": "<Tool / query / time window>",
        "evaluationAt": "<e.g. '90 days post-launch'>"
      }
    ]
  },

  "spec:openQuestions": [
    {
      "question": "<Unresolved question>",
      "owner": "engineering | design | legal | data | stakeholder",
      "blocking": true
    }
  ],

  "spec:timeline": {
    "hardDeadlines": [
      { "description": "<Deadline or commitment>", "date": "<ISO 8601 date or null>" }
    ],
    "dependencies": [
      { "description": "<Dependency on another team or system>" }
    ],
    "phases": [
      { "name": "v1", "scope": "<What is included in this phase>" }
    ]
  }
}
```

### Field rules

- **`@id`**: always `urn:spec:<kebab-case-feature-name>` derived from `name`.
- **`priority`** in `userStories`: integer starting at `0` (highest priority). Increment by 1 per story.
- **`id`** in requirements: format `R-P0-001`, `R-P1-001`, `R-P2-001` with zero-padded counter per priority tier.
- **`owner`** in `openQuestions`: one of the five allowed string values exactly.
- **`blocking`** in `openQuestions`: `true` if must be resolved before implementation starts, `false` otherwise.
- **`type`** in `goals`: `"user"` or `"business"`.
- All date strings: ISO 8601 (`YYYY-MM-DD`). Use `null` only for genuinely unknown dates.
- Omit `technicalNotes` and `dependencies` from requirements only when empty — prefer an empty string / empty array over omission to keep the schema uniform.

## Tips

- Be opinionated about scope. It is better to have a tight, well-defined spec than an expansive vague one.
- If the user's idea is too big for one spec, suggest breaking it into phases and spec the first phase.
- Success metrics should be specific and measurable, not vague ("improve user experience").
- Non-goals are as important as goals. They prevent scope creep during implementation.
- Open questions should be genuinely open — do not include questions you can answer from context.