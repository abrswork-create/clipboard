#!/usr/bin/env python3
"""
Paddle Billing Catalog Creation Script - One-Time (Lifetime) Tiers
Creates Starter Lifetime, Pro Lifetime, and Advanced Lifetime products
with one-time prices and localized purchasing-power price overrides for UK (GBP), IE (EUR), AU (AUD).
"""

import os
import sys
import json
import urllib.request
import urllib.error

PADDLE_BASE_URL = "https://api.paddle.com"

# One-Time Lifetime Tier Definitions
TIERS = [
    {
        "name": "Clipmory Starter Lifetime",
        "description": "Starter Lifetime License - Essential clipboard features with perpetual access",
        "price": {
            "amount_usd": "1499",   # $14.99
            "description": "Starter Lifetime One-Time Payment",
            "overrides": [
                {"country_codes": ["GB"], "currency": "GBP", "amount": "1199"},  # £11.99
                {"country_codes": ["IE"], "currency": "EUR", "amount": "1399"},  # €13.99
                {"country_codes": ["AU"], "currency": "AUD", "amount": "2299"},  # A$22.99
            ]
        }
    },
    {
        "name": "Clipmory Pro Lifetime",
        "description": "Pro Lifetime License - Full access to all Pro features, unlimited history, OCR & sync forever",
        "price": {
            "amount_usd": "2999",   # $29.99
            "description": "Pro Lifetime One-Time Payment",
            "overrides": [
                {"country_codes": ["GB"], "currency": "GBP", "amount": "2499"},  # £24.99
                {"country_codes": ["IE"], "currency": "EUR", "amount": "2799"},  # €27.99
                {"country_codes": ["AU"], "currency": "AUD", "amount": "4499"},  # A$44.99
            ]
        }
    },
    {
        "name": "Clipmory Advanced Lifetime",
        "description": "Advanced Lifetime License - Multi-device power pack, team features & priority support",
        "price": {
            "amount_usd": "5999",   # $59.99
            "description": "Advanced Lifetime One-Time Payment",
            "overrides": [
                {"country_codes": ["GB"], "currency": "GBP", "amount": "4999"},  # £49.99
                {"country_codes": ["IE"], "currency": "EUR", "amount": "5499"},  # €54.99
                {"country_codes": ["AU"], "currency": "AUD", "amount": "8999"},  # A$89.99
            ]
        }
    }
]


def paddle_request(endpoint: str, api_key: str, payload: dict) -> dict:
    url = f"{PADDLE_BASE_URL}{endpoint}"
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        },
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode("utf-8")
        print(f"❌ Error {e.code} calling {endpoint}: {error_msg}", file=sys.stderr)
        raise
    except Exception as e:
        print(f"❌ Request failed: {e}", file=sys.stderr)
        raise


def create_catalog(api_key: str):
    results = []
    print("🚀 Starting Paddle Live One-Time Catalog Creation...\n")

    for tier in TIERS:
        name = tier["name"]
        print(f"📦 Creating product: {name}...")

        prod_resp = paddle_request(
            "/products",
            api_key,
            {
                "name": name,
                "tax_category": "standard",
                "description": tier["description"]
            }
        )
        product_id = prod_resp["data"]["id"]
        print(f"   ✅ Product Created: {product_id}")

        price_info = tier["price"]
        print(f"   💳 Creating One-Time Price ({price_info['amount_usd']} cents USD)...")

        overrides = [
            {
                "country_codes": ov["country_codes"],
                "unit_price": {"amount": ov["amount"], "currency_code": ov["currency"]}
            }
            for ov in price_info["overrides"]
        ]

        # One-time price has billing_cycle = None (no subscription interval)
        price_resp = paddle_request(
            "/prices",
            api_key,
            {
                "product_id": product_id,
                "description": price_info["description"],
                "unit_price": {
                    "amount": price_info["amount_usd"],
                    "currency_code": "USD"
                },
                "unit_price_overrides": overrides
            }
        )
        price_id = price_resp["data"]["id"]
        print(f"      ✅ One-Time Price Created: {price_id}\n")

        results.append({
            "tier_name": name,
            "product_id": product_id,
            "price_id": price_id,
            "amount_usd": price_info["amount_usd"],
            "type": "one_time"
        })

    # Save mapping to file
    output_file = "paddle_catalog_mapping.json"
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2)

    print("=" * 60)
    print("🎉 One-Time Catalog Setup Complete!")
    print(f"Saved mapping to {output_file}")
    print("=" * 60)
    return results


if __name__ == "__main__":
    key = None
    if len(sys.argv) > 1:
        key = sys.argv[1].strip()
    elif "PADDLE_API_KEY" in os.environ:
        key = os.environ["PADDLE_API_KEY"].strip()

    if not key:
        print("Usage: python3 scripts/setup_paddle_catalog.py <PADDLE_API_KEY>")
        print("   or: export PADDLE_API_KEY=paddlev2_live_... && python3 scripts/setup_paddle_catalog.py")
        sys.exit(1)

    create_catalog(key)
