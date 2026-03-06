#!/usr/bin/env python3
"""Discover the latest supported OpenShift stable channels.

Queries the Red Hat Product Lifecycle API and the Cincinnati graph API
to determine which stable-4.x channels are both supported and have
published releases.

Outputs a JSON object suitable for GitHub Actions dynamic matrix.
"""

import json
import sys
import urllib.request

LIFECYCLE_URL = (
    "https://access.redhat.com/product-life-cycles/api/v1/products"
    "?name=OpenShift+Container+Platform"
)
CINCINNATI_URL = (
    "https://api.openshift.com/api/upgrades_info/v1/graph"
    "?channel=stable-{version}"
)

COUNT = 3


def get_supported_versions():
    """Return minor version strings that are not end-of-life."""
    req = urllib.request.Request(
        LIFECYCLE_URL,
        headers={"User-Agent": "openshift-sdk/1.0"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())

    versions = []
    for v in data["data"][0]["versions"]:
        if v["type"] == "End of life":
            continue
        name = v["name"].strip()
        if name.startswith("4."):
            versions.append(name)

    versions.sort(key=lambda v: int(v.split(".")[1]), reverse=True)
    return versions


def get_latest_release(version):
    """Return the latest release version from the Cincinnati graph, or None."""
    url = CINCINNATI_URL.format(version=version)
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
    except Exception:
        return None

    nodes = data.get("nodes", [])
    if not nodes:
        return None

    best = max(nodes, key=lambda n: [int(x) for x in n["version"].split(".")])
    return best["version"]


def main():
    supported = get_supported_versions()
    channels = []
    for version in supported:
        release = get_latest_release(version)
        if release:
            channels.append({
                "release_channel": f"stable-{version}",
                "openshift_release": release,
            })
        if len(channels) == COUNT:
            break

    if not channels:
        print("ERROR: no supported stable channels found", file=sys.stderr)
        sys.exit(1)

    print(json.dumps({"include": channels}))


if __name__ == "__main__":
    main()
