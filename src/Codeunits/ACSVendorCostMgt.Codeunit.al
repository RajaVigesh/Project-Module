codeunit 70200005 "ACS Vendor Cost Mgt."
{
    // ---- Event subscribers (extension-boundary compliant: no base object edits) ----

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure OnAfterValidateSalesLineNo(var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
    begin
        if Rec.Type <> Rec.Type::Item then
            exit;
        if Rec."Document Type" <> Rec."Document Type"::Quote then
            exit;
        ResolveVendorAndCost(Rec);
        CalcGrossMarginPct(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'Unit Price', false, false)]
    local procedure OnAfterValidateUnitPrice(var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
    begin
        CalcGrossMarginPct(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure OnAfterValidateSellToCustomerNo(var Rec: Record "Sales Header"; var xRec: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Quote then
            exit;

        SalesLine.FilterGroup(4);
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FilterGroup(0);
        SalesLine.SetLoadFields("Document Type", "Document No.", "Line No.", Type, "No.", "Unit Price",
            "ACS Vendor No.", "ACS Vendor Unit Cost", "ACS Non-Market Item",
            "ACS Vendor No. Resolved", "ACS Vendor Cost Resolved", "ACS Gross Margin %");

        if SalesLine.FindSet(true) then
            repeat
                ResolveVendorAndCost(SalesLine);
                CalcGrossMarginPct(SalesLine);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
    end;

    // ---- Gap 1: Gross Margin % ----
    // (Unit Price - Vendor Unit Cost) / Unit Price x 100. Quantity is explicitly NOT part
    // of the formula per the FDD. Zero-Unit-Price resolves to 0% (Open Question #1 - confirm
    // with ACS). Negative values are valid and not clamped.
    procedure CalcGrossMarginPct(var SalesLine: Record "Sales Line")
    begin
        if SalesLine."Unit Price" = 0 then
            SalesLine."ACS Gross Margin %" := 0
        else
            SalesLine."ACS Gross Margin %" :=
                Round((SalesLine."Unit Price" - SalesLine."ACS Vendor Unit Cost") / SalesLine."Unit Price" * 100, 0.01);
    end;

    // ---- Gap 2: Vendor No. / Vendor Unit Cost / Non-Market Item resolution ----
    procedure ResolveVendorAndCost(var SalesLine: Record "Sales Line")
    begin
        if not TryResolveVendorAndCost(SalesLine) then
            Message(ResolutionFailedMsg, GetLastErrorText);
    end;

    [TryFunction]
    local procedure TryResolveVendorAndCost(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        PurchPrice: Record "Purchase Price";
        CustomerCode: Code[20];
    begin
        ValidateDimensionSetup();

        Clear(SalesLine."ACS Vendor No.");
        Clear(SalesLine."ACS Vendor Unit Cost");
        SalesLine."ACS Non-Market Item" := false;
        SalesLine."ACS Vendor No. Resolved" := false;
        SalesLine."ACS Vendor Cost Resolved" := false;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        CustomerCode := SalesHeader."Shortcut Dimension 5 Code";

        // Step 3 - no matching Purchase Price List record for the Customer Code:
        // Vendor No./Vendor Unit Cost blank, Non-Market Item = true, both fields editable.
        PurchPrice.FilterGroup(4);
        PurchPrice.SetRange("ACS Customer Code", CustomerCode);
        PurchPrice.FilterGroup(0);
        PurchPrice.SetLoadFields("Vendor No.", "Item No.", "Direct Unit Cost", "ACS Customer Code");
        PurchPrice.SetCurrentKey("ACS Customer Code", "Item No.", "Vendor No.");

        if CustomerCode = '' then begin
            SalesLine."ACS Non-Market Item" := true;
            exit;
        end;
        if PurchPrice.IsEmpty() then begin
            SalesLine."ACS Non-Market Item" := true;
            exit;
        end;

        // Step 4 - Customer Code matched at least one vendor price list; now check Item No.
        PurchPrice.SetRange("Item No.", SalesLine."No.");
        if PurchPrice.FindFirst() then begin
            // Match found - both fields locked.
            SalesLine."ACS Vendor No." := PurchPrice."Vendor No.";
            SalesLine."ACS Vendor Unit Cost" := PurchPrice."Direct Unit Cost";
            SalesLine."ACS Non-Market Item" := false;
            SalesLine."ACS Vendor No. Resolved" := true;
            SalesLine."ACS Vendor Cost Resolved" := true;
        end else begin
            // Customer Code matched a vendor, but not this item - Vendor No. resolved/locked,
            // Vendor Unit Cost stays blank and editable.
            PurchPrice.SetRange("Item No.");
            PurchPrice.FindFirst();
            SalesLine."ACS Vendor No." := PurchPrice."Vendor No.";
            Clear(SalesLine."ACS Vendor Unit Cost");
            SalesLine."ACS Non-Market Item" := true;
            SalesLine."ACS Vendor No. Resolved" := true;
            SalesLine."ACS Vendor Cost Resolved" := false;
        end;
    end;

    // Section 11 dimension dependency - errors early (inside the TryFunction, so it never
    // blocks line entry) if Shortcut Dimension 5 isn't configured as expected.
    local procedure ValidateDimensionSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."Shortcut Dimension 5 Code" = '' then
            Error(ShortcutDim5NotSetUpErr);
    end;

    var
        ResolutionFailedMsg: Label 'Vendor/cost lookup could not be completed automatically (%1). Enter Vendor No. and Vendor Unit Cost manually.', Comment = '%1 = error text';
        ShortcutDim5NotSetUpErr: Label 'Shortcut Dimension 5 is not configured in General Ledger Setup. This is required for vendor cost resolution.';
}
