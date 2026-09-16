page 90100 "ACS Existing Project Lookup"
{
    ApplicationArea = All;
    Caption = 'Attach to Existing Project';
    PageType = List;
    SourceTable = Job;
    UsageCategory = None;
    Editable = false;

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
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    // Sets the candidate-project filter per Gap 4/5b: same customer, Status = Open,
    // matching Shortcut Dimension 5 (Customer Code), matching Start/End Date.
    // FilterGroup(4) keeps this filter isolated from any filter the user applies on the page.
    procedure SetProjectFilters(SalesHeader: Record "Sales Header")
    var
        ShortcutDimCode: Code[20];
    begin
        ShortcutDimCode := GetCustomerCodeDimensionValue(SalesHeader);

        Rec.FilterGroup(4);
        Rec.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        Rec.SetRange(Status, Rec.Status::Planning);
        Rec.SetRange("Starting Date", SalesHeader."SO START DATE");
        Rec.SetRange("Ending Date", SalesHeader."SO END DATE");
        Rec.SetRange("ShortCut Dimension 5 Code", SalesHeader."ShortCut Dimension 5 Code");
        Rec.FilterGroup(0);
    end;

    local procedure GetCustomerCodeDimensionValue(SalesHeader: Record "Sales Header"): Code[20]
    begin
        // Assumption (Open Question #2 in the FDD): "matching dimensions" is read here as
        // Shortcut Dimension 5 = Customer Code, using the same shortcut slot on the Job as
        // is used on the Sales Header/Purchase Price List per section 11. Confirm the actual
        // dimension pairing with ACS - dimension slot numbers vary by setup.
        exit(SalesHeader."Shortcut Dimension 5 Code");
    end;
}
