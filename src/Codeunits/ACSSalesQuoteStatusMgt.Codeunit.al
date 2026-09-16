codeunit 90106 "ACS Sales Quote Status Mgt."
{
    // Rule 3 (block Create Project on a Cancelled quote) is enforced inline in
    // ACS Quote To Project Mgt.RunCreateProjectFlow rather than as a separate subscriber
    // here, since that codeunit owns the Create Project entry point directly - no base
    // event to subscribe to for that guard in this design (see its class-level comment).

    // Rule 2 - Cancel Sales Quote action.
    procedure CancelQuote(var SalesHeader: Record "Sales Header")
    var
        CancelQst: Label 'Are you sure you want to cancel this Sales Quote? Once cancelled, the Sales Quote cannot be used to create a Project.';
    begin
        if not Confirm(CancelQst, false) then
            exit;

        SalesHeader."ACS Quote Status" := SalesHeader."ACS Quote Status"::Cancelled;
        SalesHeader.Modify(true);
        // Record is retained, never deleted.
    end;

    // [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeModifyEvent', '', false, false)]
    // local procedure OnBeforeModifySalesHeader(var Rec: Record "Sales Header"; var xRec: Record "Sales Header")
    // begin
    //     if Rec."ACS Quote Status" = Rec."ACS Quote Status"::Closed then
    //         Error('Sales Quote %1 is closed and cannot be modified.', Rec."No.");
    // end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteSalesHeader(var Rec: Record "Sales Header")
    begin
        if Rec."ACS Quote Status" = Rec."ACS Quote Status"::Closed then
            Error('Sales Quote %1 is closed and cannot be deleted.', Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Quote then
            exit;

        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        if SalesHeader."ACS Quote Status" = SalesHeader."ACS Quote Status"::Closed then
            Error('Sales Quote %1 is closed and cannot be modified.', SalesHeader."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteSalesLine(var Rec: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Quote then
            exit;

        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        if SalesHeader."ACS Quote Status" = SalesHeader."ACS Quote Status"::Closed then
            Error('Sales Quote %1 is closed and cannot be modified.', SalesHeader."No.");
    end;

    // Rule 1 - Project completion sync. Job.Status is a standard field; every table field
    // in AL has an implicit OnAfterValidateEvent, so no base-app modification is needed to
    // subscribe to it.
    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterValidateEvent', 'Status', false, false)]
    local procedure OnAfterValidateJobStatus(var Rec: Record Job; var xRec: Record Job)
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec.Status <> Rec.Status::Completed then
            exit;
        if xRec.Status = Rec.Status::Completed then
            exit;

        SalesHeader.SetLoadFields("ACS Linked Project No.", "ACS Quote Status");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.SetRange("ACS Linked Project No.", Rec."No.");
        if SalesHeader.FindSet(true) then
            repeat
                SalesHeader."ACS Quote Status" := SalesHeader."ACS Quote Status"::Completed;
                SalesHeader.Modify(true);
            until SalesHeader.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnCopySalesDocUpdateHeaderOnAfterSetStatusOpen, '', false, false)]
    local procedure OnCopySalesDocUpdateHeaderOnAfterSetStatusOpenCustom(var ToSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader."ACS Quote Status" := ToSalesHeader."ACS Quote Status"::Open;
        ToSalesHeader."ACS Linked Project No." := '';
        ToSalesHeader."CIT AC Approved" := ToSalesHeader."CIT AC Approved"::Open;
        ToSalesHeader."CIT Sales Person Approved" := ToSalesHeader."CIT Sales Person Approved"::Open;
    end;
}
