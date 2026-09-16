// Object #27 - added beyond the FDD's object inventory table. Gap 5, rule 4 requires the
// standard Sales Quote List to default to Quote Status = Open, which the inventory table
// doesn't list an object for. Implemented as a hardcoded FilterGroup(4) filter (per section
// 11's FilterGroup convention) applied on open, so it never collides with a user's own
// filters and isn't a personalization/saved view.
pageextension 70200028 "ACS Sales Quote List Ext" extends "Sales Quote List"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("ACS Quote Status"; Rec."ACS Quote Status")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the ACS quote lifecycle status.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(4);
        Rec.SetRange("ACS Quote Status", Rec."ACS Quote Status"::Open);
        Rec.FilterGroup(0);
    end;
}
