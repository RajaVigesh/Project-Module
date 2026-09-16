codeunit 90113 "ACS Job Invoice Field Flow"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnAfterUpdateSalesHeader', '', false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Sales Header"; Job: Record Job)
    var
        WorkDescriptionInStream: InStream;
        WorkDescriptionOutStream: OutStream;
        DimensionManagement: Codeunit "DimensionManagement";
        DimensionSetEntry: Record "Dimension Set Entry" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin

        SalesHeader.Validate("External Document No.", CopyStr(Job."Customer PO Number", 1, MaxStrLen(SalesHeader."External Document No.")));
        SalesHeader.Validate("Salesperson Code", Job."Sales Person Code");
        SalesHeader.Validate("Shortcut Dimension 1 Code", Job."Global Dimension 1 Code");
        SalesHeader.Validate("Shortcut Dimension 2 Code", Job."Global Dimension 2 Code");
        SalesHeader.Validate("Shortcut Dimension 3 Code", Job."ShortCut Dimension 3 code");
        SalesHeader.Validate("Shortcut Dimension 4 Code", Job."ShortCut Dimension 4 code");
        SalesHeader.Validate("Shortcut Dimension 5 Code", Job."ShortCut Dimension 5 code");
        SalesHeader.Validate("Shortcut Dimension 6 Code", Job."ShortCut Dimension 6 code");
        SalesHeader.Validate("Shortcut Dimension 7 Code", Job."ShortCut Dimension 7 code");
        SalesHeader.Validate("Shortcut Dimension 8 Code", Job."ShortCut Dimension 8 code");

        SalesHeader.Validate("Salesperson Code", Job."Sales Person Code");
        salesHeader.Validate("SO START DATE", Job."Starting Date");
        salesHeader.Validate("SO END DATE", Job."Ending Date");
        salesHeader.Validate("External Document No.", Job."Customer PO Number");
        salesHeader.Validate("Your Reference", Job."Your Reference");
        salesHeader.Validate("Bill-to Contact", Job."Bill-to Contact");
        salesHeader.Validate("Sell-to Contact", Job."Sell-to Contact");
        salesHeader.Validate("Posting Description", job."Your Reference" + '  ' + job."Customer PO Number");
        Job.CalcFields("CIT Work Description");
        Job."CIT Work Description".CreateInStream(WorkDescriptionInStream);
        SalesHeader."Work Description".CreateOutStream(WorkDescriptionOutStream);
        CopyStream(WorkDescriptionOutStream, WorkDescriptionInStream);

        SalesHeader.Modify(true);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Create-Invoice", 'OnAfterCreateSalesLine', '', false, false)]
    local procedure OnAfterCreateSalesLine(
        var SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line")
    begin
        if JobPlanningLine."ACS Item Category Code" = '' then
            exit;

        SalesLine.Validate("Item Category Code", JobPlanningLine."ACS Item Category Code");
        SalesLine.Validate("CIT No.", JobPlanningLine."No.");
        SalesLine.Validate("Unit Price", JobPlanningLine."Unit Price");
        SalesLine.Validate("Item Reference No.", JobPlanningLine."Item Reference No.");
        SalesLine.Validate("Job No.", JobPlanningLine."Job No.");
        SalesLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        SalesLine.Validate("Shortcut Dimension 1 Code", Job."Global Dimension 1 Code");
        SalesLine.Validate("Shortcut Dimension 2 Code", Job."Global Dimension 2 Code");
        SalesLine.Validate("CIT Shortcut Dimension 3 Code", Job."ShortCut Dimension 3 code");
        SalesLine.Validate("CIT Shortcut Dimension 4 Code", Job."ShortCut Dimension 4 code");
        SalesLine.Validate("CIT Shortcut Dimension 5 Code", Job."ShortCut Dimension 5 code");
        SalesLine.Validate("CIT Shortcut Dimension 6 Code", Job."ShortCut Dimension 6 code");
        SalesLine.Validate("CIT Shortcut Dimension 7 Code", Job."ShortCut Dimension 7 code");
        SalesLine.Validate("CIT Shortcut Dimension 8 Code", Job."ShortCut Dimension 8 code");
        // SalesLine.Validate("Planning Line No.", JobPlanningLine."Line No.");
        SalesLine.Modify(true);

        Salesheader.Validate("Dimension Set ID", SalesLine."Dimension Set ID");
        Salesheader.Modify(true);
    end;
}
