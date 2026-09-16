pageextension 90102 "ACS Sales Quote Line Ext" extends "Sales Quote Subform"
{
    layout
    {
        addafter("Unit Price")
        {
            field("ACS Gross Margin %"; Rec."ACS Gross Margin %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the gross margin percentage calculated from Unit Price and Vendor Unit Cost. (Unit Price - Vendor Unit Cost) / Unit Price x 100.';
            }
            field("ACS Vendor No."; Rec."ACS Vendor No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the vendor resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
                //Editable = not Rec."ACS Vendor No. Resolved";

                trigger OnLookup(var Text: Text): Boolean
                var
                    PurchPriceList: Record "Price List Line";
                    PurchPriceHeader: Record "Price List Header";
                    PurchPriceListLookup: Page "Purchase Price List Lines";
                    ItemVendor: Record "Item Vendor";
                    ItemVendorLookup: Page "Vendor Item Catalog";
                    SalesHeaderRec: Record "Sales Header";
                    LookupResult: Action;
                    VendorNo: Code[20];
                    UnitCost: Decimal;
                begin
                    if Rec."No." = '' then
                        exit(false);

                    if not SalesHeaderRec.Get(
                        Rec."Document Type",
                        Rec."Document No.")
                    then
                        exit(false);

                    PurchPriceList.Reset();
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

                    if not PurchPriceList.IsEmpty() then begin
                        PurchPriceListLookup.SetTableView(PurchPriceList);
                        PurchPriceListLookup.LookupMode(true);

                        LookupResult := PurchPriceListLookup.RunModal();
                        if not (LookupResult in [Action::LookupOK, Action::OK]) then
                            exit(false);

                        PurchPriceListLookup.GetRecord(PurchPriceList);
                        if not PurchPriceHeader.Get(PurchPriceList."Price List Code") then
                            exit(false);

                        VendorNo := PurchPriceHeader."Source No.";
                        UnitCost := PurchPriceList."Direct Unit Cost";
                    end else begin
                        ItemVendor.Reset();
                        ItemVendor.SetRange(
                            "Item No.",
                            Rec."No.");
                        if ItemVendor.IsEmpty() then
                            exit(false);

                        ItemVendorLookup.SetTableView(ItemVendor);
                        ItemVendorLookup.LookupMode(true);

                        LookupResult := ItemVendorLookup.RunModal();
                        if not (LookupResult in [Action::LookupOK, Action::OK]) then
                            exit(false);

                        ItemVendorLookup.GetRecord(ItemVendor);
                        VendorNo := ItemVendor."Vendor No.";
                        UnitCost := GetItemUnitCost();
                    end;

                    if VendorNo = '' then
                        exit(false);

                    Text := VendorNo;
                    Rec.Validate(
                        "ACS Vendor No.",
                        VendorNo);
                    Rec.Validate(
                        "ACS Vendor Unit Cost",
                        UnitCost);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                    exit(true);
                end;
            }
            field("ACS Vendor Name"; Rec."ACS Vendor Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the name of the vendor resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
                Editable = false;
            }
            field("ACS Vendor Unit Cost"; Rec."ACS Vendor Unit Cost")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the vendor unit cost used to calculate the gross margin.';
                Editable = not Rec."ACS Vendor Cost Resolved";
            }
            field("ACS Non-Market Item"; Rec."ACS Non-Market Item")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that no Purchase Price List match was found for this item/customer combination.';
            }
        }
    }

    local procedure GetItemUnitCost(): Decimal
    var
        Item: Record Item;
    begin
        if Item.Get(Rec."No.") then
            exit(Item."Unit Cost");

        exit(0);
    end;

    var

}
