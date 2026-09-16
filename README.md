# ACS Sales Quote → Project → Project Billing Extension

Object ID range 70200000–70200999 (placeholder — substitute the real Cetas/AppSource range in app.json before scaffolding a real environment).

## Object manifest (31 objects — 26 from the FDD inventory + 5 additions)

| ID | Type | Name | Gap | Notes |
|---|---|---|---|---|
| 70200000 | Table Ext | ACS Sales Line Ext (Sales Line) | 1, 2 | +2 resolved-state flags beyond the FDD field list |
| 70200001 | Page Ext | ACS Sales Quote Line Ext (Sales Quote Subform) | 1, 2 | |
| 70200002 | Table Ext | ACS Sales Header Ext (Sales Header) | 4, 5 | +Quote Start/End Date (addition — see below) |
| 70200003 | Page Ext | ACS Sales Quote Ext (Sales Quote) | 4, 5 | |
| 70200004 | Enum | ACS Sales Quote Status | 5 | |
| 70200005 | Codeunit | ACS Vendor Cost Mgt. | 1, 2 | |
| 70200006 | Codeunit | ACS Quote Attachment Transfer | 3 | |
| 70200007 | Codeunit | ACS Quote To Project Mgt. | 4 | Owns Create Project end-to-end — see Assumption A |
| 70200008 | Page | ACS Existing Project Lookup | 4 | |
| 70200009 | Codeunit | ACS Sales Quote Status Mgt. | 5 | |
| 70200010 | Page | ACS Sales Quote List All | 5 | |
| 70200011 | Table Ext | ACS Item Ext (Item) | 7 | |
| 70200012 | Enum | ACS Item Approval Status | 7 | |
| 70200013 | Page Ext | ACS Item Card Ext | 7 | |
| 70200014 | Codeunit | ACS Item Approval Mgt. | 7 | Workflow integration — see Assumption C |
| 70200015 | Table Ext | ACS Job Planning Line Ext | 6 | +Source Quote No./Line No. traceability fields |
| 70200016 | Codeunit | ACS Project Task Creation Mgt. | 6 | |
| 70200017 | Table | ACS Vendor Activity Header | 8 | |
| 70200018 | Table | ACS Vendor Activity Line | 8, 9 | +Qty To Invoice Updated flag |
| 70200019 | Page | ACS Vendor Activity Confirmation | 8 | |
| 70200020 | Codeunit | ACS Vendor Activity Mgt. | 8 | Workflow integration — see Assumption C |
| 70200021 | Table Ext | ACS Approval Entry Ext | 8 | |
| 70200022 | Codeunit | ACS Qty To Invoice Mgt. | 9 | |
| 70200023 | Codeunit | ACS Project Invoice Attachment Mgt. | 10 | |
| 70200024 | Table | ACS Attachment Transfer Log | 10 | |
| 70200025 | Permission Set | ACS Sales Project Ext | — | |
| 70200026 | Enum | ACS Vendor Activity Status | 8 | Implied by the FDD field table; not separately listed |
| 70200027 | Page | ACS Vendor Activity Subform | 8 | **Addition** — line part for the header/lines document page |
| 70200028 | Page Ext | ACS Sales Quote List Ext | 5 | **Addition** — rule 4 (hardcoded Open-only default view) has no object in the inventory table |
| 70200029 | Table Ext | ACS Purchase Price Ext | 2 | **Addition** — see Assumption B |
| 70200031 | Table Ext | ACS Job Journal Line Ext | 9 | **Addition** — exact traceability back to the source Vendor Activity Line |

## Assumptions requiring ACS confirmation (beyond the FDD's own Open Questions 1–5)

