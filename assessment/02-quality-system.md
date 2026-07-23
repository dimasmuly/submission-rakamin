# The Quality System (Net)

This document explains the workflow gate and automated CI net built to protect the AI Interview Platform. 

## 1. The Workflow Gate (Definition of Ready)
We introduced a hard requirement for all changes to carry their necessary inputs before they can be built or merged.

### What it is
- **PR Template Checklist**: `.github/PULL_REQUEST_TEMPLATE.md` contains mandatory checkboxes for `Spec/PRD`, `Acceptance Criteria`, and `Solution/Design Plan`.
- **Automated Verification**: `.github/workflows/gate.yml` runs a GitHub Action on every Pull Request. It parses the PR description and fails the build (goes red) if any of the mandatory Definition of Ready boxes are unchecked.

### What it protects
It prevents the root cause of "built wrong" features: starting work from a ghost spec. A change with no PRD or Acceptance criteria is completely blocked from merging.

## 2. Continuous Integration (CI) Net
We added a CI pipeline to catch defects automatically on every push and PR.

### What it is
- **RSpec Installation**: We installed and configured RSpec for the API since the platform had zero tests.
- **CI Pipeline**: `.github/workflows/ci.yml` spins up a PostgreSQL and Redis service, runs the Rails test suite, and reports the status.

### What it protects
- **Data Integrity / IDOR**: We added a request spec (`api/spec/requests/api/v1/portfolios_spec.rb`) to verify that users from one tenant cannot access portfolios of another tenant.
- **Frontend-Backend Contract**: We added a test to ensure that `ai_level` is serialized as a string (e.g. `"L3"`) rather than an integer, matching the strict requirements of the frontend's TypeScript models (`web/src/types/index.ts`).

### Red-to-Green Transition
- **Initially Red**: The tests initially fail (red) because the IDOR vulnerability exists in `PortfoliosController#set_portfolio` and the `ai_level` mismatch exists in `PortfoliosController#portfolio_skill_json`.
- **Fix to Green**: We applied code fixes in Phase 3 to correct these vulnerabilities. The test history proves that the checks were satisfied by fixing the root defect, not by weakening the test.

## How to Run Locally
To run the CI checks on your own machine:
1. `cd api`
2. `bundle install`
3. `RAILS_ENV=test bin/rails db:create db:schema:load`
4. `bundle exec rspec`
