# Contributing to LeIsaac

Thanks for your interest in contributing to LeIsaac! This document describes how to report issues, propose changes, and submit pull requests.

## Code of conduct

Be respectful and constructive. Assume good intent.

## Getting help / asking questions

- Check the project documentation: https://lightwheelai.github.io/leisaac/
- If you're unsure whether something is a bug or a usage question, open a GitHub Issue with details.

## Reporting bugs

When filing an issue, please include:

- What you expected to happen vs what happened
- Minimal steps to reproduce
- Your environment (OS, GPU, driver, Python version, Isaac Sim / IsaacLab version)
- Relevant logs and stack traces (as text)

## Proposing changes

For non-trivial changes (new features, refactors, API changes), please open an issue first to align on scope and design.

## Pull request guidelines

- Keep PRs focused: one logical change per PR.
- Write clear commit messages.
- Update documentation when behavior or usage changes.
- Describe a manual test plan in the PR.

## Style and linting

LeIsaac uses [uv](https://docs.astral.sh/uv/) for dependency management and [Ruff](https://docs.astral.sh/ruff/) for formatting and linting. `pre-commit` hooks enforce these checks automatically (see `.pre-commit-config.yaml`). GitHub Actions also runs these checks on every PR/update.

It is strongly recommended to run the checks locally before opening/updating a PR.

```bash
# Install dev dependencies (includes pre-commit, ruff, mypy, etc.):
uv sync --dev

# Install the git hooks (one time per clone):
uv run pre-commit install

# Run all hooks on all files:
uv run pre-commit run --all-files

# Or use the dev script for formatting / linting / full checks:
./dev.sh format
./dev.sh lint
./dev.sh check
```

## License

By contributing, you agree that your contributions will be licensed under the project's license (see `LICENSE`).
