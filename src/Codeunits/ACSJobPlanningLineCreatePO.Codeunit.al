codeunit 90109 "Job Planning Line-Create PO"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Order then
            exit;

        JobPlanningLine.SetRange("Purchase Order No.", Rec."No.");
        if JobPlanningLine.FindSet(true) then
            repeat
                JobPlanningLine.Validate("Purchase Order No.", '');
                JobPlanningLine.Modify(true);
            until JobPlanningLine.Next() = 0;
    end;

    var
        NoLinesErr: Label 'No planning lines are selected.';
        JobNotOpenErr: Label 'Job %1 is not open. Select lines on open jobs only.', Comment = '%1 = Job No.';
        MissingVendorErr: Label 'Vendor No. is missing on these planning lines (Job / Task / Line): %1', Comment = '%1 = list';
        TypeNotSupportedErr: Label 'Planning line %1 / %2 / %3 has a type that cannot be purchased.', Comment = '%1 = Job No., %2 = Task No., %3 = Line No.';
        NothingToOrderMsg: Label 'Nothing to order. %1 line(s) are already covered by purchase orders.', Comment = '%1 = count';
        ResultMsg: Label '%1 purchase order(s) created. %2 line(s) skipped.', Comment = '%1 = PO count, %2 = skipped count';
        NoPurchaseOrdersMsg: Label 'No purchase orders have been created for job %1.', Comment = '%1 = Job No.';
        NoPostedPurchaseInvoicesMsg: Label 'No posted purchase invoices have been created for job %1.', Comment = '%1 = Job No.';


    procedure CreatePOs(var SelectedLines: Record "Job Planning Line")
    var
        TempJPL: Record "Job Planning Line" temporary;
        PurchHeader: Record "Purchase Header";
        Vendors: List of [Code[20]];
        CreatedPOs: List of [Code[20]];
        JobNos: List of [Code[20]];
        JobNo: Code[20];
        VendorNo: Code[20];
        CreatedPONo: Code[20];
        SkippedCount: Integer;
    begin
        SelectedLines.SetFilter(
            "ACS CIT Vendor No.",
            '<>%1',
            '');

        if SelectedLines.FindSet() then
            repeat
                JobNo := SelectedLines."Job No.";
                if not JobNos.Contains(JobNo) then
                    JobNos.Add(JobNo);
            until SelectedLines.Next() = 0;

        BufferAndValidate(
            SelectedLines,
            TempJPL,
            Vendors);

        foreach VendorNo in Vendors do begin
            TempJPL.Reset();
            TempJPL.SetRange(
                "ACS CIT Vendor No.",
                VendorNo);

            CreatedPONo :=
                CreatePOForVendor(
                    TempJPL,
                    VendorNo,
                    SkippedCount);

            if CreatedPONo <> '' then
                CreatedPOs.Add(CreatedPONo);
        end;

        foreach JobNo in JobNos do
            UpdateJobPOStatus(JobNo);

        Commit();

        if CreatedPOs.Count() = 0 then begin
            Message(
                NothingToOrderMsg,
                SkippedCount);
            exit;
        end;

        Message(
            ResultMsg,
            CreatedPOs.Count(),
            SkippedCount);

        OpenCreatedPurchaseOrders(CreatedPOs);
    end;


    procedure CreatePOsForJob(JobNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange(
            "Job No.",
            JobNo);

        if JobPlanningLine.IsEmpty() then
            Error(NoLinesErr);

        CreatePOs(JobPlanningLine);
    end;


    procedure ShowPurchaseOrdersForJob(JobNo: Code[20]; JobTaskNo: Code[20]; LineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrders: List of [Code[20]];
        PurchaseOrderNo: Code[20];
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange(
            "Document Type",
            PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(
            "Job No.",
            JobNo);
        PurchaseLine.SetRange("Job Task No.", JobTaskNo);
        PurchaseLine.SetRange("Job Planning Line No.", LineNo);
        if PurchaseLine.FindSet() then
            repeat
                PurchaseOrderNo := PurchaseLine."Document No.";
                if not PurchaseOrders.Contains(PurchaseOrderNo) then
                    PurchaseOrders.Add(PurchaseOrderNo);
            until PurchaseLine.Next() = 0;

        if PurchaseOrders.Count() = 0 then begin
            Message(
                NoPurchaseOrdersMsg,
                JobNo);
            exit;
        end;

        PurchaseHeader.Reset();
        PurchaseHeader.SetRange(
            "Document Type",
            PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter(
            "No.",
            BuildNoFilter(PurchaseOrders));

        Page.Run(
            Page::"Purchase Order List",
            PurchaseHeader);
    end;


    procedure ShowAllPurchaseOrdersForJob(JobNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrders: List of [Code[20]];
        PurchaseOrderNo: Code[20];
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange(
            "Document Type",
            PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(
            "Job No.",
            JobNo);

        if PurchaseLine.FindSet() then
            repeat
                PurchaseOrderNo := PurchaseLine."Document No.";
                if not PurchaseOrders.Contains(PurchaseOrderNo) then
                    PurchaseOrders.Add(PurchaseOrderNo);
            until PurchaseLine.Next() = 0;

        if PurchaseOrders.Count() = 0 then begin
            Message(
                NoPurchaseOrdersMsg,
                JobNo);
            exit;
        end;

        PurchaseHeader.Reset();
        PurchaseHeader.SetRange(
            "Document Type",
            PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter(
            "No.",
            BuildNoFilter(PurchaseOrders));

        Page.Run(
            Page::"Purchase Order List",
            PurchaseHeader);
    end;


    procedure ShowPostedPurchaseInvoicesForJob(JobNo: Code[20]; JobTaskNo: Code[20]; LineNo: Integer)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedInvoices: List of [Code[20]];
        PostedInvoiceNo: Code[20];
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetRange(
            "Job No.",
            JobNo);
        PurchInvLine.SetRange("Job Task No.", JobTaskNo);
        PurchInvLine.SetRange("Job Planning Line No.", LineNo);
        if PurchInvLine.FindSet() then
            repeat
                PostedInvoiceNo := PurchInvLine."Document No.";
                if not PostedInvoices.Contains(PostedInvoiceNo) then
                    PostedInvoices.Add(PostedInvoiceNo);
            until PurchInvLine.Next() = 0;

        if PostedInvoices.Count() = 0 then begin
            Message(
                NoPostedPurchaseInvoicesMsg,
                JobNo);
            exit;
        end;

        PurchInvHeader.Reset();
        PurchInvHeader.SetFilter(
            "No.",
            BuildNoFilter(PostedInvoices));

        Page.Run(
            Page::"Posted Purchase Invoices",
            PurchInvHeader);
    end;


    procedure ShowAllPostedPurchaseInvoicesForJob(JobNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedInvoices: List of [Code[20]];
        PostedInvoiceNo: Code[20];
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetRange(
            "Job No.",
            JobNo);

        if PurchInvLine.FindSet() then
            repeat
                PostedInvoiceNo := PurchInvLine."Document No.";
                if not PostedInvoices.Contains(PostedInvoiceNo) then
                    PostedInvoices.Add(PostedInvoiceNo);
            until PurchInvLine.Next() = 0;

        if PostedInvoices.Count() = 0 then begin
            Message(
                NoPostedPurchaseInvoicesMsg,
                JobNo);
            exit;
        end;

        PurchInvHeader.Reset();
        PurchInvHeader.SetFilter(
            "No.",
            BuildNoFilter(PostedInvoices));

        Page.Run(
            Page::"Posted Purchase Invoices",
            PurchInvHeader);
    end;


    local procedure BufferAndValidate(
        var SelectedLines: Record "Job Planning Line";
        var TempJPL: Record "Job Planning Line" temporary;
        var Vendors: List of [Code[20]])
    var
        Job: Record Job;
        MissingVendorLines: Text;
    begin
        TempJPL.Reset();
        TempJPL.DeleteAll();

        Clear(Vendors);

        if not SelectedLines.FindSet() then
            Error(NoLinesErr);

        repeat
            Job.Reset();

            if not Job.Get(
                SelectedLines."Job No.")
            then
                Error(
                    JobNotOpenErr,
                    SelectedLines."Job No.");

            if Job.Status <> Job.Status::Open then
                Error(
                    JobNotOpenErr,
                    Job."No.");

            /*
                Text lines are not purchaseable.
                We keep them in the temporary buffer only if
                a vendor is already assigned, so they can be
                added as comments to the corresponding PO.
            */
            if SelectedLines.Type = SelectedLines.Type::Text then begin
                if SelectedLines."ACS CIT Vendor No." <> '' then begin
                    AddVendor(
                        Vendors,
                        SelectedLines."ACS CIT Vendor No.");

                    TempJPL := SelectedLines;
                    TempJPL.Insert();
                end;
            end else begin

                if SelectedLines."ACS CIT Vendor No." = '' then begin
                    MissingVendorLines +=
                        StrSubstNo(
                            '%1 / %2 / %3; ',
                            SelectedLines."Job No.",
                            SelectedLines."Job Task No.",
                            SelectedLines."Line No.");
                end else begin

                    AddVendor(
                        Vendors,
                        SelectedLines."ACS CIT Vendor No.");

                    TempJPL := SelectedLines;
                    TempJPL.Insert();
                end;
            end;

        until SelectedLines.Next() = 0;

        if MissingVendorLines <> '' then
            Error(
                MissingVendorErr,
                CopyStr(
                    MissingVendorLines,
                    1,
                    StrLen(MissingVendorLines) - 2));
    end;


    local procedure AddVendor(
        var Vendors: List of [Code[20]];
        VendorNo: Code[20])
    begin
        if VendorNo = '' then
            exit;

        if not Vendors.Contains(VendorNo) then
            Vendors.Add(VendorNo);
    end;


    local procedure UpdateJobPOStatus(JobNo: Code[20])
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        RemainingQty: Decimal;
        HasCoveredLine: Boolean;
        HasUncoveredLine: Boolean;
    begin
        if not Job.Get(JobNo) then
            exit;

        JobPlanningLine.Reset();
        JobPlanningLine.SetRange(
            "Job No.",
            JobNo);
        JobPlanningLine.SetFilter(
            "ACS CIT Vendor No.",
            '<>%1',
            '');

        if JobPlanningLine.FindSet() then
            repeat
                if JobPlanningLine.Type <> JobPlanningLine.Type::Text then begin
                    RemainingQty :=
                        RemainingQtyToOrder(JobPlanningLine);

                    if RemainingQty < JobPlanningLine.Quantity then
                        HasCoveredLine := true;

                    if RemainingQty > 0 then
                        HasUncoveredLine := true;
                end;
            until JobPlanningLine.Next() = 0;

        if not HasCoveredLine then
            Job.Validate(
                "PO Status",
                Job."PO Status"::Open)
        else
            if HasUncoveredLine then
                Job.Validate(
                    "PO Status",
                    Job."PO Status"::"Partially Created")
            else
                Job.Validate(
                    "PO Status",
                    Job."PO Status"::Created);

        Job.Modify(true);
    end;


    local procedure SetPlanningLinePurchaseOrderNo(
        JobPlanningLine: Record "Job Planning Line";
        PurchaseOrderNo: Code[20])
    var
        PlanningLine: Record "Job Planning Line";
    begin
        if not PlanningLine.Get(
            JobPlanningLine."Job No.",
            JobPlanningLine."Job Task No.",
            JobPlanningLine."Line No.")
        then
            exit;

        PlanningLine.Validate(
            "Purchase Order No.",
            PurchaseOrderNo);
        PlanningLine.Modify(true);
    end;


    local procedure CreatePOForVendor(
        var TempJPL: Record "Job Planning Line" temporary;
        VendorNo: Code[20];
        var SkippedCount: Integer): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        RemainingQty: Decimal;
        NextLineNo: Integer;
        HasOrderableLine: Boolean;
    begin
        TempJPL.Reset();
        TempJPL.SetRange(
            "ACS CIT Vendor No.",
            VendorNo);

        if not TempJPL.FindSet() then
            exit('');

        HasOrderableLine :=
            HasOrderableLines(TempJPL);

        if not HasOrderableLine then begin
            SkippedCount +=
                CountNonTextLines(TempJPL);

            exit('');
        end;

        TempJPL.FindFirst();
        CreateHeader(
            PurchHeader,
            VendorNo,
            TempJPL);

        NextLineNo := 0;

        TempJPL.Reset();
        TempJPL.SetRange(
            "ACS CIT Vendor No.",
            VendorNo);

        if TempJPL.FindSet() then
            repeat

                if TempJPL.Type = TempJPL.Type::Text then begin

                    NextLineNo += 10000;

                    InsertCommentLine(
                        PurchHeader,
                        TempJPL,
                        NextLineNo);

                    SetPlanningLinePurchaseOrderNo(
                        TempJPL,
                        PurchHeader."No.");

                end else begin

                    RemainingQty :=
                        RemainingQtyToOrder(
                            TempJPL);

                    if RemainingQty <= 0 then begin

                        SkippedCount += 1;

                    end else begin

                        NextLineNo += 10000;

                        InsertJobPurchLine(
                            PurchHeader,
                            TempJPL,
                            RemainingQty,
                            NextLineNo);

                        SetPlanningLinePurchaseOrderNo(
                            TempJPL,
                            PurchHeader."No.");
                    end;
                end;

            until TempJPL.Next() = 0;

        /*
            Safety check:
            If no Purchase Lines were actually created,
            delete the empty header and do not return a PO.
        */
        if not HasPurchaseLines(PurchHeader) then begin
            PurchHeader.Delete(true);
            exit('');
        end;

        exit(PurchHeader."No.");
    end;


    local procedure CreateHeader(
        var PurchHeader: Record "Purchase Header";
        VendorNo: Code[20];
        JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        OrderDate: Date;
    begin
        OrderDate := WorkDate();

        PurchHeader.Init();

        PurchHeader."Document Type" :=
            PurchHeader."Document Type"::Order;

        PurchHeader."No." := '';

        PurchHeader.Insert(true);

        PurchHeader.Validate(
            "Buy-from Vendor No.",
            VendorNo);

        PurchHeader.Validate(
            "Order Date",
            OrderDate);

        PurchHeader.Validate(
            "Posting Date",
            OrderDate);

        PurchHeader.Validate(
            "Document Date",
            OrderDate);

        if Job.Get(JobPlanningLine."Job No.") then begin
            PurchHeader.Validate(
                "Shortcut Dimension 1 Code",
                Job."Global Dimension 1 Code");
            PurchHeader.Validate(
                "Shortcut Dimension 2 Code",
                Job."Global Dimension 2 Code");
            purchHeader.Validate(
            "Shortcut Dimension 3 Code",
            Job."Shortcut Dimension 3 Code");
            PurchHeader.Validate(
                "Shortcut Dimension 4 Code",
                Job."Shortcut Dimension 4 Code");
            PurchHeader.Validate(
                "Shortcut Dimension 5 Code", job."Shortcut Dimension 5 Code");
            PurchHeader.Validate(
                "Shortcut Dimension 6 Code",
                Job."Shortcut Dimension 6 Code");
            PurchHeader.Validate(
                "Shortcut Dimension 7 Code",
                Job."Shortcut Dimension 7 Code");
            PurchHeader.Validate(
                "Shortcut Dimension 8 Code",
                Job."Shortcut Dimension 8 Code");
            //purchHeader.Validate(ref
        end;


        PurchHeader.Modify(true);
    end;


    local procedure InsertJobPurchLine(
        PurchHeader: Record "Purchase Header";
        JobPlanningLine: Record "Job Planning Line";
        Qty: Decimal;
        LineNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Init();

        PurchLine."Document Type" :=
            PurchHeader."Document Type";

        PurchLine."Document No." :=
            PurchHeader."No.";
        PurchLine."Line No." :=
            LineNo;

        PurchLine.Insert(true);

        SetPurchLineType(
            PurchLine,
            JobPlanningLine);

        PurchLine.Validate(
            "No.",
            JobPlanningLine."No.");

        /*
            Job information
        */
        PurchLine.Validate(
            "Job No.",
            JobPlanningLine."Job No.");

        PurchLine.Validate(
            "Job Task No.",
            JobPlanningLine."Job Task No.");

        SetJobLineType(
            PurchLine,
            JobPlanningLine);

        PurchLine.Validate(
            "Job Planning Line No.",
            JobPlanningLine."Line No.");

        /*
            Location
        */
        if JobPlanningLine."Location Code" <> '' then
            PurchLine.Validate(
                "Location Code",
                JobPlanningLine."Location Code");

        /*
            Unit of Measure
        */
        if JobPlanningLine."Unit of Measure Code" <> '' then
            PurchLine.Validate(
                "Unit of Measure Code",
                JobPlanningLine."Unit of Measure Code");

        /*
            Quantity
        */
        PurchLine.Validate(
            Quantity,
            Qty);

        /*
            Direct Unit Cost
        */
        PurchLine.Validate(
            "Direct Unit Cost",
            JobPlanningLine."Unit Cost");

        /*
            Description
        */
        if JobPlanningLine.Description <> '' then
            PurchLine.Description :=
                JobPlanningLine.Description;

        /*
            Planning Date
        */
        if JobPlanningLine."Planning Date" <> 0D then
            PurchLine.Validate(
                "Expected Receipt Date",
                JobPlanningLine."Planning Date");

        PurchLine.Modify(true);
    end;


    local procedure InsertCommentLine(
        PurchHeader: Record "Purchase Header";
        JobPlanningLine: Record "Job Planning Line";
        LineNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Init();

        PurchLine."Document Type" :=
            PurchHeader."Document Type";

        PurchLine."Document No." :=
            PurchHeader."No.";

        PurchLine."Line No." :=
            LineNo;

        PurchLine.Insert(true);

        PurchLine.
            "Job No." :=
            JobPlanningLine."Job No.";

        PurchLine.
            "Job Task No." :=
            JobPlanningLine."Job Task No.";

        PurchLine.
            "Job Planning Line No." :=
            JobPlanningLine."Line No.";

        PurchLine.Description :=
            JobPlanningLine.Description;

        PurchLine.Modify(true);
    end;


    local procedure SetPurchLineType(
        var PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line")
    begin
        case JobPlanningLine.Type of

            JobPlanningLine.Type::Item:
                PurchLine.Validate(
                    Type,
                    PurchLine.Type::Item);

            JobPlanningLine.Type::"G/L Account":
                PurchLine.Validate(
                    Type,
                    PurchLine.Type::"G/L Account");

            JobPlanningLine.Type::Resource:
                PurchLine.Validate(
                    Type,
                    PurchLine.Type::Resource);

            else
                Error(
                    TypeNotSupportedErr,
                    JobPlanningLine."Job No.",
                    JobPlanningLine."Job Task No.",
                    JobPlanningLine."Line No.");
        end;
    end;


    local procedure SetJobLineType(
        var PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line")
    begin
        case JobPlanningLine."Line Type" of

            JobPlanningLine."Line Type"::Billable:
                PurchLine.Validate(
                    "Job Line Type",
                    PurchLine."Job Line Type"::Billable);

            JobPlanningLine."Line Type"::"Both Budget and Billable":
                PurchLine.Validate(
                    "Job Line Type",
                    PurchLine."Job Line Type"::"Both Budget and Billable");

            else
                PurchLine.Validate(
                    "Job Line Type",
                    PurchLine."Job Line Type"::Budget);
        end;
    end;


    local procedure RemainingQtyToOrder(
        JobPlanningLine: Record "Job Planning Line"): Decimal
    var
        PurchLine: Record "Purchase Line";
        OrderedQty: Decimal;
    begin
        PurchLine.Reset();

        PurchLine.SetRange(
            "Document Type",
            PurchLine."Document Type"::Order);

        PurchLine.SetRange(
            "Job No.",
            JobPlanningLine."Job No.");

        PurchLine.SetRange(
            "Job Task No.",
            JobPlanningLine."Job Task No.");

        PurchLine.SetRange(
            "Job Planning Line No.",
            JobPlanningLine."Line No.");

        if PurchLine.FindSet() then
            repeat
                if PurchLine.Type <> PurchLine.Type::" " then
                    OrderedQty +=
                        PurchLine.Quantity;
            until PurchLine.Next() = 0;

        if OrderedQty >= JobPlanningLine.Quantity then
            exit(0);

        exit(
            JobPlanningLine.Quantity -
            OrderedQty);
    end;


    local procedure HasOrderableLines(
        var TempJPL: Record "Job Planning Line" temporary): Boolean
    var
        TempCheck: Record "Job Planning Line" temporary;
    begin
        TempCheck.Copy(
            TempJPL,
            true);

        TempCheck.Reset();

        if not TempCheck.FindSet() then
            exit(false);

        repeat

            if TempCheck.Type <> TempCheck.Type::Text then begin

                if RemainingQtyToOrder(TempCheck) > 0 then
                    exit(true);

            end;

        until TempCheck.Next() = 0;

        exit(false);
    end;


    local procedure CountNonTextLines(
        var TempJPL: Record "Job Planning Line" temporary): Integer
    var
        TempCheck: Record "Job Planning Line" temporary;
        Count: Integer;
    begin
        TempCheck.Copy(
            TempJPL,
            true);

        TempCheck.Reset();

        if TempCheck.FindSet() then
            repeat

                if TempCheck.Type <> TempCheck.Type::Text then
                    Count += 1;

            until TempCheck.Next() = 0;

        exit(Count);
    end;


    local procedure HasPurchaseLines(
        PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Reset();

        PurchLine.SetRange(
            "Document Type",
            PurchHeader."Document Type");

        PurchLine.SetRange(
            "Document No.",
            PurchHeader."No.");

        exit(
            not PurchLine.IsEmpty());
    end;


    local procedure OpenCreatedPurchaseOrders(
        CreatedPOs: List of [Code[20]])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Reset();

        PurchHeader.SetRange(
            "Document Type",
            PurchHeader."Document Type"::Order);

        if CreatedPOs.Count() = 1 then begin

            PurchHeader.Get(
                PurchHeader."Document Type"::Order,
                CreatedPOs.Get(1));

            Page.Run(
                Page::"Purchase Order",
                PurchHeader);

        end else begin

            PurchHeader.SetFilter(
                "No.",
                BuildNoFilter(CreatedPOs));

            Page.Run(
                Page::"Purchase Order List",
                PurchHeader);
        end;
    end;


    local procedure BuildNoFilter(
        POs: List of [Code[20]]): Text
    var
        PONo: Code[20];
        FilterText: TextBuilder;
    begin
        foreach PONo in POs do begin

            if FilterText.Length() > 0 then
                FilterText.Append('|');

            FilterText.Append(
                PONo);
        end;

        exit(
            FilterText.ToText());
    end;

}