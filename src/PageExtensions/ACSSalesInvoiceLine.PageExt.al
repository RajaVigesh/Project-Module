pageextension 90118 "Sales Invoice SubForm Ext" extends "Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        modify("Unit Price")
        {
            editable = true;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}