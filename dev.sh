#!/usr/bin/env bash
set -e

# Help function
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  format   Run code formatting (Ruff)"
    echo "  lint     Run linters and type checking (Ruff, MyPy)"
    echo "  check    Run full pre-commit pipeline (Format, Lint, Tests)"
    echo "  update   Update IsaacLab submodule to the latest tag"
    echo ""
}

# 1. Format Function
run_format() {
    echo "running formatter..."
    set -x
    ruff check source scripts --fix
    ruff format source scripts
    set +x
    echo "format complete."
}

# 2. Lint Function
run_lint() {
    echo "running linter..."
    set -x
    ruff check source scripts          # linter
    ruff format source scripts --check  # formatter check
    mypy source                         # type check
    set +x
    echo "lint complete."
}

# 3. Pre-commit/Check Function
run_check() {
    echo "running pre-commit pipeline..."
    pre-commit run --all-files
    run_format
    run_lint
    echo "running tests..."
    pytest tests
    echo "all checks passed."
}

# 4. Update IsaacLab Function
run_update() {
    echo "Entering IsaacLab submodule..."
    cd dependencies/IsaacLab || exit

    echo "Fetching tags..."
    git fetch --tags

    # Get the latest tag
    LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)
    echo "Found latest tag: $LATEST_TAG"

    git checkout "$LATEST_TAG"
    cd ../..

    echo "Committing changes to parent repo..."
    git add dependencies/IsaacLab
    git commit -m "Update IsaacLab submodule to tag $LATEST_TAG"
    echo "Done! IsaacLab is now at $LATEST_TAG"
}

# Main Dispatcher
case "$1" in
    format)
        run_format
        ;;
    lint)
        run_lint
        ;;
    check)
        run_check
        ;;
    update)
        run_update
        ;;
    *)
        show_help
        exit 1
        ;;
esac
