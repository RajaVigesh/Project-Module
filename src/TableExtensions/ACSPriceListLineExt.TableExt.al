tableextension 90116 "ACS Price List Line Ext" extends "Price List Line"
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