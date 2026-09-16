pageextension 90106 "User Setup Ext" extends "User Setup"
{
    layout
    {
        addafter("Sales Price Editable")
        {
            field("ACS Allow Edit JPL Price"; Rec."ACS Allow Edit JPL Price")
            {
                ApplicationArea = all;
                Caption = 'Sales quote price Editable';
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