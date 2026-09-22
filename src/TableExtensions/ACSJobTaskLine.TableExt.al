tableextension 90109 "Job Task Line Ext" extends "Job Task"
{
    fields
    {
        field(90100; "Total Remaining Price"; Decimal)
        {
            Caption = 'Total Remaining Price';
            DataClassification = ToBeClassified;

        }
        field(90101; "Total Remaining Cost"; Decimal)
        {
            Caption = 'Total Remaining Cost';
            // DataClassification = ToBeClassified;
            fieldclass = FlowField;
            CalcFormula = Sum("Job Planning Line"."Remaining Total Cost" WHERE("Job Task No." = field("Job Task No."), "Job No." = field("Job No.")));
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}