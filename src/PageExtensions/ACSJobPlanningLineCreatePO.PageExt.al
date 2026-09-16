pageextension 90105 "ACS Job Planning Lines Ext" extends "Job Planning Lines"
{
    layout
    {
        addafter("Job Task No.")
        {
            field("ACS CIT Vendor No."; Rec."ACS CIT Vendor No.")
            {
                Caption = 'Vendor No.';
                ApplicationArea = All;
                Editable = Rec."Purchase Order No." = '';
                ToolTip = 'Specifies the vendor resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
            }
            field("ACS Vendor Name"; Rec."ACS Vendor Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the name of the vendor resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
                Editable = false;
                Caption = 'Vendor Name';
            }
            field("ACS Item Category Code"; Rec."ACS Item Category Code")
            {
                ApplicationArea = All;
                Caption = 'Item Category Code';
                ToolTip = 'Specifies the item category code resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
            }
            field("ACS Source Quote No."; Rec."ACS Source Quote No.")
            {
                ApplicationArea = all;
                Caption = 'Source Quote No.';
                Editable = false;
            }
            field("purchase Order No."; Rec."Purchase Order No.")
            {
                ApplicationArea = all;
                Caption = 'Purchase Order No.';
                Editable = false;
            }
        }
        addafter("Qty. to Transfer to Invoice")
        {
            field("Qty Invoiced"; Rec."Qty. Invoiced")
            {
                ApplicationArea = All;
                Caption = 'Qty. Invoiced';
                Editable = false;
            }
        }
        addafter("Line Amount")
        {
            field("Remaining Amount"; Rec."Line Amount" - Rec."Invoiced Amount (LCY)")
            {
                ApplicationArea = All;
                Caption = 'Remaining Amount';
                Editable = false;
            }
            field("Qty to Transfer to Invoice"; Rec."Qty. to Transfer to Invoice")
            {
                ApplicationArea = All;
                Caption = 'Qty. to Transfer to Invoice';
                // Editable = false;

            }
        }
        addafter(quantity)
        {
            field("QtyPosted"; Rec."Qty. Posted")
            {
                ApplicationArea = All;
                Caption = 'Qty. Posted';
                Editable = false;
            }
        }
        addafter("No.")
        {
            field("Item Reference No."; Rec."Item Reference No.")
            {
                ApplicationArea = All;
                Caption = 'Item Reference No.';
                ToolTip = 'Specifies the reference number of the item resolved from the Purchase Price List for this customer, or entered manually when no match was found.';
            }
        }

        modify("Unit Price")
        {
            Editable = AllowEditJobPlanningLinePrice;
        }
        modify("Planning Date")
        {
            visible = false;
        }
        modify("Planned Delivery Date")
        {
            visible = false;
        }
        modify("Document No.")
        {
            visible = false;
        }
        modify("Cost Calculation Method")
        {
            visible = false;
        }
        modify("Price Calculation Method")
        {
            visible = false;
        }
        modify("Qty. to Assemble")
        {
            visible = false;
        }
        modify("Qty. to Transfer to Journal")
        {
            Caption = 'Usage Qty.';
        }
    }
    actions
    {
        addlast(Processing)
        {
            action(CreatePurchaseOrderNew)
            {
                Caption = 'Create Purchase Order';
                Image = Purchase;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelectedLines: Record "Job Planning Line";
                    JobPLCreatePO: Codeunit "Job Planning Line-Create PO";
                begin
                    CurrPage.SetSelectionFilter(SelectedLines);

                    if SelectedLines.IsEmpty() then begin
                        SelectedLines := Rec;
                        SelectedLines.SetRecFilter();
                    end;

                    JobPLCreatePO.CreatePOs(SelectedLines);
                    CurrPage.Update(false);
                end;
            }

            action(ShowPurchaseOrders)
            {
                Caption = 'Purchase Orders';
                Image = Purchase;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    JobPLCreatePO: Codeunit "Job Planning Line-Create PO";
                begin
                    JobPLCreatePO.ShowPurchaseOrdersForJob(Rec."Job No.", Rec."Job Task No.", Rec."Line No.");
                end;
            }

            action(ShowPostedPurchaseInvoices)
            {
                Caption = 'Posted Purchase Invoices';
                Image = Purchase;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    JobPLCreatePO: Codeunit "Job Planning Line-Create PO";
                begin
                    JobPLCreatePO.ShowPostedPurchaseInvoicesForJob(Rec."Job No.", Rec."Job Task No.", Rec."Line No.");
                end;
            }
        }
        modify(CreateJobJournalLines)
        {
            trigger OnBeforeAction()
            var
                myInt: Integer;
            begin
                OnBeforeActionEventCreateJobJournalLines(Rec);
            end;
        }
        addafter(CreateJobJournalLines)
        {
            action("&Open Job JournalNew")
            {
                ApplicationArea = Jobs;
                Caption = '&Open Project Journal';
                Image = Journals;
                RunObject = Page "Job Journal";
                RunPageLink = "Job No." = field("Job No.");
                ToolTip = 'Open the project journal, for example, to post usage for a project.';
            }
        }
        modify("&Open Job Journal")
        {
            visible = false;
        }
    }
    procedure OnBeforeActionEventCreateJobJournalLines(
    var Rec: Record "Job Planning Line")
    var
        SelectedLines: Record "Job Planning Line";
        PurchaseLine: Record "Purchase Line";
        MissingLines: Text;
    begin
        if Rec.IsEmpty() then
            exit;
        SelectedLines.Copy(Rec);
        CurrPage.SetSelectionFilter(SelectedLines);
        SelectedLines.SetFilter(Type, '<>%1', SelectedLines.Type::Text);
        SelectedLines.SetFilter("ACS CIT Vendor No.", '<>%1', '');
        if SelectedLines.FindSet() then
            repeat
                PurchaseLine.Reset();

                PurchaseLine.SetRange(
                    "Document Type",
                    PurchaseLine."Document Type"::Order);

                PurchaseLine.SetRange(
                    "Job No.",
                    SelectedLines."Job No.");

                PurchaseLine.SetRange(
                    "Job Task No.",
                    SelectedLines."Job Task No.");

                PurchaseLine.SetRange(
                    "Job Planning Line No.",
                    SelectedLines."Line No.");

                if not PurchaseLine.FindFirst() then begin
                    if MissingLines <> '' then
                        MissingLines += ', ';

                    MissingLines +=
                        StrSubstNo(
                            '%1 / %2 / %3',
                            SelectedLines."Job No.",
                            SelectedLines."Job Task No.",
                            SelectedLines."Line No.");
                end;

            until SelectedLines.Next() = 0;

        if MissingLines <> '' then
            Error(
                'Purchase Order is not created for the following Job Planning Line(s): %1',
                MissingLines);
    end;

    var
        AllowEditJobPlanningLinePrice: Boolean;

    trigger OnAfterGetRecord()
    var
        UserSetup: Record "User Setup";
    begin
        // if Rec."ACS Non-Market Item" then begin
        if UserSetup.Get(UserId()) then
            AllowEditJobPlanningLinePrice := UserSetup."ACS Allow Edit JPL Price"
        else
            AllowEditJobPlanningLinePrice := false;
        //end
    end;


}
