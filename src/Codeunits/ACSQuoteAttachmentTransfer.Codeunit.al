codeunit 90104 "ACS Quote Attachment Transfer"
{
    procedure TransferAttachments(
        SourceQuoteNo: Code[20];
        TargetProjectNo: Code[20])
    begin
        if not TryTransferAttachments(SourceQuoteNo, TargetProjectNo) then
            Message(
                TransferFailedMsg,
                GetLastErrorText());
    end;


    [TryFunction]
    local procedure TryTransferAttachments(
        SourceQuoteNo: Code[20];
        TargetProjectNo: Code[20])
    var
        SourceAttachment: Record "Document Attachment";
        TargetAttachment: Record "Document Attachment";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // ================================================================
        // SALES QUOTE HEADER ATTACHMENTS -> JOB
        // ================================================================

        SourceAttachment.Reset();
        SourceAttachment.SetRange(
            "Table ID",
            Database::"Sales Header");
        SourceAttachment.SetRange(
            "No.",
            SourceQuoteNo);

        if SourceAttachment.FindSet() then
            repeat
                CopyAttachmentToJob(
                    SourceAttachment,
                    TargetProjectNo);
            until SourceAttachment.Next() = 0;


        // ================================================================
        // SALES LINE ATTACHMENTS -> JOB PLANNING LINE
        // ================================================================

        SourceAttachment.Reset();
        SourceAttachment.SetRange(
            "Table ID",
            Database::"Sales Line");
        SourceAttachment.SetRange(
            "No.",
            SourceQuoteNo);

        if SourceAttachment.FindSet() then
            repeat

                JobPlanningLine.Reset();
                JobPlanningLine.SetRange(
                    "ACS Source Quote No.",
                    SourceQuoteNo);
                JobPlanningLine.SetRange(
                    "ACS Source Quote Line No.",
                    SourceAttachment."Line No.");
                JobPlanningLine.SetRange(
                    "Job No.",
                    TargetProjectNo);

                if JobPlanningLine.FindSet() then
                    repeat
                        CopyAttachmentToPlanningLine(
                            SourceAttachment,
                            JobPlanningLine);
                    until JobPlanningLine.Next() = 0;

            until SourceAttachment.Next() = 0;
    end;


    local procedure CopyAttachmentToJob(
        SourceAttachment: Record "Document Attachment";
        TargetJobNo: Code[20])
    var
        TargetAttachment: Record "Document Attachment";
    begin
        Clear(TargetAttachment);

        TargetAttachment.Init();

        TargetAttachment."Table ID" :=
            Database::Job;

        TargetAttachment."No." :=
            TargetJobNo;

        TargetAttachment."Line No." :=
            GetNextLineNo(
                Database::Job,
                TargetJobNo,
                0);

        TargetAttachment.Validate(
            "File Name",
            SourceAttachment."File Name");

        TargetAttachment."File Extension" :=
            SourceAttachment."File Extension";

        TargetAttachment."File Type" :=
            SourceAttachment."File Type";

        CopyMedia(
            SourceAttachment,
            TargetAttachment);

        TargetAttachment.Insert(true);
    end;


    local procedure CopyAttachmentToPlanningLine(
        SourceAttachment: Record "Document Attachment";
        JobPlanningLine: Record "Job Planning Line")
    var
        TargetAttachment: Record "Document Attachment";
    begin
        Clear(TargetAttachment);

        TargetAttachment.Init();

        TargetAttachment."Table ID" :=
            Database::"Job Planning Line";

        TargetAttachment."No." :=
            JobPlanningLine."Job No.";

        TargetAttachment."Line No." :=
            JobPlanningLine."Line No.";

        TargetAttachment.Validate(
            "File Name",
            SourceAttachment."File Name");

        TargetAttachment."File Extension" :=
            SourceAttachment."File Extension";

        TargetAttachment."File Type" :=
            SourceAttachment."File Type";

        CopyMedia(
            SourceAttachment,
            TargetAttachment);

        TargetAttachment.Insert(true);
    end;


    local procedure CopyMedia(
        SourceAttachment: Record "Document Attachment";
        var TargetAttachment: Record "Document Attachment")
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        if not SourceAttachment."Document Reference ID".HasValue() then
            Error(
                'Source attachment "%1" does not contain a document.',
                SourceAttachment."File Name");

        Clear(TempBlob);

        TempBlob.CreateOutStream(OutStr);

        SourceAttachment."Document Reference ID".ExportStream(
            OutStr);

        TempBlob.CreateInStream(InStr);

        TargetAttachment."Document Reference ID".ImportStream(
            InStr,
            SourceAttachment."File Name");
    end;


    local procedure GetNextLineNo(
        TableID: Integer;
        DocumentNo: Code[20];
        CurrentLineNo: Integer): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Reset();

        DocumentAttachment.SetRange(
            "Table ID",
            TableID);

        DocumentAttachment.SetRange(
            "No.",
            DocumentNo);

        if DocumentAttachment.FindLast() then
            exit(DocumentAttachment."Line No." + 10000);

        exit(10000);
    end;


    var
        TransferFailedMsg: Label
            'Document attachments could not be copied to the new project automatically (%1). Copy them manually if required.',
            Comment = '%1 = error text';
}