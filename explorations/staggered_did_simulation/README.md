# Staggered DID Simulation

This self-contained exploration simulates staggered treatment adoption and compares
a conventional TWFE specification with Callaway–Sant'Anna group-time ATT estimates
produced by `csdid`.

## Run

From the repository root:

```powershell
scripts\run_stata.bat explorations\staggered_did_simulation\dofiles\01_csdid_simulation.do
```

The lightweight `dofiles/00_check_csdid.do` file can be used to check whether the
required `csdid` command is installed before running the simulation.

## Outputs

- Log: `explorations/staggered_did_simulation/logs/01_csdid_simulation.log`
- Tables: `explorations/staggered_did_simulation/output/tables/`
- Figures: `explorations/staggered_did_simulation/output/figures/`

The generated tables report the TWFE baseline, overall ATT, and event-time ATT. The
event-study figure is exported as both PDF and PNG. This remains an exploration and
is not wired into `dofiles/00_master.do`.
