codeunit 70200022 "ACS Qty To Invoice Mgt."
{
    // [Likely] "Job Jnl.-Post Line" publishing OnAfterPostJobJnlLine mirrors the equivalent
    // event on the item/resource journal posting codeunits - verify the exact event name
    // against the target base app version before deploying.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnAfterPostJobJnlLine', '', false, false)]
    local procedure OnAfterPostJobJnlLine(JobJournalLine: Record "Job Journal Line")
    begin
        if not TryUpdateQtyToInvoice(JobJournalLine) then
            LogFailure(JobJournalLine, GetLastErrorText);
        // Wrapped in TryFunction (rule 6) - this must never block or roll back the job
        // journal posting itself, which has already completed by the time this fires.
    end;

    [TryFunction]
    local procedure TryUpdateQtyToInvoice(JobJournalLine: Record "Job Journal Line")
    var
        ActivityLine: Record "ACS Vendor Activity Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        if JobJournalLine."ACS Vendor Activity Batch Name" = '' then
            exit; // this posted line didn't originate from a vendor activity confirmation

        if not ActivityLine.Get(JobJournalLine."ACS Vendor Activity Batch Name", JobJournalLine."ACS Vendor Activity Line No.") then
            exit;

        // Rule 4 - the same vendor activity line never updates Qty. to Invoice more than
        // once, even on a retry/reversal replay of the posting event.
        if ActivityLine."ACS Qty To Invoice Updated" then
            exit;

        if not JobPlanningLine.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.") then
            exit;

        // Rule 5 - this only sets an initial value; Finance can freely override it
        // afterwards, so the field is never locked here.
        JobPlanningLine.Validate("Qty. to Invoice", JobPlanningLine."Qty. to Invoice" + JobJournalLine.Quantity);
        JobPlanningLine.Modify(true);

        ActivityLine."ACS Qty To Invoice Updated" := true;
        ActivityLine.Modify(true);
    end;

    local procedure LogFailure(JobJournalLine: Record "Job Journal Line"; ErrorText: Text)
    begin
        // Posting already succeeded - surface the miss without disrupting the user's flow.
        Message(QtyToInvoiceUpdateFailedMsg, JobJournalLine."Job No.", JobJournalLine."Job Task No.", ErrorText);
    end;

    var
        QtyToInvoiceUpdateFailedMsg: Label 'Qty. to Invoice could not be updated automatically for Job %1, Job Task %2 (%3). Update it manually before invoicing.', Comment = '%1 = job no., %2 = job task no., %3 = error text';
}
