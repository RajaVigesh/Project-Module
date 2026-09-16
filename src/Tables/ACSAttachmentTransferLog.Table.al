table 70200024 "ACS Attachment Transfer Log"
{
    Caption = 'Attachment Transfer Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Source Project No."; Code[20])
        {
            Caption = 'Source Project No.';
            TableRelation = Job;
        }
        // "Document Attachment".ID (auto-increment) uniquely identifies the source
        // attachment record - used instead of file name/timestamp because it's a hard key.
        field(2; "Source Attachment ID"; Integer)
        {
            Caption = 'Source Attachment ID';
        }
        field(3; "Target Sales Invoice No."; Code[20])
        {
            Caption = 'Target Sales Invoice No.';
            TableRelation = "Sales Invoice Header";
        }
        field(10; "Transferred At"; DateTime)
        {
            Caption = 'Transferred At';
            Editable = false;
        }
    }

    keys
    {
        // Primary key on the combination enforces no-duplicate-transfer at the data
        // level (Gap 10 requirement) - a second Insert() for the same combination fails.
        key(PK; "Source Project No.", "Source Attachment ID", "Target Sales Invoice No.")
        {
            Clustered = true;
        }
    }
}
