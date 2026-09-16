codeunit 70200020 "ACS Vendor Activity Mgt."
{
    // ---- Retrieval (RetrievePlanningLines procedure) ----
    procedure RetrievePlanningLines(var Header: Record "ACS Vendor Activity Header")
    var
        ExistingOpenLine: Record "ACS Vendor Activity Line";
        JobPlanningLine: Record "Job Planning Line";
        ExcludedKeys: Dictionary of [Text, Boolean];
        NextLineNo: Integer;
    begin
        Header.TestField(Status, Header.Status::Open);

        // Re-running retrieval clears the batch's own not-yet-submitted rows first, so
        // repeated retrievals don't duplicate lines. Created/Approved/Rejected lines
        // (already tied to an approval entry) are never touched here.
        ExistingOpenLine.SetRange("Batch Name", Header."Batch Name");
        ExistingOpenLine.SetRange(Status, ExistingOpenLine.Status::Open);
        ExistingOpenLine.DeleteAll(true);

        BuildExclusionSet(ExcludedKeys);

        JobPlanningLine.FilterGroup(4);
        if Header."Project No. Filter" <> '' then
            JobPlanningLine.SetRange("Job No.", Header."Project No. Filter");
        if Header."Vendor No. Filter" <> '' then
            JobPlanningLine.SetRange("ACS CIT Vendor No.", Header."Vendor No. Filter");
        if (Header."Period Start Date" <> 0D) or (Header."Period End Date" <> 0D) then
            JobPlanningLine.SetRange("Planning Date", Header."Period Start Date", Header."Period End Date");
        JobPlanningLine.SetFilter("ACS CIT Vendor No.", '<>%1', '');
        JobPlanningLine.FilterGroup(0);
        JobPlanningLine.SetLoadFields("Job No.", "Job Task No.", "Line No.", Description,
            Quantity, "ACS CIT Vendor No.", "Planning Date");
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "ACS CIT Vendor No.");

        NextLineNo := GetNextActivityLineNo(Header."Batch Name");

        if JobPlanningLine.FindSet() then
            repeat
                // Exclusion checked against an in-memory set built once (BuildExclusionSet),
                // not a per-row IsEmpty() query - avoids the N+1 lookup at scale.
                if not ExcludedKeys.ContainsKey(PlanningLineKey(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.")) then begin
                    InsertActivityLine(Header, JobPlanningLine, NextLineNo);
                    NextLineNo += 1;
                end;
            until JobPlanningLine.Next() = 0;
    end;

    local procedure BuildExclusionSet(var ExcludedKeys: Dictionary of [Text, Boolean])
    var
        ActivityLine: Record "ACS Vendor Activity Line";
    begin
        ActivityLine.SetLoadFields("Job No.", "Job Task No.", "Job Planning Line No.", Status);
        ActivityLine.SetFilter(Status, '%1|%2', ActivityLine.Status::Created, ActivityLine.Status::Approved);
        if ActivityLine.FindSet() then
            repeat
                ExcludedKeys.Add(PlanningLineKey(ActivityLine."Job No.", ActivityLine."Job Task No.", ActivityLine."Job Planning Line No."), true);
            until ActivityLine.Next() = 0;
    end;

    local procedure PlanningLineKey(JobNo: Code[20]; JobTaskNo: Code[20]; PlanningLineNo: Integer): Text
    begin
        exit(JobNo + '|' + JobTaskNo + '|' + Format(PlanningLineNo));
    end;

    local procedure InsertActivityLine(Header: Record "ACS Vendor Activity Header"; JobPlanningLine: Record "Job Planning Line"; LineNo: Integer)
    var
        ActivityLine: Record "ACS Vendor Activity Line";
    begin
        ActivityLine.Init();
        ActivityLine."Batch Name" := Header."Batch Name";
        ActivityLine."Line No." := LineNo;
        ActivityLine."Job No." := JobPlanningLine."Job No.";
        ActivityLine."Job Task No." := JobPlanningLine."Job Task No.";
        ActivityLine."Job Planning Line No." := JobPlanningLine."Line No.";
        ActivityLine."Vendor No." := JobPlanningLine."ACS CIT Vendor No.";
        ActivityLine.Description := JobPlanningLine.Description;
        ActivityLine."Planned Quantity" := JobPlanningLine.Quantity;
        ActivityLine.Status := ActivityLine.Status::Open;
        ActivityLine.Insert(true);
    end;

    local procedure GetNextActivityLineNo(BatchName: Code[20]): Integer
    var
        ActivityLine: Record "ACS Vendor Activity Line";
    begin
        ActivityLine.SetRange("Batch Name", BatchName);
        ActivityLine.SetCurrentKey("Batch Name", "Line No.");
        if ActivityLine.FindLast() then
            exit(ActivityLine."Line No." + 10000);
        exit(10000);
    end;

    // ---- Submit for Approval ----
    // [Speculative] uses the same Workflow Event Library pattern flagged in
    // ACS Item Approval Mgt. - verify signatures before relying on it.
    procedure SubmitForApproval(var Header: Record "ACS Vendor Activity Header")
    var
        ActivityLine: Record "ACS Vendor Activity Line";
        WorkflowManagement: Codeunit "Workflow Management";
        InvalidLinesErr: Label 'This batch has %1 open line(s) with a zero or blank Reported Quantity. Enter a Reported Quantity before submitting for approval.', Comment = '%1 = count';
        NoOpenLinesErr: Label 'There are no open lines to submit in this batch.';
        NoWorkflowSetupErr: Label 'No approval workflow is enabled for vendor activity confirmation. Set one up in Workflows before submitting.';
        SubmittedMsg: Label '%1 line(s) submitted for approval.', Comment = '%1 = count';
        SubmittedCount: Integer;
    begin
        ActivityLine.SetRange("Batch Name", Header."Batch Name");
        ActivityLine.SetRange(Status, ActivityLine.Status::Open);
        if ActivityLine.IsEmpty() then
            Error(NoOpenLinesErr);

        ActivityLine.SetFilter("Reported Quantity", '<=%1', 0);
        if not ActivityLine.IsEmpty() then
            Error(InvalidLinesErr, ActivityLine.Count());
        ActivityLine.SetRange("Reported Quantity");

        if not WorkflowManagement.CanExecuteWorkflow(Header, RunWorkflowOnSubmitVendorActivityCode()) then
            Error(NoWorkflowSetupErr);

        if ActivityLine.FindSet(true) then
            repeat
                WorkflowManagement.HandleEvent(RunWorkflowOnSubmitVendorActivityCode(), ActivityLine);
                ActivityLine.Status := ActivityLine.Status::Created;
                ActivityLine.Modify(true);
                SubmittedCount += 1;
                // Submitted lines drop out of the "eligible" retrieval filter automatically
                // (BuildExclusionSet now finds them at Status = Created) - no second
                // exclusion mechanism, per rule 5.
            until ActivityLine.Next() = 0;

        Message(SubmittedMsg, SubmittedCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        SubmitVendorActivityEventDescriptionTxt: Label 'Vendor activity line is submitted for approval';
    begin
        WorkflowEventHandling.AddEventToLibrary(
            RunWorkflowOnSubmitVendorActivityCode(), Database::"ACS Vendor Activity Line", SubmitVendorActivityEventDescriptionTxt, 0);
    end;

    procedure RunWorkflowOnSubmitVendorActivityCode(): Code[128]
    begin
        exit(UpperCase('RUNWORKFLOWONSUBMITVENDORACTIVITYCODE'));
    end;

    // ---- Traceability - link the created Approval Entry back to its Activity Line
    // and populate Job No./Job Task No. (table extension item 22) ----
    [EventSubscriber(ObjectType::Table, Database::"Approval Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertApprovalEntry(var Rec: Record "Approval Entry")
    var
        ActivityLine: Record "ACS Vendor Activity Line";
        RecRef: RecordRef;
    begin
        if Rec."Table ID" <> Database::"ACS Vendor Activity Line" then
            exit;
        if not RecRef.Get(Rec."Record ID to Approve") then
            exit;
        RecRef.SetTable(ActivityLine);

        Rec."ACS Job No." := ActivityLine."Job No.";
        Rec."ACS Job Task No." := ActivityLine."Job Task No.";
        Rec.Modify(true);

        if ActivityLine.Get(ActivityLine."Batch Name", ActivityLine."Line No.") then begin
            ActivityLine."Approval Entry No." := Rec."Entry No.";
            ActivityLine.Modify(true);
        end;
    end;

    // ---- Approval outcome -> status update + auto job journal posting (Open Question #4:
    // resolved here as auto-post, since the FDD explicitly rules out a manual posting step) ----
    [EventSubscriber(ObjectType::Table, Database::"Approval Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyApprovalEntry(var Rec: Record "Approval Entry"; var xRec: Record "Approval Entry"; RunTrigger: Boolean)
    var
        ActivityLine: Record "ACS Vendor Activity Line";
        RecRef: RecordRef;
    begin
        if Rec."Table ID" <> Database::"ACS Vendor Activity Line" then
            exit;
        if Rec.Status = xRec.Status then
            exit;
        if not (Rec.Status in [Rec.Status::Approved, Rec.Status::Rejected]) then
            exit;
        if not RecRef.Get(Rec."Record ID to Approve") then
            exit;
        RecRef.SetTable(ActivityLine);

        if Rec.Status = Rec.Status::Approved then begin
            ActivityLine.Status := ActivityLine.Status::Approved;
            ActivityLine.Modify(true);
            CreateAndPostJobJournalLine(ActivityLine);
        end else begin
            ActivityLine.Status := ActivityLine.Status::Rejected;
            ActivityLine.Modify(true);
        end;
    end;

    local procedure CreateAndPostJobJournalLine(var ActivityLine: Record "ACS Vendor Activity Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        JobJournalTemplateNameTok: Label 'JOB', Locked = true;
        JobJournalBatchNameTok: Label 'ACSVENDACT', Locked = true;
    begin
        if not JobPlanningLine.Get(ActivityLine."Job No.", ActivityLine."Job Task No.", ActivityLine."Job Planning Line No.") then
            exit;

        JobJournalLine.Init();
        JobJournalLine."Journal Template Name" := JobJournalTemplateNameTok;
        JobJournalLine."Journal Batch Name" := JobJournalBatchNameTok;
        JobJournalLine."Line No." := GetNextJobJournalLineNo(JobJournalTemplateNameTok, JobJournalBatchNameTok);
        JobJournalLine.Insert(true);
        JobJournalLine.Validate("Posting Date", WorkDate());
        JobJournalLine.Validate("Job No.", JobPlanningLine."Job No.");
        JobJournalLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        JobJournalLine.Validate(Type, JobPlanningLine.Type);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
        JobJournalLine.Validate(Quantity, ActivityLine."Reported Quantity");
        JobJournalLine.Validate("Unit Cost", ActivityLine."Unit Cost");
        JobJournalLine."Job Planning Line No." := JobPlanningLine."Line No.";
        JobJournalLine."ACS Vendor Activity Batch Name" := ActivityLine."Batch Name";
        JobJournalLine."ACS Vendor Activity Line No." := ActivityLine."Line No.";
        JobJournalLine.Modify(true);

        // Not wrapped in TryFunction here (unlike Gap 9's consumer of this posting) -
        // a failed post on an Approved activity line needs to surface to the approver
        // rather than fail silently, since nothing else will retry it.
        JobJnlPostLine.Run(JobJournalLine);
    end;

    local procedure GetNextJobJournalLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        if JobJournalLine.FindLast() then
            exit(JobJournalLine."Line No." + 10000);
        exit(10000);
    end;
}
