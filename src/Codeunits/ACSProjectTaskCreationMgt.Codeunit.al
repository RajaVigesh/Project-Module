codeunit 70200016 "ACS Project Task Creation Mgt."
{
    // Gap 6d. Builds one Job Task per distinct Item Category Code on the quote and one Job
    // Planning Line per quote line (Item lines under their category's task; Comment lines
    // attached immediately after the preceding Item line's planning line). Reused for both
    // the "new project" and "attach to existing project" paths (5a) so task/line creation
    // logic isn't duplicated.
    procedure CreateTasksAndPlanningLines(SalesHeader: Record "Sales Header"; Job: Record Job)
    var
        SalesLine: Record "Sales Line";
        LastItemJobPlanningLine: Record "Job Planning Line";
        CommentOffset: Integer;
        HasCurrentItem: Boolean;
    begin
        ValidateQuoteLinesHaveCategory(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetLoadFields(Type, "No.", Description, Quantity, "Unit of Measure Code",
            "Variant Code", "ACS Vendor Unit Cost", "Unit Price", "ACS Vendor No.", "Item Category Code", "Line No.");

        if not SalesLine.FindSet() then
            exit;

        HasCurrentItem := false;
        repeat
            if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine."No." <> '') then begin
                EnsureJobTaskForCategory(Job, SalesLine."Item Category Code");
                CreateItemPlanningLine(Job, SalesHeader, SalesLine, LastItemJobPlanningLine);
                HasCurrentItem := true;
                CommentOffset := 0;
            end else
                // [Likely] assumption: a "Comment line" is a Sales Line with a blank Type
                // and a Description - the FDD doesn't define the underlying data shape.
                if (SalesLine.Type = SalesLine.Type::" ") and (SalesLine.Description <> '') and HasCurrentItem then begin
                    CommentOffset += 1;
                    CreateCommentPlanningLine(LastItemJobPlanningLine, SalesLine, CommentOffset);
                end;
        until SalesLine.Next() = 0;
    end;

    local procedure ValidateQuoteLinesHaveCategory(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        MissingCategoryLinesErr: Label 'Sales Quote %1 has %2 item line(s) without an Item Category Code. Item Category Code is required on every item line before a project can be created.', Comment = '%1 = quote no., %2 = count of offending lines';
        NoLinesErr: Label 'Sales Quote %1 has no lines. Add at least one line before creating a project.', Comment = '%1 = quote no.';
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.IsEmpty() then
            Error(NoLinesErr, SalesHeader."No.");

        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Item Category Code", '');
        if not SalesLine.IsEmpty() then
            Error(MissingCategoryLinesErr, SalesHeader."No.", SalesLine.Count());
    end;

    local procedure EnsureJobTaskForCategory(Job: Record Job; ItemCategoryCode: Code[20])
    var
        JobTask: Record "Job Task";
        ItemCategory: Record "Item Category";
    begin
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("Job Task No.", ItemCategoryCode);
        if not JobTask.IsEmpty() then
            exit; // duplicate-task guard - task for this category already exists

        ItemCategory.Get(ItemCategoryCode);

        JobTask.Init();
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := ItemCategoryCode;
        JobTask.Insert(true);
        JobTask.Validate(Description, ItemCategory.Description);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.Modify(true);
    end;

    local procedure CreateItemPlanningLine(Job: Record Job; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LastItemJobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine."Job Task No." := SalesLine."Item Category Code";
        JobPlanningLine."Line No." := GetNextPlanningLineNo(Job."No.", SalesLine."Item Category Code");
        JobPlanningLine.Insert(true);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.Validate("No.", SalesLine."No.");
        JobPlanningLine.Validate(Description, SalesLine.Description);
        JobPlanningLine.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
        JobPlanningLine.Validate("Variant Code", SalesLine."Variant Code");
        JobPlanningLine.Validate(Quantity, SalesLine.Quantity);
        JobPlanningLine.Validate("Unit Cost", SalesLine."ACS Vendor Unit Cost");
        JobPlanningLine.Validate("Unit Price", SalesLine."Unit Price");
        JobPlanningLine."Planning Date" := SalesHeader."ACS Quote Start Date";
        JobPlanningLine."ACS CIT Vendor No." := SalesLine."ACS Vendor No.";
        JobPlanningLine."ACS Item Category Code" := SalesLine."Item Category Code";
        JobPlanningLine."ACS Source Quote No." := SalesHeader."No.";
        JobPlanningLine."ACS Source Quote Line No." := SalesLine."Line No.";
        JobPlanningLine.Modify(true);

        LastItemJobPlanningLine := JobPlanningLine;
    end;

    local procedure CreateCommentPlanningLine(ParentJobPlanningLine: Record "Job Planning Line"; SalesLine: Record "Sales Line"; CommentOffset: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine."Job No." := ParentJobPlanningLine."Job No.";
        JobPlanningLine."Job Task No." := ParentJobPlanningLine."Job Task No.";
        // Inserted immediately after the parent item's line, ahead of the next 10000-block
        // line - safe as long as fewer than 10000 comments trail a single item line.
        JobPlanningLine."Line No." := ParentJobPlanningLine."Line No." + CommentOffset;
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);
        JobPlanningLine.Validate(Description, SalesLine.Description);
        JobPlanningLine."ACS Source Quote No." := ParentJobPlanningLine."ACS Source Quote No.";
        JobPlanningLine."ACS Source Quote Line No." := SalesLine."Line No.";
        JobPlanningLine.Modify(true);
    end;

    local procedure GetNextPlanningLineNo(JobNo: Code[20]; JobTaskNo: Code[20]): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetLoadFields("Job No.", "Job Task No.", "Line No.");
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");
        if JobPlanningLine.FindLast() then
            exit(JobPlanningLine."Line No." + 10000);
        exit(10000);
    end;
}
