#!/usr/bin/env python3
import os, sys, json
import tinytuya

def fail(msg):
    print(json.dumps({"error": str(msg)}))
    sys.exit(1)

try:
    dev = tinytuya.OutletDevice(
        os.environ["TUYA_DEVICE_ID"],
        os.environ.get("TUYA_IP", "192.168.1.186"),
        os.environ["TUYA_LOCAL_KEY"],
    )
    dev.set_version(float(os.environ.get("TUYA_VERSION", "3.5")))
    dev.set_socketTimeout(5)
    dp = int(os.environ.get("TUYA_SWITCH_DP", "1"))
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"

    if cmd in ("on", "off"):
        res = dev.set_status(cmd == "on", dp)
        if isinstance(res, dict) and res.get("Error"):
            fail(res["Error"])

    st = dev.status()
    if not isinstance(st, dict) or "dps" not in st:
        fail((st or {}).get("Error", "no dps in status"))
    print(json.dumps({"on": bool(st["dps"][str(dp)])}))
except KeyError as e:
    fail(f"missing setting or datapoint: {e}")
except Exception as e:
    fail(f"{type(e).__name__}: {e}")