#!/usr/bin/env python3
"""
Refresh the bundled country statistics in CountryData.cs from the free,
key-less World Bank API (https://api.worldbank.org).

WHY THIS EXISTS
---------------
The app must run with no network connection, so the data is *bundled* as a
compiled C# list (fast, trim-safe, offline). "Keeping it up to date" therefore
means regenerating that bundled file in the repo - not fetching at runtime.
This script does exactly that: it reads the existing CountryData.cs, refreshes
the numeric fields in place, and writes the file back. A human reviews the
`git diff` and commits it (or the scheduled GitHub Action opens a PR).

WHAT IT UPDATES (World Bank indicator -> field)
    SP.POP.TOTL     -> Population
    AG.LND.TOTL.K2  -> Area (land area, km^2)
    NY.GDP.MKTP.CD  -> GdpTotal (converted USD -> millions USD)
    NY.GDP.PCAP.CD  -> GdpPerCapita (USD)
    EN.POP.DNST     -> PopulationDensity (people / km^2)
    SE.ADT.LITR.ZS  -> LiteracyRate (%)
    SP.DYN.LE00.IN  -> LifeExpectancy (years)

WHAT IT LEAVES ALONE
    Code, Name, Iso2, Continent  -> identity fields, curated by hand.
    Hdi                          -> no free, stable API; update from the annual
                                    UNDP Human Development Report by hand.
    Any field World Bank has no recent value for -> the existing value is kept.

USAGE
    python3 scripts/update_country_data.py            # refresh + write
    python3 scripts/update_country_data.py --dry-run  # report changes only

NOTE
    Only the Python standard library is used (urllib), so there is nothing to
    install. Run it once and eyeball the diff before committing - data coverage
    on some indicators is patchy, which is exactly why we keep existing values
    on gaps.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

# Path is relative to the repository root (where the script is run from).
DATA_FILE = Path("src/MyDesktopApplication.Shared/Data/CountryData.cs")

WORLD_BANK_BASE = "https://api.worldbank.org/v2"


# field name in CountryData.cs -> (World Bank indicator, formatter)
def _as_int(value: float) -> str:
    return str(int(round(value)))

def _as_millions(value: float) -> str:
    return str(int(round(value / 1_000_000)))

def _one_dp(value: float) -> str:
    return f"{value:.1f}"

FIELDS = {
    "Population": ("SP.POP.TOTL", _as_int),
    "Area": ("AG.LND.TOTL.K2", _as_int),
    "GdpTotal": ("NY.GDP.MKTP.CD", _as_millions),
    "GdpPerCapita": ("NY.GDP.PCAP.CD", _as_int),
    "PopulationDensity": ("EN.POP.DNST", _one_dp),
    "LiteracyRate": ("SE.ADT.LITR.ZS", _one_dp),
    "LifeExpectancy": ("SP.DYN.LE00.IN", _one_dp),
}


def fetch_indicator(indicator: str) -> dict[str, float]:
    """Return {iso3: most_recent_non_empty_value} for every country."""
    values: dict[str, float] = {}
    page = 1
    while True:
        url = (
            f"{WORLD_BANK_BASE}/country/all/indicator/{indicator}"
            f"?format=json&mrnev=1&per_page=400&page={page}"
        )
        with urllib.request.urlopen(url, timeout=60) as response:
            payload = json.load(response)

        if not isinstance(payload, list) or len(payload) < 2 or payload[1] is None:
            break

        meta, rows = payload[0], payload[1]
        for row in rows:
            iso3 = row.get("countryiso3code")
            value = row.get("value")
            if iso3 and value is not None:
                values[iso3] = float(value)

        total_pages = int(meta.get("pages", 1))
        if page >= total_pages:
            break
        page += 1

    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would change without writing the file.",
    )
    args = parser.parse_args()

    if not DATA_FILE.exists():
        print(f"ERROR: {DATA_FILE} not found. Run this from the repo root.", file=sys.stderr)
        return 1

    text = DATA_FILE.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    # Download every indicator once for all countries (a handful of requests).
    print("Fetching indicators from the World Bank API...")
    indicator_values: dict[str, dict[str, float]] = {}
    for field, (indicator, _) in FIELDS.items():
        print(f"  {field:<18} <- {indicator}")
        try:
            indicator_values[field] = fetch_indicator(indicator)
        except Exception as error:  # noqa: BLE001 - report and keep existing values
            print(f"    WARNING: failed to fetch {indicator}: {error}", file=sys.stderr)
            indicator_values[field] = {}

    country_line = re.compile(r'new\(\)\s*\{\s*Code\s*=\s*"([A-Z]{3})"')
    changes = 0
    countries = 0

    for i, line in enumerate(lines):
        match = country_line.search(line)
        if not match:
            continue
        countries += 1
        iso3 = match.group(1)
        new_line = line

        for field, (_, formatter) in FIELDS.items():
            value = indicator_values[field].get(iso3)
            if value is None:
                continue  # no fresh data -> keep whatever is in the file
            formatted = formatter(value)
            # Replace exactly this field's number on this country's line.
            pattern = re.compile(rf"({re.escape(field)}\s*=\s*)(-?\d+(?:\.\d+)?)")
            replaced, n = pattern.subn(rf"\g<1>{formatted}", new_line, count=1)
            if n == 1 and replaced != new_line:
                new_line = replaced
                changes += 1

        lines[i] = new_line

    print(f"\nScanned {countries} countries; {changes} field value(s) changed.")

    if args.dry_run:
        print("Dry run - no file written.")
        return 0

    DATA_FILE.write_text("".join(lines), encoding="utf-8")
    print(f"Wrote {DATA_FILE}. Review `git diff` before committing.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
