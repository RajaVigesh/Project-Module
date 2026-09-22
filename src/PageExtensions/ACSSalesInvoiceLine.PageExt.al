pageextension 90118 "Sales Invoice SubForm Ext" extends "Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        modify("Unit Price")
        {
            editable = true;
        }
        modify("Item Reference No.")
        {
            visible = false;
        }
        modify("CIT No.")
        {
            visible = true;
        }
        modify("No.")
        {
            visible = false;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}