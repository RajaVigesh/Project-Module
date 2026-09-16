tableextension 70200002 "ACS Sales Header Ext" extends "Sales Header"
{
    fields
    {
        field(70200000; "ACS Quote Status"; Enum "ACS Sales Quote Status")
        {
            Caption = 'Quote Status';
            DataClassification = CustomerContent;
        }
        field(70200001; "ACS Linked Project No."; Code[20])
        {
            Caption = 'Linked Project No.';
            TableRelation = Job;
            DataClassification = CustomerContent;
            Editable = false;
        }
        // Not in the FDD field table. Gap 4 (5b) requires matching "Start Date and End Date"
        // between the Sales Quote and the candidate Project, but the FDD doesn't define
        // where those dates live on the quote - Sales Header has no native Start/End Date.
        // Added here as the most direct implementation; confirm with ACS whether these
        // should instead map to existing fields (e.g. Requested Delivery Date) already in use.
        field(70200002; "ACS Quote Start Date"; Date)
        {
            Caption = 'Quote Start Date';
            DataClassification = CustomerContent;
        }
        field(70200003; "ACS Quote End Date"; Date)
        {
            Caption = 'Quote End Date';
            DataClassification = CustomerContent;
        }
    }
}
