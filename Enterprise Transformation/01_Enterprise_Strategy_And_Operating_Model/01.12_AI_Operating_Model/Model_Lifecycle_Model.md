# Model Lifecycle Operating Model

## Overview
The operational framework governing how a model lives and dies.

## Stages and Owners
1. **Train/Fine-Tune**: Owned by Data Scientists / ML Engineers.
2. **Validate/Red-Team**: Owned by AI Governance / Security teams to ensure safety and lack of bias.
3. **Deploy**: Owned by MLOps Engineers.
4. **Monitor**: Shared ownership between Data Scientists (for drift) and SREs (for system uptime).
5. **Retire**: Owned by AI Product Managers when the model is replaced or no longer delivers ROI.
