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
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}