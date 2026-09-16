page 70200019 "ACS Vendor Activity Confirmation"
{
    ApplicationArea = All;
    Caption = 'Vendor Activity Confirmation';
    PageType = Document;
    SourceTable = "ACS Vendor Activity Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Filters)
            {
                Caption = 'Batch Filters';

                field("Batch Name"; Rec."Batch Name")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Project No. Filter"; Rec."Project No. Filter")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Vendor No. Filter"; Rec."Vendor No. Filter")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "ACS Vendor Activity Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Batch Name" = field("Batch Name");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetrievePlanningLines)
            {
                ApplicationArea = All;
                Caption = 'Retrieve Planning Lines';
                Image = GetLines;
                ToolTip = 'Retrieves eligible Job Planning Lines matching the batch filters, excluding lines already submitted for or approved in a prior batch.';

                trigger OnAction()
                var
                    ACSVendorActivityMgt: Codeunit "ACS Vendor Activity Mgt.";
                begin
                    ACSVendorActivityMgt.RetrievePlanningLines(Rec);
                    CurrPage.Lines.Page.Update(false);
                end;
            }
            action(SubmitForApproval)
            {
                ApplicationArea = All;
                Caption = 'Submit for Approval';
                Image = SendApprovalRequest;
                ToolTip = 'Submits the Open lines in this batch for approval via the standard approval workflow.';

                trigger OnAction()
                var
                    ACSVendorActivityMgt: Codeunit "ACS Vendor Activity Mgt.";
                begin
                    ACSVendorActivityMgt.SubmitForApproval(Rec);
                    CurrPage.Lines.Page.Update(false);
                end;
            }
        }
    }
}
