tableextension 70200021 "ACS Approval Entry Ext" extends "Approval Entry"
{
    fields
    {
        field(70200000; "ACS Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70200001; "ACS Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("ACS Job No."));
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
