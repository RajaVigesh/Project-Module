pageextension 70200001 "ACS Sales Quote Line Ext" extends "Sales Quote Subform"
{
    layout
    {
        addafter("Unit Price")
        {
            field("ACS Gross Margin %"; Rec."ACS Gross Margin %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the gross margin percentage calculated from Unit Price and Vendor Unit Cost. (Unit Price - Vendor Unit Cost) / Unit Price x 100.';
            }
            field("ACS Vendor No."; Rec."ACS Vendor No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the vendor resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
                Editable = not Rec."ACS Vendor No. Resolved";
            }
            field("ACS Vendor Unit Cost"; Rec."ACS Vendor Unit Cost")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the vendor unit cost used to calculate the gross margin.';
                Editable = not Rec."ACS Vendor Cost Resolved";
            }
            field("ACS Non-Market Item"; Rec."ACS Non-Market Item")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that no Purchase Price List match was found for this item/customer combination.';
            }
        }
    }
}
