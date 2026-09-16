table 70200017 "ACS Vendor Activity Header"
{
    Caption = 'Vendor Activity Confirmation Batch';
    DataClassification = CustomerContent;
    LookupPageId = "ACS Vendor Activity Confirmation";

    fields
    {
        field(1; "Batch Name"; Code[20])
        {
            Caption = 'Batch Name';
            NotBlank = true;
        }
        field(10; "Project No. Filter"; Code[20])
        {
            Caption = 'Project No. Filter';
            TableRelation = Job;
        }
        field(20; "Vendor No. Filter"; Code[20])
        {
            Caption = 'Vendor No. Filter';
            TableRelation = Vendor;
        }
        field(30; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(31; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
        }
        field(40; Status; Enum "ACS Vendor Activity Status")
        {
            Caption = 'Status';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Batch Name")
        {
            Clustered = true;
        }
    }
}
