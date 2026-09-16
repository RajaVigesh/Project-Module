codeunit 70200007 "ACS Quote To Project Mgt."
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

        if SalesHeader."ACS Linked Project No." <> '' then
            Error(AlreadyLinkedErr, SalesHeader."No.", SalesHeader."ACS Linked Project No.");

        if Confirm(AttachToExistingQst, false) then begin
            ExistingProjectLookup.SetProjectFilters(SalesHeader);
            ExistingProjectLookup.LookupMode(true);
            if ExistingProjectLookup.RunModal() = Action::LookupOK then begin
                ExistingProjectLookup.GetRecord(Job);
                AttachToExistingProject(SalesHeader, Job);
            end;
        end else begin
            CreateNewProject(SalesHeader, Job);
            FinalizeConsolidation(SalesHeader, Job);
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
    begin
        ACSProjectTaskCreationMgt.CreateTasksAndPlanningLines(SalesHeader, Job);

        SalesHeader."ACS Linked Project No." := Job."No.";
        SalesHeader.Modify(true);

        // Sequenced strictly after confirmed success above - never runs if project
        // creation/attach or task/line creation failed (Gap 3, rule 5).
        ACSQuoteAttachmentTransfer.TransferAttachments(SalesHeader."No.", Job."No.");
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
    begin
        JobsSetup.Get();
        JobsSetup.TestField("Job Nos.");

        Job.Init();
        Job."No." := NoSeries.GetNextNo(JobsSetup."Job Nos.");
        Job.Insert(true);
        Job.Validate(Description, SalesHeader."Sell-to Customer Name" + ' - ' + SalesHeader."No.");
        Job.Validate("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        Job.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Job.Validate("Starting Date", SalesHeader."ACS Quote Start Date");
        Job.Validate("Ending Date", SalesHeader."ACS Quote End Date");
        Job.Validate("Shortcut Dimension 5 Code", SalesHeader."Shortcut Dimension 5 Code");
        Job.Modify(true);
    end;
}
