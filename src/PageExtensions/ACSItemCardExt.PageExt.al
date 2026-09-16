pageextension 90100 "ACS Item Card Ext" extends "Item Card"
{
    layout
    {
        addafter("No.")
        {
            field("ACS Status"; Rec."ACS Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the approval status of this item. Only Active items can be used on sales, purchase, or job transaction lines.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            // action("ACS Send For Approval")
            // {
            //     ApplicationArea = All;
            //     Caption = 'Send for Approval';
            //     Image = SendApprovalRequest;
            //     Enabled = (Rec."ACS Status" = Rec."ACS Status"::Draft) or (Rec."ACS Status" = Rec."ACS Status"::Rejected);
            //     ToolTip = 'Validates mandatory item fields and submits the item for approval via the standard approval workflow.';

            //     trigger OnAction()
            //     var
            //         ACSItemApprovalMgt: Codeunit "ACS Item Approval Mgt.";
            //     begin
            //         ACSItemApprovalMgt.SendForApproval(Rec);
            //         CurrPage.Update(false);
            //     end;
            // }
        }
    }
}
