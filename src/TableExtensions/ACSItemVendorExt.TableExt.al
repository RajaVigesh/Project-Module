tableextension 90114 "ACS Item Vendor Ext" extends "Item Vendor"
{
    fields
    {
        field(90100; "ACS Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
    }
}