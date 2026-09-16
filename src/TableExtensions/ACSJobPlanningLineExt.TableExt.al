tableextension 90103 "ACS Job Planning Line Ext" extends "Job Planning Line"
{
    fields
    {
        field(90100; "ACS CIT Vendor No."; Code[20])
        {
            Caption = 'CIT Vendor No.';
            TableRelation = Vendor;
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                VendorRec: Record Vendor;
            begin
                if "ACS CIT Vendor No." <> '' then begin
                    if VendorRec.Get("ACS CIT Vendor No.") then
                        Rec.Validate("ACS Vendor Name", VendorRec.Name)
                    else begin
                        Rec."ACS Vendor Name" := '';
                    end;
                end;
            end;
        }
        field(90101; "ACS Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
            DataClassification = CustomerContent;
        }
        // Traceability back to the source Sales Quote - required to enforce the Gap 4
        // "same quote can't be attached to the same project twice" rule and to support
        // Gap 9's Job No./Job Task No./Job Planning Line No. lookup from the posted journal.
        field(90102; "ACS Source Quote No."; Code[20])
        {
            Caption = 'Source Sales Quote No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(90103; "ACS Source Quote Line No."; Integer)
        {
            Caption = 'Source Sales Quote Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(90104; "ACS Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(90105; "ACS Vendor Unit Cost"; Decimal)
        {
            Caption = 'Vendor Unit Cost';
            DecimalPlaces = 2 : 5;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin

            end;
        }
        field(90106; "ACS Non-Market Item"; Boolean)
        {
            Caption = 'Non-Market Item';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(90107; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(90108; "Item Reference No."; Code[20])
        {
            Caption = 'Item Reference No.';
            DataClassification = CustomerContent;
        }
        field(90109; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DecimalPlaces = 2 : 5;
            // DataClassification = CustomerContent;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Job Planning Line"."Line Amount");
        }
    }

    keys
    {
        key(ACSSourceQuote; "ACS Source Quote No.")
        {
        }
    }
}
