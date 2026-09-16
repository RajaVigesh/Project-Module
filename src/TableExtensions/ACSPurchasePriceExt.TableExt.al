// Object #29 - added beyond the FDD's object inventory table. Gap 2's resolution algorithm
// filters the Purchase Price List "by Customer Code dimension" but the FDD doesn't say how
// that dimension is stored against a purchase price record - there's no native dimension
// field on table "Purchase Price". [Speculative] Implemented here as a direct field so the
// filter in ACS Vendor Cost Mgt. is something that actually compiles and runs; if ACS's
// Purchase Price Lists already carry this via Dimension Set ID or a different mechanism,
// swap the field reference in ACS Vendor Cost Mgt.ResolveVendorAndCost accordingly.
tableextension 90104 "ACS Purchase Price Ext" extends "Purchase Price"
{
    fields
    {
        field(90100; "ACS Customer Code"; Code[20])
        {
            Caption = 'Customer Code';
            DataClassification = CustomerContent;
        }
        field(90101; "ACS Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
    }

    // keys
    // {
    //     key(ACSCustomerCode; "ACS Customer Code", "Item No.", "Vendor No.")
    //     {
    //     }
    // }
}
