# Runtime Surfaces Contract

## Workbook Contract

- Workbook mutation is `xlwings-only`.
- `openpyxl` is validation-only.
- Use the sibling `xlwings` runtime surface before blocking.
- Remote workbook escalation uses the `spreadsheet` lane on the `maxfa-wsl` -> `maxfa-win` Office surface.

## Deck Contract

- Generic `.pptx` work uses `PPTXGenJS`.
- Remote think-cell lanes are `think-cell-json-automation-windows`, `think-cell-remote-automation-windows`, and `think-cell-com-automation-windows`.
- Use the JSON-first order: `think-cell-json-automation-windows`, then `think-cell-remote-automation-windows`, then `think-cell-com-automation-windows`.
- `think-cell-com-automation-windows` or VBA is the final escalation lane.

## Remote Office Contract

- macOS is the default local control plane.
- `maxfa-wsl` is the remote control plane for Office workflows.
- `maxfa-win` is the native Office execution surface.
- Skills that may require Windows Office must name the remote escalation lane explicitly.
