import json
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone, timedelta
from typing import List

from fastapi import FastAPI, HTTPException

app = FastAPI()


@dataclass
class Backup:
    label: str
    timestamp: int
    type: str
    size: str


def run_command(command: List[str], cwd: str = None) -> str:
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True, cwd=cwd)
        return result.stdout
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Command failed: {e.stderr}")


@app.post("/backup")
async def create_backup():
    try:
        result = run_command(["pgbackrest", "--log-level-console=info", "backup", "--type=incr", "--stanza=main"])
        return {"message": "Backup created successfully", "details": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/backups", response_model=List[Backup])
async def list_backups():
    try:
        result = run_command(["pgbackrest", "info", "--output=json"])
        info = json.loads(result)
        if len(info) == 0:
            raise HTTPException(status_code=404, detail="No backups found")
        backups = []
        for backup in info[0].get("backup", []):
            backups.append(Backup(
                label=backup.get("label", ""),
                timestamp=backup.get("timestamp", {}).get("start", 0),
                type=backup.get("type", ""),
                size=str(backup.get("info", {}).get("size", ""))
            ))
        return backups
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/restore")
async def restore_backup(timestamp: int):
    try:
        tz_offset = timezone(timedelta(hours=4))
        dt = datetime.fromtimestamp(timestamp, tz_offset)
        result = run_command([
            "/app/scripts/restore.sh",
            dt.isoformat()
        ], cwd="/app/scripts")
        return {"message": "Restore completed successfully", "details": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
