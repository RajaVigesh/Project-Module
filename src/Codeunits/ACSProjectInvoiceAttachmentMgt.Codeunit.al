codeunit 90101 "Proj Invoice Attachment Mgt."
{
    [EventSubscriber(
    ObjectType::Codeunit,
    Codeunit::"Job Create-Invoice",
    'OnAfterCreateSalesLine',
    '',
    false,
    false)]
    local procedure OnAfterCreateSalesLine(
    var SalesLine: Record "Sales Line";
    SalesHeader: Record "Sales Header";
    Job: Record Job;
    var JobPlanningLine: Record "Job Planning Line")
    var
    begin
        if SalesHeader."Document Type" <>
        SalesHeader."Document Type"::Invoice
        then
            exit;
        if Job."No." = '' then
            exit;

        TransferProjectAttachments(
            Job."No.",
            SalesHeader."No.");
    end;


    procedure TransferProjectAttachments(
        SourceProjectNo: Code[20];
        TargetSalesInvoiceNo: Code[20])
    begin
        if not TryTransferProjectAttachments(
            SourceProjectNo,
            TargetSalesInvoiceNo)
        then
            Message(
                TransferFailedMsg,
                TargetSalesInvoiceNo,
                GetLastErrorText());
    end;


    [TryFunction]
    local procedure TryTransferProjectAttachments(
        SourceProjectNo: Code[20];
        TargetSalesInvoiceNo: Code[20])
    var
        SourceAttachment: Record "Document Attachment";
        TargetAttachment: Record "Document Attachment";
        TransferLog: Record "ACS Attachment Transfer Log";
        TargetLineNo: Integer;
    begin
        SourceAttachment.Reset();
        SourceAttachment.SetRange(
            "Table ID",
            Database::Job);
        SourceAttachment.SetRange(
            "No.",
            SourceProjectNo);

        if not SourceAttachment.FindSet() then
            exit;

        repeat
            if not TransferLog.Get(
                SourceProjectNo,
                SourceAttachment.ID,
                TargetSalesInvoiceNo)
            then begin

                Clear(TargetAttachment);
                TargetAttachment.Init();

                TargetAttachment."Table ID" :=
                    Database::"Sales Header";

                TargetAttachment."No." :=
                    TargetSalesInvoiceNo;

                TargetLineNo :=
                    GetNextLineNo(
                        Database::"Sales Header",
                        TargetSalesInvoiceNo,
                        TargetLineNo);

                TargetAttachment."Line No." :=
                    TargetLineNo;

                TargetAttachment.Validate(
                    "File Name",
                    SourceAttachment."File Name");

                TargetAttachment."File Extension" :=
                    SourceAttachment."File Extension";

                TargetAttachment."File Type" :=
                    SourceAttachment."File Type";

                // IMPORTANT:
                // Target is a Sales Invoice, so explicitly
                // set Document Type to Invoice.
                TargetAttachment."Document Type" :=
                    TargetAttachment."Document Type"::Invoice;

                CopyMedia(
                    SourceAttachment,
                    TargetAttachment);

                TargetAttachment.Insert(true);

                TransferLog.Init();

                TransferLog."Source Project No." :=
                    SourceProjectNo;

                TransferLog."Source Attachment ID" :=
                    SourceAttachment.ID;

                TransferLog."Target Sales Invoice No." :=
                    TargetSalesInvoiceNo;

                TransferLog."Transferred At" :=
                    CurrentDateTime;

                TransferLog.Insert(true);
            end;

        until SourceAttachment.Next() = 0;
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
            if DocumentAttachment."Line No." >= CurrentLineNo then
                exit(
                    DocumentAttachment."Line No." + 10000);

        if CurrentLineNo = 0 then
            exit(10000);

        exit(CurrentLineNo + 10000);
    end;


    var
        TransferFailedMsg: Label
        'Project document attachments could not be copied to Sales Invoice %1 automatically (%2). Copy them manually if required.',
        Comment = '%1 = invoice no., %2 = error text';

}
