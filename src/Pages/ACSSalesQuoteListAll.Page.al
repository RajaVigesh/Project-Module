page 70200010 "ACS Sales Quote List All"
{
    ApplicationArea = All;
    Caption = 'All Quotes (All Statuses)';
    CardPageId = "Sales Quote";
    Editable = false;
    PageType = List;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Quote));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                }
                field("ACS Quote Status"; Rec."ACS Quote Status")
                {
                    ApplicationArea = All;
                }
                field("ACS Linked Project No."; Rec."ACS Linked Project No.")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
