pageextension 90107 "Job Task Lines Subform Ext" extends "Job Task Lines Subform"
{
    layout
    {
        modify("Remaining (Total Cost)")
        {
            visible = true;
        }
        modify("Remaining (Total Price)")
        {
            visible = true;
        }
        modify("Start Date")
        {
            visible = False;
        }
        modify("End Date")
        {
            visible = False;
        }
        addafter("Remaining (Total Price)")
        {
            field("Total Remaining Cost"; Rec."Total Remaining Cost")
            {
                ApplicationArea = All;
                Caption = 'Total Remaining Cost';
                ToolTip = 'Specifies the total remaining cost for the job task line.';
                Editable = false;
            }
            field("Total Remaining Price"; Rec."Total Remaining Price")
            {
                ApplicationArea = All;
                Caption = 'Total Remaining Price';
                ToolTip = 'Specifies the total remaining price for the job task line.';
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}