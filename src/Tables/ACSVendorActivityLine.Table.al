table 90102 "ACS Vendor Activity Line"
{
    Caption = 'Vendor Activity Confirmation Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch Name"; Code[20])
        {
            Caption = 'Batch Name';
            TableRelation = "ACS Vendor Activity Header"."Batch Name";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
            Editable = false;
        }
        field(11; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            Editable = false;
        }
        field(12; "Job Planning Line No."; Integer)
        {
            Caption = 'Job Planning Line No.';
            Editable = false;
        }
        field(20; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            Editable = false;
        }
        field(21; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(30; "Planned Quantity"; Decimal)
        {
            Caption = 'Planned Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(31; "Reported Quantity"; Decimal)
        {
            Caption = 'Reported Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                Rec.TestField(Status, Rec.Status::Open);
            end;
        }
        field(32; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                Rec.TestField(Status, Rec.Status::Open);
            end;
        }
        field(40; Status; Enum "ACS Vendor Activity Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(41; "Approval Entry No."; Integer)
        {
            Caption = 'Approval Entry No.';
            TableRelation = "Approval Entry"."Entry No.";
            Editable = false;
        }
        // Gap 9 - prevents the same vendor activity line from updating Qty. to Invoice
        // more than once even if the job journal posting event fires again.
        field(50; "ACS Qty To Invoice Updated"; Boolean)
        {
            Caption = 'Qty to Invoice Updated';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(SourcePlanningLine; "Job No.", "Job Task No.", "Job Planning Line No.")
        {
        }
        key(ByStatus; Status)
        {
        }
    }
}
