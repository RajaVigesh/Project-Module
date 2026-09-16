pageextension 90115 "ACS Vendor Item Catalog Ext" extends "Vendor Item Catalog"
{
    layout
    {
        addafter("Vendor No.")
        {
            field("ACS Vendor Name"; Rec."ACS Vendor Name")
            {
                ApplicationArea = All;
                Caption = 'Vendor Name';
                ToolTip = 'Specifies the vendor name from the vendor master.';
            }
        }
    }
}