# rollercoaster-bridges

Integration bridges for the `std-rollercoaster` standalone resource, one per framework.

| Framework | Bridge | Status |
|-----------|--------|--------|
| atena     | `atena-bridge-rollercoaster` | present |
| ESX       | `esx-bridge-rollercoaster`   | planned |
| QBCore    | `qbcore-bridge-rollercoaster`| planned |
| OX        | `ox-bridge-rollercoaster`    | planned |

Each bridge is integration glue (calls `exports['std-rollercoaster']:*` + the framework's API). The standalone
stays pure/agnostic. Advanced atena-only mechanics a framework can't map are left as a documented comment.
Install `std-rollercoaster` + the ONE bridge matching your framework.

## Get the standalone (required)

This bridge is free integration glue and needs the **std-rollercoaster** standalone resource (sold separately):

➡️ **https://github.com/atena-studio/std-rollercoaster**
