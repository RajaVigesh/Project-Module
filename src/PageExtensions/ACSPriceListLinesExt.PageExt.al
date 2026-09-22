pageextension 90117 "ACS Price List Lines Ext" extends "Purchase Price List Lines"
{
    layout
    {
        addafter(Description)
        {
            field("ACS Vendor Name"; Rec."ACS Vendor Name")
            {
                ApplicationArea = All;
                Caption = 'Vendor Name';
                ToolTip = 'Specifies the vendor name from the vendor master.';
            }
        }
        modify(DirectUnitCost)
        {
            ApplicationArea = All;
            ToolTip = 'Specifies the unit cost of the item.';
            visible = True;
        }

        modify("CIT Product No")
        {
            ApplicationArea = All;
            ToolTip = 'Specifies the unit price of the item.';
            visible = True;
            trigger OnAfterValidate()
            var
                PriceListHeader: Record "Price List Header";
            begin
                PriceListHeader.Reset();
                if PriceListHeader.Get(Rec."Price List Code") then begin
                    Rec.Validate("CIT Shortcut Dimension 5 Code", PriceListHeader."CIT Shortcut Dimension 5 Code");
                    Rec.Validate("CIT Shortcut Dimension 3 Code", PriceListHeader."CIT Shortcut Dimension 3 Code");
                    // CurrPage.Update(false);
                end;
            end;
        }

    }
}