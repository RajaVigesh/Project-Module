tableextension 70200000 "ACS Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(70200000; "ACS Gross Margin %"; Decimal)
        {
            Caption = 'Gross Margin %';
            DecimalPlaces = 2 : 2;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(70200001; "ACS Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ACSVendorCostMgt: Codeunit "ACS Vendor Cost Mgt.";
            begin
                // Manual entry path only - the resolved path never lands here because
                // the field is locked (see ACS Vendor No. Resolved) whenever the system set it.
                ACSVendorCostMgt.CalcGrossMarginPct(Rec);
            end;
        }
        field(70200002; "ACS Vendor Unit Cost"; Decimal)
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
        field(70200003; "ACS Non-Market Item"; Boolean)
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
        field(70200004; "ACS Vendor No. Resolved"; Boolean)
        {
            Caption = 'Vendor No. Resolved';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(70200005; "ACS Vendor Cost Resolved"; Boolean)
        {
            Caption = 'Vendor Unit Cost Resolved';
            Editable = false;
            DataClassification = SystemMetadata;
        }
    }
}
