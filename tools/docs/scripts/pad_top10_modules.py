import os
BASE = r"c:\Users\swapn\Desktop\docs\Architecture_space\docs\02_Data_Engineering_Architecture\03_Data_Orchestration_Architecture\03_Top_10"
FOLDERS = [
    "02_Apache_Airflow_Learning_Guide",
    "03_Prefect_Learning_Guide",
    "04_Dagster_Learning_Guide",
]
PAD = """
## Architecture doc alignment

This module supports the Top 10 learning path under `02.03.03` and cross-links fundamentals in [Orchestration Reference Model](../../01_Fundamentals/01_Overview/03_Orchestration_Reference_Model.md), cloud comparisons in [Managed Workflows](../../02_Cloud_Services/01_Overview/02_Managed_Workflows.md), and peer guides in the [Top 10 hub](../README.md).

Use it together with official vendor documentation for version-specific APIs, deprecations, and security bulletins. Re-validate assumptions quarterly or when upgrading major versions.
"""
MARKER = "## Architecture doc alignment"
for folder in FOLDERS:
    d = os.path.join(BASE, folder)
    for name in os.listdir(d):
        if not name.endswith(".md") or name == "README.md":
            continue
        path = os.path.join(d, name)
        with open(path, encoding="utf-8") as f:
            text = f.read()
        if MARKER in text:
            continue
        if "## Related" in text:
            text = text.replace("## Related", PAD.strip() + "\n\n## Related", 1)
        else:
            text = text.rstrip() + "\n\n" + PAD.strip() + "\n"
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        lines = len(text.splitlines())
        print(name, lines)
