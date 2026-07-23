# Platform Audit

This document outlines the real state of the AI Interview Platform, highlighting critical risks across workflow, data integrity, and functionality.

## Missing or Ambiguous Spec (Never Defined)

1. **P0 (Blocker) - Complete Absence of Definition of Ready (Specs/PRDs)**
   - **Impact**: The entire delivery process is unsafe. Engineers are building features without verified specs, meaning correctness cannot be validated and no one can prove if the right problem is being solved.
   - **Evidence**: A repository-wide scan reveals `0` PRDs, `0` Acceptance Criteria documents, and no structural enforcement in the codebase or CI to require them before a build starts.

2. **P1 (Major) - Lack of Automated Test Coverage**
   - **Impact**: Code regressions will silently reach production. The G3 "Release-ready" gate cannot be enforced automatically because there are no tests to prove "regression green".
   - **Evidence**: Running a search for `spec/`, `test/`, or `__tests__/` yields no testing framework or test cases in both the API and Web services.

## Built Wrong (Defined but Build Does Not Match)

3. **P1 (Major) - Insecure Direct Object Reference (IDOR) on Portfolios**
   - **Impact**: Severe data leak. Any authenticated user (from any tenant) can view another tenant's candidate portfolio by simply guessing the `Portfolio` ID.
   - **Evidence**: In `api/app/models/portfolio.rb`, the `TenantScoped` concern is missing. In `PortfoliosController#set_portfolio`, when accessed directly via `/api/v1/portfolios/:id`, the lookup is simply `Portfolio.find(params[:id])` with no check to ensure the portfolio belongs to the current user's tenant.

4. **P1 (Major) - Data Type Mismatch for `ai_level` between API and Web**
   - **Impact**: The frontend assessor view will break or fail to render portfolio skills properly because it receives unexpected data types.
   - **Evidence**: The DB schema (`create_table "portfolio_skills"`) stores `ai_level` as an `integer` (1-5), and `PortfoliosController#portfolio_skill_json` returns it as an integer. However, `web/src/types/index.ts` rigidly expects `ai_level: string; // "L1" | "L2" | "L3" | "L4" | "L5"`.

## Summary & Ship Decision
If this platform went in front of a client tomorrow, my decision would be: **DO NOT SHIP (Blocked)**. The presence of a severe data-leak (IDOR) and hard-crashing data mismatches means it fails the G3 gate. The lack of any PRDs or test coverage means we cannot confidently guarantee correctness. The workflow must be hardened before any more code is written.
