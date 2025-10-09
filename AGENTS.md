# Repository Guidelines

## Project Structure & Module Organization
PromptEngine is a Rails engine. Engine code lives under `app/`, split into `controllers/`, `models/`, `services/`, and `views/` that all mount under the `PromptEngine` namespace. Shared Ruby utilities are in `lib/`, with the entry point at `lib/prompt_engine.rb` and Rake tasks under `lib/tasks/`. Database migrations, seeds, and schema snapshots live in `db/`. Specs sit in `spec/`, while `spec/dummy/` hosts the sandbox Rails app used for integration-style tests. Executables such as `bin/rubocop`, `bin/rails`, and `bin/test_integration` power local workflows.

## Build, Test, and Development Commands
- `bundle exec rspec` — runs the engine's unit and feature specs in `spec/`.
- `bin/test_integration` — migrates the dummy app and exercises `spec/models/prompt_spec.rb` end to end.
- `bin/rubocop` — enforces the RuboCop Rails Omakase style rules.
- `bin/rails prompt_engine:install:migrations` — copies engine migrations when verifying installation inside the dummy app.
Run commands from the repository root unless otherwise noted.

## Coding Style & Naming Conventions
Code is Ruby-first with standard two-space indentation. Follow the Rails Omakase RuboCop profile (`.rubocop.yml`), including snake_case method names, CamelCase classes under the `PromptEngine` module, and descriptive migration names such as `YYYYMMDDHHMMSS_create_prompt_versions`. Prefer service objects in `app/services/` for multi-step workflows and keep controllers lean.

## Testing Guidelines
RSpec is the default framework. Name specs after the subject (`spec/models/prompt_spec.rb`) and group shared examples under `spec/support/` if added. Use `FactoryBot` for fixtures and `VCR` + `WebMock` when touching external LLM APIs. Aim to cover new behavior with focused examples and update `spec/dummy` seeds when playground data changes. Run `bundle exec rspec` before pushing.

## Commit & Pull Request Guidelines
Recent history favors concise, imperative commit subjects (e.g., "Update RubyLLM to 1.6.4"). Scope commits to one logical change and reference issues in the body when relevant. Pull requests should describe the motivation, outline tests executed, and include screenshots or console output when the admin UI or generators change. Keep PRs small; mention follow-up work explicitly to aid review.

## Configuration Tips
Sensitive keys (LLM providers, admin credentials) belong in Rails credentials. Ensure sandbox migrations stay in sync with `db/` before publishing a gem release, and document any new initializer knobs in both `README.md` and the docs site to avoid drift.
