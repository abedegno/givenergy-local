"""API routes for inverter data (system data and meter data)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from givlocal.api.dependencies import require_auth
from givlocal.api.schemas import DataResponse
from givlocal.transforms.meter_data import transform_meter_data
from givlocal.transforms.system_data import transform_system_data

router = APIRouter(tags=["Inverter Data"])


@router.get(
    "/inverter/{inverter_serial_number}/system-data-latest",
    dependencies=[Depends(require_auth)],
)
async def system_data_latest(inverter_serial_number: str):
    """Transform current register cache to cloud JSON format."""
    from givlocal.main import app_state

    inv_state = app_state.inverters.get(inverter_serial_number)
    if not inv_state:
        raise HTTPException(status_code=404, detail="Inverter not found")

    result = transform_system_data(inv_state.plant.inverter)
    return DataResponse(data=result)


@router.get(
    "/inverter/{inverter_serial_number}/meter-data-latest",
    dependencies=[Depends(require_auth)],
)
async def meter_data_latest(inverter_serial_number: str):
    """Transform current register cache to cloud meter data JSON format."""
    from givlocal.main import app_state

    inv_state = app_state.inverters.get(inverter_serial_number)
    if not inv_state:
        raise HTTPException(status_code=404, detail="Inverter not found")

    result = transform_meter_data(inv_state.plant.inverter)
    return DataResponse(data=result)
