codeunit 70200006 "ACS Quote Attachment Transfer"
{
    // Called directly from ACS Quote To Project Mgt. strictly after a confirmed successful
    // Project creation/attach (never from a base-app event, so sequencing rule 5 - "if
    // Project creation fails, this must not run at all" - is satisfied by construction, not
    // by subscription timing).
    procedure TransferAttachments(SourceQuoteNo: Code[20]; TargetProjectNo: Code[20])
    begin
        if not TryTransferAttachments(SourceQuoteNo, TargetProjectNo) then
            Message(TransferFailedMsg, GetLastErrorText);
    end;

    [TryFunction]
    local procedure TryTransferAttachments(SourceQuoteNo: Code[20]; TargetProjectNo: Code[20])
    var
        SourceAttachment: Record "Document Attachment";
        TargetAttachment: Record "Document Attachment";
    begin
        SourceAttachment.SetRange("Table ID", Database::"Sales Header");
        SourceAttachment.SetRange("No.", SourceQuoteNo);
        if not SourceAttachment.FindSet() then
            exit; // zero attachments - exit silently, no error

        repeat
            TargetAttachment.Init();
            TargetAttachment."Table ID" := Database::Job;
            TargetAttachment."No." := TargetProjectNo;
            TargetAttachment.Validate("File Name", SourceAttachment."File Name");
            TargetAttachment."File Extension" := SourceAttachment."File Extension";
            TargetAttachment."File Type" := SourceAttachment."File Type";
            TargetAttachment.Content := SourceAttachment.Content;
            TargetAttachment."Document Type" := SourceAttachment."Document Type";
            TargetAttachment.Insert(true);
        until SourceAttachment.Next() = 0;
        // Source attachments are never modified or deleted.
    end;

    var
        TransferFailedMsg: Label 'Document attachments could not be copied to the new project automatically (%1). Copy them manually if required.', Comment = '%1 = error text';
}
