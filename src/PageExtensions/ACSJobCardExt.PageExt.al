pageextension 90104 "Job Card Ext" extends "Job Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Project Manager")
        {
            field("ShortCut Dimension 3 Code"; Rec."ShortCut Dimension 3 Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer code for this project, used to match against existing quotes when consolidating projects.';
            }
            field("ShortCut Dimension 4 Code"; Rec."ShortCut Dimension 4 Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer code for this project, used to match against existing quotes when consolidating projects.';
            }
            field("ShortCut Dimension 5 Code"; Rec."ShortCut Dimension 5 Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer code for this project, used to match against existing quotes when consolidating projects.';
            }
            field("ShortCut Dimension 6 Code"; Rec."ShortCut Dimension 6 Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer code for this project, used to match against existing quotes when consolidating projects.';
            }
            field("ShortCut Dimension 7 Code"; Rec."ShortCut Dimension 7 Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer code for this project, used to match against existing quotes when consolidating projects.';
            }
            field("ShortCut Dimension 8 Code"; Rec."ShortCut Dimension 8 Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the customer code for this project, used to match against existing quotes when consolidating projects.';
            }

        }
        addafter(Status)
        {
            field("Approval Status"; Rec."Approval Status")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        modify(Status)
        {
            Editable = false;
        }
        addafter("No. of Archived Versions")
        {
            field("Customer PO Number"; Rec."Customer PO Number")
            {
                ApplicationArea = All;
                caption = 'Customer PO No.';
                ToolTip = 'Specifies the customer purchase order number for this project.';
            }
            field("Sales Person Code"; Rec."Sales Person Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the sales person responsible for this project.';
            }
            field("ACS Customer Posting Group"; Rec."ACS Customer Posting Group")
            {
                ApplicationArea = All;
                Caption = 'Customer Posting Group';
                ToolTip = 'Specifies the customer posting group copied from the sales quote.';
            }
            field("PO Status"; Rec."PO Status")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field(WorkDescription; WorkDescription)
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
                MultiLine = true;
                // ShowCaption = false;
                Caption = 'Work Description';
                ToolTip = 'Specifies the products or service being offered';

            }
        }

    }

    actions
    {
        // Add changes to page actions here
        addlast(Processing)
        {
            action(CreatePOsFromJob)
            {
                ApplicationArea = All;
                Caption = 'Create Purchase Orders';
                Image = Purchase;

                trigger OnAction()
                var
                    JobPLCreatePO: Codeunit "Job Planning Line-Create PO";
                begin
                    JobPLCreatePO.CreatePOsForJob(Rec."No.");
                end;
            }

            action(ShowPurchaseOrdersForJob)
            {
                ApplicationArea = All;
                Caption = 'Purchase Orders';
                Image = Purchase;

                trigger OnAction()
                var
                    JobPLCreatePO: Codeunit "Job Planning Line-Create PO";
                begin
                    JobPLCreatePO.ShowAllPurchaseOrdersForJob(Rec."No.");
                end;
            }

            action(ShowPostedPurchaseInvoicesForJob)
            {
                ApplicationArea = All;
                Caption = 'Posted Purchase Invoices';
                Image = Purchase;

                trigger OnAction()
                var
                    JobPLCreatePO: Codeunit "Job Planning Line-Create PO";
                begin
                    JobPLCreatePO.ShowAllPostedPurchaseInvoicesForJob(Rec."No.");
                end;
            }

            action(CloseProject)
            {
                ApplicationArea = All;
                Caption = 'Close Project';
                Enabled = Rec.Status <> Rec.Status::Completed;
                Image = Completed;
                ToolTip = 'Close the project and prevent further project processing.';

                trigger OnAction()
                var
                    CloseProjectQst: Label 'Do you want to close project %1?', Comment = '%1 = project number';
                begin
                    if Confirm(CloseProjectQst, false, Rec."No.") then begin
                        Rec.Validate(Status, Rec.Status::Completed);
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }

            group(ApprovalRequest)
            {

                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = all;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RunWorkflowEntriesPage(
                            Rec.RecordId(),
                            DATABASE::Job,
                            Enum::"Approval Document Type"::" ",
                            Rec."No.");
                    end;
                }

                action(SendJobApprovalRequest)
                {
                    ApplicationArea = All;
                    Caption = 'Send Approval Request';
                    Image = SendApprovalRequest;
                    // Promoted = true;
                    // PromotedCategory = Process;
                    Enabled = Rec."Approval Status" = Rec."Approval Status"::Open;

                    trigger OnAction()
                    var
                        JobApprovalMgt: Codeunit ApprovalsMgmtCustom;
                        VariantRec: Variant;

                    begin
                        VariantRec := Rec;
                        JobApprovalMgt.OnSendDocForApproval(VariantRec);
                        CurrPage.Update(false);
                    end;
                }
                action(CancelJobApprovalRequest)
                {
                    ApplicationArea = All;
                    Caption = 'Cancel Approval Request';
                    Image = CancelApprovalRequest;
                    // Promoted = true;
                    // PromotedCategory = Process;
                    Enabled = Rec."Approval Status" = Rec."Approval Status"::"Pending Approval";

                    trigger OnAction()
                    var
                        JobApprovalMgt: Codeunit ApprovalsMgmtCustom;
                        VariantRec: Variant;
                    begin
                        VariantRec := rec;
                        JobApprovalMgt.OnCancelDocForApproval(VariantRec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Action3)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = all;
                    Caption = 'Re&lease';
                    Enabled = Rec."Approval Status" <> Rec."Approval Status"::Released;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ApprovalMngetment: Codeunit ApprovalsMgmtCustom;
                        JobVariant: Variant;
                    begin
                        JobVariant := Rec;
                        ApprovalMngetment.ReleaseManual(JobVariant);
                        CurrPage.Update(false);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = all;
                    Caption = 'Re&open';
                    Enabled = Rec."Approval Status" <> Rec."Approval Status"::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ApprovalMngetment: Codeunit ApprovalsMgmtCustom;
                    begin
                        ApprovalMngetment.OpenJobDocment(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }

        }
        addafter(Category_Process)
        {
            group(Category_Category1)
            {
                Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 9.';
                ShowAs = SplitButton;

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }

            }
            actionref(ShowPurchaseOrdersForJob_Promoted; ShowPurchaseOrdersForJob)
            {
            }
            actionref(ShowPostedPurchaseInvoicesForJob_Promoted; ShowPostedPurchaseInvoicesForJob)
            {
            }
        }
        addafter(Category_Category1)
        {
            group(Category_Category2)
            {
                Caption = 'Approval', Comment = 'Generated from the PromotedActionCategories property index 10.';
                ShowAs = SplitButton;

                actionref(SendJobApprovalRequest_Promoted; SendJobApprovalRequest)
                {
                }
                actionref(CancelJobApprovalRequest_Promoted; CancelJobApprovalRequest)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("CIT Work Description");
        WorkDescription := Rec.GetWorkDescription();
    end;
    // procedure OpenApprovalsSales(JobRec: Record Job)
    // begin
    //     ApprovalMngt.RunWorkflowEntriesPage(
    //         JobRec.RecordId(), DATABASE::Job, , JobRec."No.");
    // end;

    var
        myInt: Integer;
        ApprovalMngt: Codeunit "Approvals Mgmt.";
        ApprovalEntries: Record "Approval Entry";
        WorkDescription: Text;
}