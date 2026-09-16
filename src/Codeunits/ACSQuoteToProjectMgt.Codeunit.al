codeunit 90105 "ACS Quote To Project Mgt."
{
    // Entry point for the "ACS Create Project" quote action (5a).
    //
    // [Speculative] This action is implemented as a new, self-contained action rather than
    // as a subscriber wrapping an existing "Create Project" action/codeunit, because the FDD
    // references an existing Create Project flow (and an "Existing item-lookup-by-category
    // customization on Sales Quote Lines" per 5d) that isn't part of this object inventory
    // and whose codeunit/event name is unknown here. If ACS already has that prior
    // customization, this procedure's project-creation block (CreateNewProject) should be
    // replaced with a call into it, and its confirm/attach decision tree spliced into its
    // entry point instead - everything downstream (attach validation, task/planning line
    // creation, attachment transfer) is unaffected either way.
    procedure RunCreateProjectFlow(var SalesHeader: Record "Sales Header")
    var
        Job: Record Job;
        ExistingProjectLookup: Page "ACS Existing Project Lookup";
        AttachToExistingQst: Label 'Do you want to attach the Sales Quote to an existing Project?';
        AlreadyLinkedErr: Label 'Sales Quote %1 is already linked to Project %2.', Comment = '%1 = quote no., %2 = project no.';
        CancelledQuoteErr: Label 'The selected Sales Quote has been cancelled and cannot be used for Project creation.';
    begin
        if SalesHeader."ACS Quote Status" = SalesHeader."ACS Quote Status"::Cancelled then
            Error(CancelledQuoteErr);

        if SalesHeader."ACS Quote Status" = SalesHeader."ACS Quote Status"::Closed then
            Error('Sales Quote %1 is already closed and linked to a Project. It cannot be changed.', SalesHeader."No.");

        if SalesHeader."ACS Linked Project No." <> '' then
            Error(AlreadyLinkedErr, SalesHeader."No.", SalesHeader."ACS Linked Project No.");

        Job.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        Job.SetRange(Status, Job.Status::Planning);
        Job.SetRange("Starting Date", SalesHeader."SO START DATE");
        Job.SetRange("Ending Date", SalesHeader."SO END DATE");
        job.SetRange("Shortcut Dimension 5 Code", SalesHeader."Shortcut Dimension 5 Code");
        if not Job.FindFirst() then begin
            CreateNewProject(SalesHeader, Job);
            FinalizeConsolidation(SalesHeader, Job);
            exit;
        end
        else
            Message('There is already Project Existing for this Filters');
    end;

    procedure RunExistingProjectFlow(var SalesHeader: Record "Sales Header")
    var
        Job: Record Job;
        ExistingProjectLookup: Page "ACS Existing Project Lookup";
        AttachToExistingQst: Label 'Do you want to attach the Sales Quote to an existing Project?';
        AlreadyLinkedErr: Label 'Sales Quote %1 is already linked to Project %2.', Comment = '%1 = quote no., %2 = project no.';
        CancelledQuoteErr: Label 'The selected Sales Quote has been cancelled and cannot be used for Project creation.';
    begin
        if SalesHeader."ACS Quote Status" = SalesHeader."ACS Quote Status"::Cancelled then
            Error(CancelledQuoteErr);

        if SalesHeader."ACS Quote Status" = SalesHeader."ACS Quote Status"::Closed then
            Error('Sales Quote %1 is already closed and linked to a Project. It cannot be changed.', SalesHeader."No.");

        if SalesHeader."ACS Linked Project No." <> '' then
            Error(AlreadyLinkedErr, SalesHeader."No.", SalesHeader."ACS Linked Project No.");

        if Confirm(AttachToExistingQst, false) then begin
            existingProjectLookup.SetProjectFilters(SalesHeader);
            ExistingProjectLookup.LookupMode(true);
            if ExistingProjectLookup.RunModal() = Action::LookupOK then begin
                ExistingProjectLookup.GetRecord(Job);
                AttachToExistingProject(SalesHeader, Job);
            end;
        end;
    end;

    // 5c - attach-to-existing validation, enforced as blocking errors.
    procedure AttachToExistingProject(var SalesHeader: Record "Sales Header"; Job: Record Job)
    var
        JobPlanningLine: Record "Job Planning Line";
        AttachedMsg: Label 'Sales Quote %1 has been attached to Project %2.', Comment = '%1 = quote no., %2 = project no.';
        AlreadyOnProjectErr: Label 'Sales Quote %1 has already been attached to Project %2.', Comment = '%1 = quote no., %2 = project no.';
    begin
        SalesHeader.TestField("ACS Linked Project No.", '');

        JobPlanningLine.SetLoadFields("ACS Source Quote No.");
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("ACS Source Quote No.", SalesHeader."No.");
        if not JobPlanningLine.IsEmpty() then
            Error(AlreadyOnProjectErr, SalesHeader."No.", Job."No.");

        FinalizeConsolidation(SalesHeader, Job);
        Message(AttachedMsg, SalesHeader."No.", Job."No.");
    end;

    local procedure FinalizeConsolidation(var SalesHeader: Record "Sales Header"; Job: Record Job)
    var
        ACSProjectTaskCreationMgt: Codeunit "ACS Project Task Creation Mgt.";
        ACSQuoteAttachmentTransfer: Codeunit "ACS Quote Attachment Transfer";
        JobCard: Page "Job Card";
        JobCreatedMsg: Label 'Job %1 has been created and opened successfully.', Comment = '%1 = Job No.';
    begin
        ACSProjectTaskCreationMgt.CreateTasksAndPlanningLines(SalesHeader, Job);

        SalesHeader."ACS Linked Project No." := Job."No.";
        SalesHeader."ACS Quote Status" := SalesHeader."ACS Quote Status"::Closed;
        SalesHeader.Modify(true);

        // Sequenced strictly after confirmed success above - never runs if project
        // creation/attach or task/line creation failed (Gap 3, rule 5).
        ACSQuoteAttachmentTransfer.TransferAttachments(SalesHeader."No.", Job."No.");

        Message(JobCreatedMsg, Job."No.");

        //  JobCard.SetTableView(Job);
        //  JobCard.Run();
    end;

    // 5a "No" branch - minimal standard Job creation. Replace with ACS's existing Create
    // Project codeunit if one already exists (see class-level comment above); this covers
    // the fields the rest of this extension needs (customer, dates, dimension) but a real
    // deployment likely needs Job Posting Group, WIP method, and other Job Card defaults
    // that ACS's own setup already governs.
    local procedure CreateNewProject(SalesHeader: Record "Sales Header"; var Job: Record Job)
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Codeunit "No. Series";
        WorkDescriptionInStream: InStream;
        WorkDescriptionOutStream: OutStream;
        JobCreateErr: Label 'Project creation failed for Sales Quote %1. Check Job setup and required values.', Comment = '%1 = Sales Quote No.';
    begin
        JobsSetup.Get();
        JobsSetup.TestField("Job Nos.");

        Job.Init();
        Job."No." := NoSeries.GetNextNo(JobsSetup."Job Nos.");
        if not Job.Insert(true) then
            Error(JobCreateErr, SalesHeader."No.");

        Job.Validate(Description, SalesHeader."Sell-to Customer Name");
        Job.Validate("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        Job.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Job.Validate("ACS Customer Posting Group", SalesHeader."Customer Posting Group");
        Job.Validate(Status, Job.Status::Planning);
        Job.Validate("Starting Date", SalesHeader."SO START DATE");
        Job.Validate("Ending Date", SalesHeader."SO END DATE");
        Job.Validate("Shortcut Dimension 5 Code", SalesHeader."Shortcut Dimension 5 Code");
        job.Validate("Global Dimension 1 Code", SalesHeader."Shortcut Dimension 1 Code");
        job.Validate("Global Dimension 2 Code", SalesHeader."Shortcut Dimension 2 Code");
        Job.Validate("ShortCut Dimension 3 code", SalesHeader."Shortcut Dimension 3 Code");
        Job.Validate("ShortCut Dimension 4 code", SalesHeader."Shortcut Dimension 4 Code");
        job.Validate("ShortCut Dimension 6 code", SalesHeader."Shortcut Dimension 6 Code");
        job.Validate("ShortCut Dimension 7 code", SalesHeader."Shortcut Dimension 7 Code");
        job.Validate("ShortCut Dimension 8 code", SalesHeader."Shortcut Dimension 8 Code");
        SalesHeader.CalcFields("Work Description");
        SalesHeader."Work Description".CreateInStream(WorkDescriptionInStream);
        Job."CIT Work Description".CreateOutStream(WorkDescriptionOutStream);
        CopyStream(WorkDescriptionOutStream, WorkDescriptionInStream);
        job.Validate("Customer PO Number", SalesHeader."External Document No.");
        job.Validate("Sales Person Code", SalesHeader."Salesperson Code");
        job.Validate("Your Reference", SalesHeader."Your Reference");
        job.Validate("Bill-to Contact", SalesHeader."Bill-to Contact");
        job.Validate("Sell-to Contact", SalesHeader."Sell-to Contact");
        job.Validate("Bill-to Contact No.", SalesHeader."Bill-to Contact No.");
        job.Validate("Sell-to Contact No.", SalesHeader."Sell-to Contact No.");



        if not Job.Modify(true) then
            Error(JobCreateErr, SalesHeader."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnBeforeUpdateJobTaskDimension, '', false, false)]
    local procedure OnBeforeUpdateJobTaskDimension(var IsHandled: Boolean)
    begin
        IsHandled := True;
    end;
}
