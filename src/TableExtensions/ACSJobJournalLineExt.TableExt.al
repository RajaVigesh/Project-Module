// Object #30 - added beyond the FDD's object inventory table. Without this, Gap 9's
// "same vendor activity never updates Qty. to Invoice more than once" guard would have to
// fuzzy-match a posted Job Journal Line back to a Vendor Activity Line via Job
// No./Job Task No./Job Planning Line No. alone, which is ambiguous once more than one
// activity line has ever referenced the same planning line across confirmation cycles.
// These two fields make the link exact.
tableextension 90102 "ACS Job Journal Line Ext" extends "Job Journal Line"
{
    fields
    {
        field(70200000; "ACS Vendor Activity Batch Name"; Code[20])
        {
            Caption = 'Vendor Activity Batch Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70200001; "ACS Vendor Activity Line No."; Integer)
        {
            Caption = 'Vendor Activity Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
