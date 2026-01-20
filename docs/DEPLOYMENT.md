# Investment Manager Deployment

## Overview

The Investment Manager is currently a Python CLI application. This guide covers local installation and usage.

## Installation

```bash
cd modules/asset-managers/investment-manager
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Usage

```bash
# Run the application
python -m investment_manager

# Run tests
pytest
```

## Configuration

Configuration is managed via environment variables or a `.env` file:

```bash
DATABASE_URL=sqlite:///./investment_manager.db
```

## Future Deployment

When Flutter frontend and FastAPI backend are added:
- Frontend: GitHub Pages via infrastructure workflows
- Backend: AWS ECS via infrastructure workflows

---

[Back to Module](../) | [Platform Documentation](../../../../docs/)
