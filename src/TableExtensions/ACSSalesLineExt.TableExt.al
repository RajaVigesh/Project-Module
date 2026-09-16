tableextension 90106 "ACS Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(90100; "ACS Gross Margin %"; Decimal)
        {
            Caption = 'Gross Margin %';
            DecimalPlaces = 2 : 2;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(90101; "ACS Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
            begin
                SetVendorDetails();
            end;

            // trigger OnLookup()
            // var
            //     PurchPriceList: Record "Price List Line";
            //     PurchPriceListLookup: Page "Purchase Price List Lines";
            //     ItemVendor: Record "Item Vendor";
            //     ItemVendorLookup: Page "Vendor Item Catalog";
            //     VendorNo: Code[20];
            //     UnitCost: Decimal;
            // begin
            //     if not GetVendorLookupSource(PurchPriceList, ItemVendor) then
            //         exit;

            //     if not PurchPriceList.IsEmpty() then begin
            //         PurchPriceListLookup.SetTableView(PurchPriceList);
            //         PurchPriceListLookup.LookupMode(true);

            //         if PurchPriceListLookup.RunModal() <> Action::LookupOK then
            //             exit;

            //         PurchPriceListLookup.GetRecord(PurchPriceList);
            //         VendorNo := PurchPriceList."Assign-to No.";
            //         UnitCost := PurchPriceList."Direct Unit Cost";
            //     end else begin
            //         ItemVendorLookup.SetTableView(ItemVendor);
            //         ItemVendorLookup.LookupMode(true);

            //         if ItemVendorLookup.RunModal() <> Action::LookupOK then
            //             exit;

            //         ItemVendorLookup.GetRecord(ItemVendor);
            //         VendorNo := ItemVendor."Vendor No.";
            //         UnitCost := GetItemUnitCost();
            //     end;

            //     if VendorNo = '' then
            //         exit;

            //     Rec.Validate(
            //         "ACS Vendor No.",
            //         VendorNo);
            //     Rec.Validate(
            //         "ACS Vendor Unit Cost",
            //         UnitCost);
            // end;
        }
        field(90102; "ACS Vendor Unit Cost"; Decimal)
        {
            Caption = 'Vendor Unit Cost';
            DecimalPlaces = 2 : 5;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ACSVendorCostMgt: Codeunit "ACS Vendor Cost Mgt.";
            begin
                ACSVendorCostMgt.CalcGrossMarginPct(Rec);
            end;
        }
        field(90103; "ACS Non-Market Item"; Boolean)
        {
            Caption = 'Non-Market Item';
            Editable = false;
            DataClassification = CustomerContent;
        }
        // Not in the FDD field table - added because "conditionally editable" (Gap 2)
        // needs a persisted state to distinguish "no customer-dimension match" (both blank,
        // both editable) from "customer match / no item match" (Vendor No. locked, cost editable).
        // Without these, the page can't tell the two blank-Vendor-No-but-different-reason
        // states apart. Flagging as an assumption to confirm - functionally required either
        // way, this is just where the state lives.
        field(90104; "ACS Vendor No. Resolved"; Boolean)
        {
            Caption = 'Vendor No. Resolved';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(90105; "ACS Vendor Cost Resolved"; Boolean)
        {
            Caption = 'Vendor Unit Cost Resolved';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(90106; "ACS Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            Editable = false;
            DataClassification = CustomerContent;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
            begin
                ApplyItemCostFallback();
            end;
        }
    }

    local procedure GetVendorLookupSource(
        var PurchPriceList: Record "Price List Line";
        var ItemVendor: Record "Item Vendor"): Boolean
    var
        SalesHeaderRec: Record "Sales Header";
    begin
        PurchPriceList.Reset();
        ItemVendor.Reset();

        if Rec."No." = '' then
            exit(false);

        if not SalesHeaderRec.Get(
            Rec."Document Type",
            Rec."Document No.")
        then
            exit(false);

        if SalesHeaderRec."Document Type" <> SalesHeaderRec."Document Type"::Quote then
            exit(false);

        PurchPriceList.SetRange(
            "CIT Shortcut Dimension 5 Code",
            SalesHeaderRec."Shortcut Dimension 5 Code");
        PurchPriceList.SetRange(
            "Product No.",
            Rec."No.");
        PurchPriceList.SetRange(
            Status,
            PurchPriceList.Status::Active);
        PurchPriceList.SetRange(
            "Source Type",
            PurchPriceList."Source Type"::Vendor);
        PurchPriceList.SetRange(
            "Item Category Code",
            Rec."Item Category Code");

        if not PurchPriceList.IsEmpty() then
            exit(true);

        ItemVendor.SetRange(
            "Item No.",
            Rec."No.");
        exit(true);
    end;

    local procedure ApplyItemCostFallback()
    var
        PurchPriceList: Record "Price List Line";
        ItemVendor: Record "Item Vendor";
        Item: Record Item;
    begin
        if not GetVendorLookupSource(PurchPriceList, ItemVendor) then
            exit;

        if not PurchPriceList.IsEmpty() then
            exit;

        if not ItemVendor.IsEmpty() then
            exit;

        if not Confirm(
            NoVendorSourceConfirmMsg,
            false,
            Rec."No.")
        then
            exit;

        if Item.Get(Rec."No.") then
            Rec.Validate(
                "ACS Vendor Unit Cost",
                Item."Unit Cost");
    end;

    local procedure SetVendorDetails()
    var
        PurchPriceList: Record "Price List Line";
        ItemVendor: Record "Item Vendor";
        VendorRec: Record Vendor;
    begin
        if Rec."ACS Vendor No." = '' then begin
            Clear(Rec."ACS Vendor Name");
            exit;
        end;

        if VendorRec.Get(Rec."ACS Vendor No.") then
            Rec.Validate(
                "ACS Vendor Name",
                VendorRec.Name);

        if GetVendorLookupSource(PurchPriceList, ItemVendor) then begin
            if not PurchPriceList.IsEmpty() then begin
                PurchPriceList.SetRange(
                    "Assign-to No.",
                    Rec."ACS Vendor No.");
                if PurchPriceList.FindFirst() then
                    Rec.Validate(
                        "ACS Vendor Unit Cost",
                        PurchPriceList."Direct Unit Cost");
            end else begin
                ItemVendor.SetRange(
                    "Vendor No.",
                    Rec."ACS Vendor No.");
                if not ItemVendor.IsEmpty() then
                    Rec.Validate(
                        "ACS Vendor Unit Cost",
                        GetItemUnitCost());
            end;
        end;
    end;

    local procedure GetItemUnitCost(): Decimal
    var
        Item: Record Item;
    begin
        if Item.Get(Rec."No.") then
            exit(Item."Unit Cost");

        exit(0);
    end;

    var
        NoVendorSourceConfirmMsg: Label 'No purchase price list or vendor catalog was found for item %1. Do you want to use the item card unit cost as the vendor unit cost?', Comment = '%1 = Item No.';

}
