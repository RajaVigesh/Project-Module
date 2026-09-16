pageextension 70200003 "ACS Sales Quote Ext" extends "Sales Quote"
{
    layout
    {
        addafter(Status)
        {
            field("ACS Quote Status"; Rec."ACS Quote Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ACS quote lifecycle status: Open, Completed (linked project completed), or Cancelled.';
            }
            field("ACS Linked Project No."; Rec."ACS Linked Project No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the project this quote has been consolidated into.';
            }
            field("ACS Quote Start Date"; Rec."ACS Quote Start Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the intended project start date, used to match against existing projects when consolidating quotes.';
            }
            field("ACS Quote End Date"; Rec."ACS Quote End Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the intended project end date, used to match against existing projects when consolidating quotes.';
            }
        }
    }

    actions
    {
        addafter(Approval)
        {
            action("ACS Cancel Quote")
            {
                ApplicationArea = All;
                Caption = 'Cancel Quote';
                Image = Cancel;
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
                ToolTip = 'Creates a new project from this quote, or attaches this quote to an existing open project for the same customer (PEP consolidation).';

                trigger OnAction()
                var
                    ACSQuoteToProjectMgt: Codeunit "ACS Quote To Project Mgt.";
                begin
                    ACSQuoteToProjectMgt.RunCreateProjectFlow(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
