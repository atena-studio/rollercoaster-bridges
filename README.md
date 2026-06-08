# atena-bridges-rollercoaster

Integration bridges for the `atena-std-rollercoaster` standalone resource, one per framework.

| Framework | Bridge | Status |
|-----------|--------|--------|
| atena     | `atena-bridge-rollercoaster` | present |
| ESX       | `esx-bridge-rollercoaster`   | planned |
| QBCore    | `qbcore-bridge-rollercoaster`| planned |
| OX        | `ox-bridge-rollercoaster`    | planned |

Each bridge is integration glue (calls `exports['atena-std-rollercoaster']:*` + the framework's API). The standalone
stays pure/agnostic. Advanced atena-only mechanics a framework can't map are left as a documented comment.
Install `atena-std-rollercoaster` + the ONE bridge matching your framework.
