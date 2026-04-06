# Runtime Surfaces Contract

## Workbook Contract

- Workbook mutation is `xlwings-only`.
- `openpyxl` is validation-only.
- Use the sibling `xlwings` runtime surface before blocking.

## Deck Contract

- Generic `.pptx` work uses `PPTXGenJS`.
- think-cell JSON lanes come before COM.
- COM or VBA is the final escalation lane.

## Remote Office Contract

- macOS is the default local control plane.
- `maxfa-wsl` is the remote control plane for Office workflows.
- `maxfa-win` is the native Office execution surface.
- Skills that may require Windows Office must name the remote escalation lane explicitly.
