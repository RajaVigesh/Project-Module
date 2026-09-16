pageextension 90101 "ACS Sales Quote Ext" extends "Sales Quote"
{
    layout
    {
        addafter(Status)
        {
            field("ACS Quote Status"; Rec."ACS Quote Status")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the ACS quote lifecycle status: Open, Closed (project created), Completed (linked project completed), or Cancelled.';
            }
            field("ACS Linked Project No."; Rec."ACS Linked Project No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the project this quote has been consolidated into.';
            }
            field("ACS Quote Start Date"; Rec."ACS Quote Start Date")
            {
                ApplicationArea = All;
                Visible = false;
                Editable = Rec."ACS Quote Status" <> Rec."ACS Quote Status"::Closed;
                ToolTip = 'Specifies the intended project start date, used to match against existing projects when consolidating quotes.';
            }
            field("ACS Quote End Date"; Rec."ACS Quote End Date")
            {
                ApplicationArea = All;
                Visible = false;
                Editable = Rec."ACS Quote Status" <> Rec."ACS Quote Status"::Closed;
                ToolTip = 'Specifies the intended project end date, used to match against existing projects when consolidating quotes.';
            }

        }
        modify("Sell-to Customer No.")
        {
            Visible = false;
        }
    }

    actions
    {
        addafter("Archive Document")
        {
            action("ACS Cancel Quote")
            {
                ApplicationArea = All;
                Caption = 'Cancel Quote';
                Image = Cancel;
                Enabled = Rec."ACS Quote Status" <> Rec."ACS Quote Status"::Closed;
                ToolTip = 'Cancels the sales quote. A cancelled quote cannot be used to create or be attached to a project.';

                trigger OnAction()
                var
                    ACSSalesQuoteStatusMgt: Codeunit "ACS Sales Quote Status Mgt.";
                begin
                    ACSSalesQuoteStatusMgt.CancelQuote(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("ACS Create Project")
            {
                ApplicationArea = All;
                Caption = 'Create Project';
                Image = Job;
                Enabled = Rec."ACS Quote Status" <> Rec."ACS Quote Status"::Closed;
                ToolTip = 'Creates a new project from this quote, or attaches this quote to an existing open project for the same customer (PEP consolidation).';

                trigger OnAction()
                var
                    ACSQuoteToProjectMgt: Codeunit "ACS Quote To Project Mgt.";
                begin
                    if not (Rec.Status = Rec.Status::Released) then
                        Error('The quote must be Released before creating the Project and transferring attachments.');
                    ACSQuoteToProjectMgt.RunCreateProjectFlow(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("ACS Existing Project")
            {
                ApplicationArea = All;
                Caption = 'Existing Project';
                Image = Job;
                Enabled = Rec."ACS Quote Status" <> Rec."ACS Quote Status"::Closed;
                ToolTip = 'Creates a new project from this quote, or attaches this quote to an existing open project for the same customer (PEP consolidation).';

                trigger OnAction()
                var
                    JobRec: Record Job;
                    ACSQuoteToProjectMgt: Codeunit "ACS Quote To Project Mgt.";
                begin
                    if not (Rec.Status = Rec.Status::Released) then
                        Error('The quote must be Released before creating the Project and transferring attachments.');

                    JobRec.Reset();
                    JobRec.SetRange("Sell-to Customer No.", Rec."Sell-to Customer No.");
                    JobRec.SetRange(Status, JobRec.Status::Planning);
                    JobRec.SetFilter("Starting Date", '>=%1', Rec."SO START DATE");
                    JobRec.SetFilter("Ending Date", '%1<=', Rec."SO END DATE");
                    JobRec.SetRange("Shortcut Dimension 5 Code", Rec."Shortcut Dimension 5 Code");
                    if JobRec.FindFirst() then begin
                        ACSQuoteToProjectMgt.RunExistingProjectFlow(Rec);
                        CurrPage.Update(false);
                    end
                    else
                        Message('No existing open project found for this customer and date range. Please use the Create Project action instead.');
                end;
            }
        }
        addafter("Archive Document_Promoted")
        {
            actionRef(CreateProject_Promoted; "ACS Create Project")
            {

            }
            actionRef(ExistingProject_Promoted; "ACS Existing Project")
            {

            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := Rec."ACS Quote Status" <> Rec."ACS Quote Status"::Closed;
    end;
}
