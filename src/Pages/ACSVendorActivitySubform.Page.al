page 90103 "ACS Vendor Activity Subform"
{
    ApplicationArea = All;
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "ACS Vendor Activity Line";
    MultipleNewLines = false;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Planned Quantity"; Rec."Planned Quantity")
                {
                    ApplicationArea = All;
                }
                field("Reported Quantity"; Rec."Reported Quantity")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Approval Entry No."; Rec."Approval Entry No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
