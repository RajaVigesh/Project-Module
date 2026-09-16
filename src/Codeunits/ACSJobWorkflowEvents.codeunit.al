// //codeunit 50802 "Manual Release Event Handler"
//{


// Dragon

// [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterModifyEvent', '', false, false)]
// local procedure OnAfterTransferHeaderModify(var Rec: Record "Transfer Header"; RunTrigger: Boolean)
// begin
//     if Rec.Status <> Rec.Status::Released then begin
//         CODEUNIT.Run(CODEUNIT::"Release Transfer Document", Rec);
//         Commit();
//     end;
// end;
//}

codeunit 90112 ApprovalsMgmtCustom
{
    var
        ApprovalEntry: Record "Approval Entry";
        Company: Record "Company Information";

        Usersetup: Record "User Setup";

        WorkfloweventHandling: Codeunit "Workflow Event Handling";

        WorkflowManagement: Codeunit "Workflow Management";

        RecRef: RecordRef;

        VariantRec: Variant;
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
        DynamicRequestPageField: Record "Dynamic Request Page Field";
        Workflowsetup: Codeunit "Workflow Setup";
        BlankdateFormula: DateFormula;
        NoWorkflowEnabledErr: Label 'This record is not supported by related approval workflow';

        //MRQ
        JobRecJobDocCategoryTxt: Label 'Jobs';
        JobRecJobDocCategoryDescTxt: Label 'Job Document';
        JobRecJobAppWorkflowCodeTxt: Label 'JBQAPW-1';
        JobAppWorkflowDescTxt: Label 'Job Approval Workflows';
        RecJob: Record Job;
    //MRQ


    procedure CheckApprovalsWorkflowEnabled(var Variant: Variant): Boolean
    begin
        if not IsApprovalsWorkflowEnabled(Variant) then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure IsApprovalsWorkflowEnabled(var Variant: Variant): Boolean
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::Job:
                begin
                    RecRef.SetTable(RecJob);
                    exit(WorkflowManagement.CanExecuteWorkflow(RecJob, RunworkflowSendJobDocForApprovalCode()))
                end;

        end
    end;

    procedure RunworkflowSendJobDocForApprovalCode(): Text
    begin
        exit(UpperCase('RunWorkflowOnSendJobDocForApproval'))
    end;

    [IntegrationEvent(false, false)]

    procedure OnSendDocForApproval(var Variant: Variant)
    begin

    end;

    procedure RunworkflowCancelJobDocForApprovalCode(): Text
    begin
        exit(UpperCase('RunWorkflowOnCancelJobDocForApproval'))
    end;

    [IntegrationEvent(false, false)]

    procedure OnCancelDocForApproval(var Variant: Variant)
    begin

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::ApprovalsMgmtCustom, 'OnSendDocForApproval', '', false, false)]

    procedure RunWorkflowOnSendDocForApproval(var Variant: Variant)
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::Job:
                begin
                    RecRef.SetTable(RecJob);
                    WorkflowManagement.HandleEvent(RunworkflowSendJobDocForApprovalCode(), RecJob);
                end;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ApprovalsMgmtCustom, 'OnCancelDocForApproval', '', false, false)]

    procedure RunWorkflowOnCancelApprovalRequest(var Variant: Variant)
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::Job:
                begin
                    RecRef.SetTable(RecJob);
                    WorkflowManagement.HandleEvent(RunworkflowCancelJobDocForApprovalCode(), RecJob);
                end;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", OnSetStatusToPendingApproval, '', false, false)]

    local procedure ApprovalMgmt_OnsetstatustoPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        MultiLevelApproval: Codeunit ApprovalsMgmtCustom;
    begin
        if SetStatusToPendingApprovalIntegration(Variant, IsHandled) then
            exit;
    end;

    procedure SetStatusToPendingApprovalIntegration(var Variant: Variant; var IsHandled: Boolean): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::Job:
                begin
                    RecRef.SetTable(RecJob);
                    RecJob.Validate("Approval Status", RecJob."Approval Status"::"Pending Approval");
                    RecJob.Modify(true);
                    Variant := RecJob;
                    IsHandled := true;
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", OnAddWorkflowEventsToLibrary, '', false, false)]

    local procedure AddCustomWorkflowEventsToLibrary()
    var
        WorkflowEventCU: Codeunit "Workflow Event Handling";
        JobSendForApprovalEventDesctxt: Label 'An Approval of a Job is requested';
        JobCancelForApprovalEventDesctxt: Label 'An Approval of a Job is Cancelled';

    begin
        WorkflowEventCU.AddEventToLibrary(RunworkflowSendJobDocForApprovalCode(), Database::Job, JobSendForApprovalEventDesctxt, 0, false);
        WorkflowEventCU.AddEventToLibrary(RunworkflowCancelJobDocForApprovalCode(), Database::Job, JobCancelForApprovalEventDesctxt, 0, false);

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", OnAddWorkflowEventPredecessorsToLibrary, '', false, false)]
    local procedure AddCustomWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventCU: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            WorkflowEventCU.RunWorkflowOnApproveApprovalRequestCode():
                begin
                    WorkflowEventCU.AddEventPredecessor(WorkflowEventCU.RunWorkflowOnApproveApprovalRequestCode(), RunworkflowSendJobDocForApprovalCode());

                end;
            WorkflowEventCU.RunWorkflowOnRejectApprovalRequestCode():
                begin
                    WorkflowEventCU.AddEventPredecessor(WorkflowEventCU.RunWorkflowOnRejectApprovalRequestCode(),
                    RunworkflowSendJobDocForApprovalCode());

                end;
            WorkflowEventCU.RunWorkflowOnDelegateApprovalRequestCode():
                begin
                    WorkflowEventCU.AddEventPredecessor(WorkflowEventCU.RunWorkflowOnDelegateApprovalRequestCode(),
                    RunworkflowSendJobDocForApprovalCode());

                end;
        end
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAfterInsertApprovalsTableRelations, '', false, false)]
    local procedure WorkflowSetup_OnAfterInsertApprovalsTableRelation()
    var
    begin
        InsertApprovalTableRelationIntegration();
    end;

    procedure InsertApprovalTableRelationIntegration()
    begin
        InsertTableRelation(Database::Job, 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));

    end;

    procedure InsertTableRelation(TableId: Integer; FieldId: Integer; RelatedTableId: Integer; RelatedFieldId: Integer)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
    begin
        WorkflowTableRelation.Init();
        WorkflowTableRelation."Table ID" := TableId;
        WorkflowTableRelation."Field ID" := FieldId;
        WorkflowTableRelation."Related Table ID" := RelatedTableId;
        WorkflowTableRelation."Related Field ID" := RelatedFieldId;
        if WorkflowTableRelation.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", OnReleaseDocument, '', false, false)]
    local procedure WorkflowResHandling_OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        Variant_var: Variant;
    begin
        Variant_var := RecRef;
        if IntegrationReleaseDocument(Variant_var, Handled) then
            exit;
    end;

    procedure IntegrationReleaseDocument(var Variant: Variant; var Handled: Boolean): Boolean

    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::Job:
                begin
                    ReleaseJobDocument(Variant);
                    Handled := true;
                    exit(true);

                end;

            //ASN
            else
                exit(false);
        end;
    end;

    procedure ReleaseJobDocument(var JobHeader: Record Job)
    begin
        OnBeforeReleaseJobDoc(JobHeader);
        if JobHeader."Approval Status" = JobHeader."Approval Status"::Released then
            exit;
        JobHeader.Validate("Approval Status", JobHeader."Approval Status"::Released);
        JobHeader.Validate(Status, JobHeader.Status::Open);
        JobHeader.Modify();
        OnAfterReleaseJobDoc(JobHeader);
    end;

    [InternalEvent(false, false)]
    procedure OnBeforeReleaseJobDoc(var JobHeader: Record Job)
    begin

    end;

    [InternalEvent(false, false)]
    procedure OnAfterReleaseJobDoc(var JobHeader: Record Job)
    begin

    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", OnOpenDocument, '', false, false)]
    local procedure WorkflowResponseHandling_OnOpenDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        Variant_Var: Variant;
    begin
        Variant_Var := RecRef;
        if IntegrationOpenDocument(Variant_Var, Handled) then
            exit;
    end;

    procedure IntegrationOpenDocument(var Variant: Variant; var Handled: Boolean): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number() of
            DATABASE::Job:
                begin
                    OpenJobDocment(Variant);
                    Handled := true;
                    exit(true);
                end;

            else
                exit(false);
        end;
    end;

    procedure OpenJobDocment(var JobHeader: Record Job)
    begin
        OnBeforeReopenJobDoc(JobHeader);


        if JobHeader."Approval Status" = JobHeader."Approval Status"::Open then
            exit;

        JobHeader.Validate("Approval Status", JobHeader."Approval Status"::Open);
        JobHeader.Validate(Status, JobHeader.Status::Planning);

        JobHeader.Modify(true);
        OnAfterReopenJobDoc(JobHeader);
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeReopenJobDoc(var JobHeader: Record Job)
    begin

    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterReopenJobDoc(var JobHeader: Record Job)
    begin

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAddWorkflowCategoriesToLibrary, '', false, false)]
    local procedure AddCustomWorkflowCategoriesToLibrary()
    var
        Workflowsetup: Codeunit "Workflow Setup";
    begin
        Workflowsetup.InsertWorkflowCategory(JobRecJobDocCategoryTxt, JobRecJobDocCategoryDescTxt);

    end;

    local procedure InsertReqPageEntity(Name: Code[20]; Description: Text[100]; TableId: Integer; RelatedTableId: Integer)
    begin
        if not FindReqPageEntity(Name, TableId, RelatedTableId) then
            CreateReqpageEntity(Name, Description, TableId, RelatedTableId);
    end;

    local procedure FindReqPageEntity(Name: Code[20]; TableId: Integer; RelatedTableId: Integer): Boolean
    begin
        DynamicRequestPageEntity.SetRange(Name, Name);
        DynamicRequestPageEntity.SetRange("Table ID", TableId);
        DynamicRequestPageEntity.SetRange("Related Table ID", RelatedTableId);
        exit(DynamicRequestPageEntity.FindFirst());
    end;

    local procedure CreateReqpageEntity(Name: Code[20]; Description: Text[100]; TableId: Integer; RelatedTableId: Integer)
    begin
        DynamicRequestPageEntity.Init();
        DynamicRequestPageEntity.Name := Name;
        DynamicRequestPageEntity.Description := Description;
        DynamicRequestPageEntity.Validate("Table ID", TableId);
        DynamicRequestPageEntity.Validate("Related Table ID", RelatedTableId);
        DynamicRequestPageEntity.Insert(true);
    end;

    local procedure InsertReqPageField(TableId: Integer; FieldId: Integer)
    begin
        if not DynamicRequestPageField.Get(TableId, FieldId) then
            CreateReqPageField(TableId, FieldId);
    end;

    local procedure CreateReqPageField(TableId: Integer; FieldId: Integer)
    begin
        DynamicRequestPageField.Init();
        DynamicRequestPageField.Validate("Table ID", TableId);
        DynamicRequestPageField.Validate("Field ID", FieldId);
        DynamicRequestPageField.Insert();
    end;

    local procedure InsertRequestPageFields()
    begin
        InsertJobReqPageFields();
        //CRB

    end;

    local procedure InsertJobReqPageFields()
    var
        JobHeader: Record Job;
    begin
        InsertReqPageField(Database::Job, JobHeader.FieldNo("Approval Status"));
        InsertReqPageField(Database::Job, JobHeader.FieldNo("No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAfterInitWorkflowTemplates, '', false, false)]
    local procedure InsertCustomWorkflowTemplates()
    begin
        InsertReqPageEntities();
        InsertRequestPageFields();

        AssignEntitiesToWorkflowEvents();
        InsertWorkflowTemplates()

    end;

    local procedure AssignEntitiesToWorkflowEvents()
    begin

        AssignEntityToWorkflowEvent(Database::Job, JobRecJobDocCategoryTxt);

    end;

    local procedure AssignEntityToWorkflowEvent(TableID: Integer; DynamicReqPageEntityName: Text)
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowEvent.SetRange("Table ID", TableID);
        if WorkflowEvent.FindFirst() then
            WorkflowEvent.ModifyAll("Dynamic Req. Page Entity Name", DynamicReqPageEntityName, true);
    end;

    local procedure InsertReqPageEntities()
    begin

        InsertReqPageEntity(JobRecJobDocCategoryTxt, JobRecJobDocCategoryDescTxt, Database::Job, Database::"Job Planning Line");

        ;

    end;


    local procedure InsertWorkflowTemplates()
    begin
        InsertJobApprovalWorkflowTemplate();

    end;

    local procedure InsertJobApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        Workflow.Reset();
        Workflow.SetRange(Code, Workflowsetup.GetWorkflowTemplateCode(JobRecJobAppWorkflowCodeTxt));
        if Workflow.IsEmpty then begin
            Workflowsetup.InsertWorkflowTemplate(Workflow, JobRecJobAppWorkflowCodeTxt, JobAppWorkflowDescTxt, JobRecJobDocCategoryTxt);
            InsertJobApprovalworkflowDetails(Workflow);
            Workflowsetup.MarkWorkflowAsTemplate(Workflow);
        end;
    end;

    local procedure InsertJobApprovalworkflowDetails(var workflow: Record Workflow)
    var
        JobHeaderRecord: Record Job;
        ApprovalEntry: Record "Approval Entry";
        WorkflowStepArgumnet: Record "Workflow Step Argument";
    begin




        InsertTableRelation(Database::Job, 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        Workflowsetup.InsertDocApprovalWorkflowSteps(workflow, BuildJobCreateConditions(JobHeaderRecord."Approval Status"::Open),
        RunworkflowSendJobDocForApprovalCode(),
        BuildJobCreateConditions(JobHeaderRecord."Approval Status"::"Pending Approval"),
        RunworkflowCancelJobDocForApprovalCode(), WorkflowStepArgumnet, true);
    end;

    /* //CRB
     local procedure InsertCRBApprovalworkflowDetails(var workflow: Record Workflow)
     var
         CustomeRunningBill: Record "CIT Customer Running Bill";
         ApprovalEntry: Record "Approval Entry";
         WorkflowStepArgumnet: Record "Workflow Step Argument";
     begin
         InsertTableRelation(Database::"CIT Customer Running Bill", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
         Workflowsetup.InsertDocApprovalWorkflowSteps(workflow, BuildCRBCreateConditions(CustomeRunningBill."Approval status"::Open),
         RunworkflowSendCustomerRunningBillDocForApprovalCode(),
         BuildCRBCreateConditions(CustomeRunningBill."Approval status"::"Pending for Approval"),
         RunworkflowCancelCustomerRunningBilltDocForApprovalCode(), WorkflowStepArgumnet, true);
     end;
     */
    //CRB

    local procedure BuildJobCreateConditions(Status: Enum "Project Approval Status"): Text
    var
        JobHeader: Record Job;
        WorkflowSetup: Codeunit "Workflow Setup";
        JobCreateConditionsTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Job">%1</DataItem></DataItems></ReportParameters>';
    begin
        JobHeader.Reset();
        JobHeader.SetRange("Approval Status", Status);

        exit(StrSubstNo(JobCreateConditionsTxt, WorkflowSetup.Encode(JobHeader.GetView(false))));
    end;

    //Release Manual
    procedure ReleaseManual(Variant: Variant)
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number of

            Database::Job:
                ManuallyReleaseJobHeader(Variant);
        end;
    end;
    //Release Manual

    procedure ManuallyReleaseJobHeader(var JobHeaderRec: Record Job)
    var
        ErrorMsgPendingApproval: Label '%1 has been sent for approval.';
        CheckWorkflowenabled: Label 'This document can only be released when the approval process is complete.';
        JobRecord: Record Job;
    begin
        case JobHeaderRec."Approval Status" of
            JobHeaderRec."Approval Status"::Released:
                exit;
            JobHeaderRec."Approval Status"::"Pending Approval":
                Error(ErrorMsgPendingApproval, JobHeaderRec."No.");
            JobHeaderRec."Approval Status"::Open:
                begin
                    VariantRec := JobHeaderRec;
                    if IsApprovalsWorkflowEnabled(VariantRec) then
                        Error(CheckWorkflowenabled);
                end;
        end;
        JobRecord.Reset();
        JobRecord.SetRange("No.", JobHeaderRec."No.");

        if JobRecord.FindFirst() then begin
            JobRecord.Validate("Approval Status", JobRecord."Approval Status"::Released);
            JobRecord.Validate(Status, JobRecord.Status::Open);
            JobRecord.Modify(true);


        end;
    end;


    //Open Record 

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", OnConditionalCardPageIDNotFound, '', false, false)]

    local procedure OpenRecord(RecordRef: RecordRef; var CardPageID: Integer)
    var
    begin
        case RecordRef.Number of
            Database::Job:
                CardPageID := Page::"Job Card";

        end;
    end;
    //Open Record

    //flow document no in Approval Entry
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterPopulateApprovalEntryArgument', '', false, false)]
    local procedure UpdateDocumentNo(var ApprovalEntryArgument: Record "Approval Entry"; var RecRef: RecordRef; var IsHandled: Boolean; WorkflowStepInstance: Record "Workflow Step Instance")
    var

        RecJob: Record Job;
    begin

        case RecRef.Number of
            Database::Job:
                BEGIN
                    RecRef.SETTABLE(RecJob);
                    ApprovalEntryArgument."Document No." := RecJob."No.";

                END;
        end;
    end;


}





