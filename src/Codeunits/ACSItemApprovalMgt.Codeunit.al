// codeunit 90100 "ACS Item Approval Mgt."
// {
//     // ---- Send for Approval (rule 3) ----
//     // [Speculative] Workflow Event Library registration below (OnAddWorkflowEventsToLibrary
//     // / AddEventToLibrary / WorkflowManagement.HandleEvent) follows the standard AL pattern
//     // for extending the Approval Workflow framework to a new document type, but this is the
//     // least-documented integration point in the whole extension - compile and test this
//     // codeunit first and adjust signatures/procedure names against the actual base app
//     // version before relying on it. The outcome handling below (OnAfterModifyApprovalEntry)
//     // does not depend on these exact names and is solid regardless.
//     procedure SendForApproval(var Item: Record Item)
//     var
//         WorkflowManagement: Codeunit "Workflow Management";
//         NoWorkflowSetupErr: Label 'No approval workflow is enabled for item approval requests. Set one up in Workflows before sending items for approval.';
//     begin
//         ValidateMandatoryFields(Item);

//         if not WorkflowManagement.CanExecuteWorkflow(Item, RunWorkflowOnSendItemForApprovalCode()) then
//             Error(NoWorkflowSetupErr);

//         WorkflowManagement.HandleEvent(RunWorkflowOnSendItemForApprovalCode(), Item);

//         Item."ACS Status" := Item."ACS Status"::"Pending Approval";
//         Item.Modify(true);
//     end;

//     local procedure ValidateMandatoryFields(Item: Record Item)
//     begin
//         // Minimum set per the FDD; confirm the full list with ACS (Open Question #3).
//         Item.TestField(Description);
//         Item.TestField("Base Unit of Measure");
//         Item.TestField("Item Category Code");
//     end;

//     [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
//     local procedure OnAddWorkflowEventsToLibrary()
//     var
//         WorkflowEventHandling: Codeunit "Workflow Event Handling";
//         SendItemForApprovalEventDescriptionTxt: Label 'Item is sent for approval';
//     begin
//         WorkflowEventHandling.AddEventToLibrary(
//             RunWorkflowOnSendItemForApprovalCode(), Database::Item, SendItemForApprovalEventDescriptionTxt, 0, true);
//     end;

//     procedure RunWorkflowOnSendItemForApprovalCode(): Code[128]
//     begin
//         exit(UpperCase('RUNWORKFLOWONSENDITEMFORAPPROVALCODE'));
//     end;

//     // ---- Approval outcome (rules 4 & 5) - reads generically off Approval Entry, so it
//     // doesn't depend on the workflow registration details above being exactly right. ----
//     [EventSubscriber(ObjectType::Table, Database::"Approval Entry", 'OnAfterModifyEvent', '', false, false)]
//     local procedure OnAfterModifyApprovalEntry(var Rec: Record "Approval Entry"; var xRec: Record "Approval Entry"; RunTrigger: Boolean)
//     var
//         Item: Record Item;
//         RecRef: RecordRef;
//     begin
//         if Rec."Table ID" <> Database::Item then
//             exit;
//         if Rec.Status = xRec.Status then
//             exit;
//         if not (Rec.Status in [Rec.Status::Approved, Rec.Status::Rejected]) then
//             exit;
//         if not RecRef.Get(Rec."Record ID to Approve") then
//             exit;
//         RecRef.SetTable(Item);

//         // Terminology reconciliation (Open Question #5): the FDD calls this "Inactive" in
//         // one place but the field table uses Rejected - using Rejected consistently.
//         if Rec.Status = Rec.Status::Approved then
//             Item."ACS Status" := Item."ACS Status"::Active
//         else
//             Item."ACS Status" := Item."ACS Status"::Rejected;
//         Item.Modify(true);
//     end;

//     // ---- Rule 2 - block non-Active items from transactional use everywhere (shared) ----
//     procedure ValidateItemIsActive(ItemNo: Code[20])
//     var
//         Item: Record Item;
//         ItemNotActiveErr: Label 'Item %1 has status %2 and cannot be used on a transaction line until it is Active.', Comment = '%1 = item no., %2 = status';
//     begin
//         if ItemNo = '' then
//             exit;
//         Item.SetLoadFields("ACS Status");
//         if not Item.Get(ItemNo) then
//             exit;
//         if Item."ACS Status" <> Item."ACS Status"::Active then
//             Error(ItemNotActiveErr, ItemNo, Item."ACS Status");
//     end;

//     [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'No.', false, false)]
//     local procedure OnAfterValidateSalesLineNo(var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
//     begin
//         if Rec.Type = Rec.Type::Item then
//             ValidateItemIsActive(Rec."No.");
//     end;

//     [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'No.', false, false)]
//     local procedure OnAfterValidatePurchaseLineNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line")
//     begin
//         if Rec.Type = Rec.Type::Item then
//             ValidateItemIsActive(Rec."No.");
//     end;

//     [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterValidateEvent', 'No.', false, false)]
//     local procedure OnAfterValidateJobPlanningLineNo(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line")
//     begin
//         if Rec.Type = Rec.Type::Item then
//             ValidateItemIsActive(Rec."No.");
//     end;
// }