**A. Create Project / PEP consolidation (Gap 4, `ACS Quote To Project Mgt.`) — [Speculative]**
The FDD references an existing "Create Project" action and an existing item-lookup-by-category customization on Sales Quote Lines, neither of which is in this object inventory. Standard Business Central has no native "create a Job from a Sales Quote" feature, so this is almost certainly a prior ACS customization. Rather than guess its codeunit/event name and risk a subscriber that silently never fires, `ACS Quote To Project Mgt.` owns the whole flow as a new, separately named action (`ACS Create Project`). **If a prior Create Project codeunit already exists, give me its name/signature and I'll wire this as a subscriber instead** — the task/planning-line creation, attach validation, and attachment transfer are already factored out so that swap is contained to one procedure (`CreateNewProject`).

**B. Purchase Price List dimension filter (Gap 2) — [Speculative]**
The FDD says to filter "Purchase Price List... by Customer Code dimension" but no such field exists on table `Purchase Price`, and it's unclear whether ACS's environment uses that legacy table or the modern Price List Header/Line. Implemented against `Purchase Price` (matches the FDD's literal wording, simplest structure) with a new `ACS Customer Code` field added directly (object 70200029). **Confirm which pricing table is actually in use and how the Customer Code dimension is captured on it** — this is the single most likely thing to need rework.

**C. Approval Workflow extensibility for Item and Vendor Activity Line (Gaps 7, 8) — [Speculative]**
Both `ACS Item Approval Mgt.` and `ACS Vendor Activity Mgt.` register a new workflow event via `Codeunit "Workflow Event Handling".AddEventToLibrary` and trigger it via `Codeunit "Workflow Management".HandleEvent`, per the standard (but sparsely documented) pattern for extending approvals to a new record type. This is the least-certain integration point in the codebase — **compile and unit-test these two codeunits first**. The approval *outcome* handling (status sync back to Item / Vendor Activity Line) is written generically against the standard `Approval Entry` table's insert/modify events and doesn't depend on the registration details being exactly right.

**D. Job Journal posting event name (Gap 9) — [Likely]**
`ACS Qty To Invoice Mgt.` subscribes to `Codeunit "Job Jnl.-Post Line", OnAfterPostJobJnlLine`, inferred by analogy with the item/resource journal posting codeunits. Verify this against the actual base app version.

**E. Job → Sales Invoice attachment trigger (Gap 10) — [Likely]**
Standard BC does have a native Job Planning Line → Sales Invoice flow (`Codeunit "Job Create-Invoice"`), so this is not a phantom dependency like A/B above. No explicit "invoice successfully created from job" event was found under that description, so the codeunit hooks off `Sales Line` `OnAfterInsertEvent` (Document Type = Invoice, Job No. populated) instead. This design is idempotent by construction (the transfer log's primary key), so it's safe even though it may fire more than once per invoice.

## Deployment prerequisites (not created by this extension)

- General Ledger Setup: Shortcut Dimension 5 must be configured (validated at runtime, errors clearly if missing).
- Job Journal Template `JOB` / Batch `ACSVENDACT` (or update the two `Tok` constants in `ACS Vendor Activity Mgt.CreateAndPostJobJournalLine` to match ACS's real batch).
- Workflow Setup: an approval workflow enabled for the two new workflow events (Item send-for-approval, Vendor Activity submit-for-approval) and for the Finance approver group (Gap 7, rule 6 — no role-checking code, by design).
- Assign permission set `ACS Sales Project Ext` to relevant users/groups.
- `app.json` `platform`/`application`/`runtime` versions are placeholders — set to the target environment's actual versions.

## Resolved FDD open questions (implemented as stated in the FDD; flag back if wrong)

1. Zero-Unit-Price Gross Margin % → 0%.
2. Existing-project dimension match → Shortcut Dimension 5 Code, same slot on Job and Sales Header.
3. Item mandatory-field list for Send for Approval → Description, Base Unit of Measure, Item Category Code only.
4. Vendor Activity approval → Job Journal posting → auto-post (not staged for a separate confirmed run).
5. Item Status terminology → `Rejected` used consistently (not "Inactive").
