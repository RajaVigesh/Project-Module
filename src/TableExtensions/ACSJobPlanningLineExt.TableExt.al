tableextension 70200015 "ACS Job Planning Line Ext" extends "Job Planning Line"
{
    fields
    {
        field(70200000; "ACS CIT Vendor No."; Code[20])
        {
            Caption = 'CIT Vendor No.';
            TableRelation = Vendor;
            DataClassification = CustomerContent;
        }
        field(70200001; "ACS Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
            DataClassification = CustomerContent;
        }
        // Traceability back to the source Sales Quote - required to enforce the Gap 4
        // "same quote can't be attached to the same project twice" rule and to support
        // Gap 9's Job No./Job Task No./Job Planning Line No. lookup from the posted journal.
        field(70200002; "ACS Source Quote No."; Code[20])
        {
            Caption = 'Source Sales Quote No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70200003; "ACS Source Quote Line No."; Integer)
        {
            Caption = 'Source Sales Quote Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(ACSSourceQuote; "ACS Source Quote No.")
        {
        }
    }
}
