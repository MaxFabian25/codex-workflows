# Runtime Surfaces Contract

## Workbook Contract

- Workbook mutation is `xlwings-only`.
- `openpyxl` is validation-only.
- Use the sibling `xlwings` runtime surface before blocking.
- Remote workbook escalation uses the `spreadsheet` lane on a remote Linux control plane that hands off to a Windows Office host.

## Deck Contract

- Generic `.pptx` work uses `PPTXGenJS`.
- Local mac think-cell work uses `think-cell-json-automation`.
- Think-cell routing order is `think-cell-json-automation`, then `think-cell-json-automation-windows`, then `think-cell-remote-automation-windows`, then `think-cell-com-automation-windows`.
- `think-cell-com-automation-windows` or VBA is the final escalation lane.

## Remote Office Contract

- macOS is the default local control plane.
- A remote Linux environment can act as the control plane for Office workflows.
- A paired Windows host is the native Office execution surface.
- Skills that may require Windows Office must name the remote escalation lane explicitly.
