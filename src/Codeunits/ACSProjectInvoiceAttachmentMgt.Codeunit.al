codeunit 70200023 "ACS Project Invoice Attachment Mgt."
{
    // [Likely] Hooks off Sales Line OnAfterInsertEvent (Document Type = Invoice, Job No.
    // populated) rather than a specific "Project Billing success" event, since the base
    // Job-to-Sales-Invoice flow (Codeunit "Job Create-Invoice") doesn't appear to publish an
    // explicit event under that description. This design is idempotent by construction (see
    // the log table's primary key below), so firing once per qualifying Sales Line - rather
    // than needing to fire exactly once per invoice - is safe, not risky.
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesLine(var Rec: Record "Sales Line")
    begin
        if Rec."Document Type" <> Rec."Document Type"::Invoice then
            exit;
        if Rec."Job No." = '' then
            exit;

        TransferProjectAttachments(Rec."Job No.", Rec."Document No.");
    end;

    procedure TransferProjectAttachments(SourceProjectNo: Code[20]; TargetSalesInvoiceNo: Code[20])
    begin
        if not TryTransferProjectAttachments(SourceProjectNo, TargetSalesInvoiceNo) then
            Message(TransferFailedMsg, GetLastErrorText);
    end;

    [TryFunction]
    local procedure TryTransferProjectAttachments(SourceProjectNo: Code[20]; TargetSalesInvoiceNo: Code[20])
    var
        SourceAttachment: Record "Document Attachment";
        TargetAttachment: Record "Document Attachment";
        TransferLog: Record "ACS Attachment Transfer Log";
    begin
        SourceAttachment.SetRange("Table ID", Database::Job);
        SourceAttachment.SetRange("No.", SourceProjectNo);
        if not SourceAttachment.FindSet() then
            exit; // zero project attachments - continues without error (rule 5)

        repeat
            // Primary key on the log enforces no-duplicate-transfer at the data level
            // (rule per the table definition), not just via this in-code check.
            if not TransferLog.Get(SourceProjectNo, SourceAttachment.ID, TargetSalesInvoiceNo) then begin
                TargetAttachment.Init();
                TargetAttachment."Table ID" := Database::"Sales Invoice Header";
                TargetAttachment."No." := TargetSalesInvoiceNo;
                TargetAttachment.Validate("File Name", SourceAttachment."File Name");
                TargetAttachment."File Extension" := SourceAttachment."File Extension";
                TargetAttachment."File Type" := SourceAttachment."File Type";
                TargetAttachment.Content := SourceAttachment.Content;
                TargetAttachment."Document Type" := SourceAttachment."Document Type";
                TargetAttachment.Insert(true);
                // Original Project attachment is never modified or removed (rule 7).

                TransferLog.Init();
                TransferLog."Source Project No." := SourceProjectNo;
                TransferLog."Source Attachment ID" := SourceAttachment.ID;
                TransferLog."Target Sales Invoice No." := TargetSalesInvoiceNo;
                TransferLog."Transferred At" := CurrentDateTime;
                TransferLog.Insert(true);
            end;
        until SourceAttachment.Next() = 0;
        // Attachments added to the Project after invoice creation are not retroactively
        // transferred (rule 6) - there is no background sync job here by design.
    end;

    var
        TransferFailedMsg: Label 'Project document attachments could not be copied to Sales Invoice %1 automatically (%2). Copy them manually if required.', Comment = '%1 = invoice no., %2 = error text';
}
