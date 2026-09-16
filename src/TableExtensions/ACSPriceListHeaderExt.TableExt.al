tableextension 90115 "ACS Price List Header Ext" extends "Price List Header"
{
    fields
    {
        field(90100; "ACS Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Source No.")));
            Editable = false;
        }
    }
}