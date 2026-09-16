tableextension 90107 "Job Ext" extends Job
{
    fields
    {
        field(90100; "ShortCut Dimension 3 code"; Code[20])
        {
            Caption = 'Shortcut Dimension 3 Code';
            CaptionClass = '1,2,3';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3));
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
            begin
                ValidateShortcutDimCode(3, "Shortcut Dimension 3 Code");
            end;
            //CAS-28402-V4H0 Begin
            /*trigger OnLookup()
            begin
                TestField("ShortCut Dimension 5 Code");
                ShowDimensionCombinationList(3, Rec."ShortCut Dimension 5 code");
                Validate("ShortCut Dimension 4 Code", '');
            end;*/
            //CAS-28402-V4H0 end
        }
        field(90101; "ShortCut Dimension 4 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 4 Code';
            CaptionClass = '1,2,4';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4));
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(4, "Shortcut Dimension 4 Code");
            end;

            trigger OnLookup()
            begin
                TestField("ShortCut Dimension 3 code");
                ShowDimensionCombinationList(4, Rec."ShortCut Dimension 3 code");
            end;
        }
        field(90102; "ShortCut Dimension 5 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 5 Code';
            CaptionClass = '1,2,5';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5));
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(5, "Shortcut Dimension 5 Code");
            end;

        }
        field(90103; "ShortCut Dimension 6 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 6 Code';
            CaptionClass = '1,2,6';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6));
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(6, "Shortcut Dimension 6 Code");
            end;
        }
        field(90104; "ShortCut Dimension 7 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 7 Code';
            CaptionClass = '1,2,7';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7));
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(7, "Shortcut Dimension 7 Code");
            end;
        }
        field(90105; "ShortCut Dimension 8 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 8 Code';
            CaptionClass = '1,2,8';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8));
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                ValidateShortcutDimCode(8, "Shortcut Dimension 8 Code");
            end;
        }
        field(90106; "Approval Status"; Enum "Project Approval Status")
        {
            Caption = 'Approval Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(90107; "CIT Work Description"; blob)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
        }
        field(90108; "PO Status"; Enum "Job PO Status")
        {
            Caption = 'PO Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(90109; "Customer PO Number"; Code[20])
        {
            Caption = 'Customer PO Number';
            DataClassification = CustomerContent;
        }
        field(90110; "Sales Person Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = CustomerContent;
        }
        field(90111; "ACS Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    procedure ShowDimensionCombinationList(DimensionCode: Integer; DimValueCode: Code[20])
    var
        DimensionValueComb: Record "Dimension Value Combination";
        DimensionValue: Record "Dimension Value";
        DimensionValueList: Page "Dimension Value List";
        GenLedSetup: Record "General Ledger Setup";
    begin
        GenLedSetup.Get();
        DimensionValue.Reset();
        DimensionValue.ClearMarks();
        DimensionValue.SetRange("Global Dimension No.", DimensionCode);
        if DimensionValue.FindSet() then begin
            repeat
                // Commented on 170426 CIT416
                // case DimensionCode of
                //     3:
                //         begin
                //             DimensionValueComb.Reset();
                //             DimensionValueComb.SetRange("Dimension 1 Code", GenLedSetup."Shortcut Dimension 3 Code");
                //             DimensionValueComb.SetRange("Dimension 2 Code", GenLedSetup."Shortcut Dimension 5 Code");
                //             DimensionValueComb.SetRange("Dimension 2 Value Code", DimValueCode);
                //             DimensionValueComb.SetRange("Dimension 1 Value Code", DimensionValue.Code);
                //         end;
                //     7:
                //         begin
                //             DimensionValueComb.Reset();
                //             DimensionValueComb.SetRange("Dimension 1 Code", GenLedSetup."Shortcut Dimension 3 Code");
                //             DimensionValueComb.SetRange("Dimension 2 Code", GenLedSetup."Shortcut Dimension 7 Code");
                //             DimensionValueComb.SetRange("Dimension 1 Value Code", DimValueCode);
                //             DimensionValueComb.SetRange("Dimension 2 Value Code", DimensionValue.Code);
                //         end;
                // /* 5:
                //     begin
                //         DimensionValueComb.Reset();
                //         DimensionValueComb.SetRange("Dimension 1 Code", GenLedSetup."Shortcut Dimension 3 Code");
                //         DimensionValueComb.SetRange("Dimension 2 Code", GenLedSetup."Shortcut Dimension 5 Code");
                //         DimensionValueComb.SetRange("Dimension 1 Value Code", DimValueCode);
                //         DimensionValueComb.SetRange("Dimension 2 Value Code", DimensionValue.Code);
                //     end; */
                // end;
                // if not DimensionValueComb.FindFirst() then begin
                //     DimensionValue.Mark(true);
                // end;
                // Commented on 170426 CIT416
                // CIT416 above logic updated on 170426
                case DimensionCode of
                    3:
                        begin
                            DimensionValueComb.Reset();
                            DimensionValueComb.SetRange("Dimension 1 Code", GenLedSetup."Shortcut Dimension 3 Code");
                            DimensionValueComb.SetRange("Dimension 2 Code", GenLedSetup."Shortcut Dimension 5 Code");
                            DimensionValueComb.SetRange("Dimension 2 Value Code", DimValueCode);
                            DimensionValueComb.SetRange("Dimension 1 Value Code", DimensionValue.Code);

                            if DimensionValueComb.FindFirst() then
                                DimensionValue.Mark(true);
                        end;

                    7:
                        begin
                            DimensionValueComb.Reset();
                            DimensionValueComb.SetRange("Dimension 1 Code", GenLedSetup."Shortcut Dimension 3 Code");
                            DimensionValueComb.SetRange("Dimension 2 Code", GenLedSetup."Shortcut Dimension 7 Code");
                            DimensionValueComb.SetRange("Dimension 1 Value Code", DimValueCode);
                            DimensionValueComb.SetRange("Dimension 2 Value Code", DimensionValue.Code);

                            if DimensionValueComb.FindFirst() then
                                DimensionValue.Mark(true);
                        end;

                    else begin
                        DimensionValue.Mark(true);
                    end;
                end;
            until DimensionValue.Next() = 0;
            // CIT416 above logic updated on 170426
        end;
        DimensionValue.MarkedOnly(true);
        Clear(DimensionValueList);
        DimensionValueList.SetTableView(DimensionValue);
        DimensionValueList.LookupMode(true); //CIT256 Added lookupmode to show Ok button in list page 8-11-23
        if DimensionValueList.RunModal() in [Action::LookupOK, Action::OK] then begin
            DimensionValueList.SetSelectionFilter(DimensionValue);
            DimensionValue.FindFirst();
            if DimensionCode = 7 then begin
                Validate("ShortCut Dimension 4 code", DimensionValue.Code);
            end
            else
                if DimensionCode = 3 then begin
                    Validate("ShortCut Dimension 3 code", DimensionValue.Code);
                end
                else if DimensionCode = 5 then begin
                    Validate("ShortCut Dimension 5 code", DimensionValue.Code);
                end
                else if DimensionCode = 4 then begin
                    Validate("ShortCut Dimension 4 code", DimensionValue.Code);
                end;

        end;
    end;
    //CIT256 Dimension Combination Check <<<<< End 28-7-23

    //CIT256 Update Customer Default dimension in SQ,SO,SI >>>>> Begin 8-8-23
    local procedure UpdateCustomerDefaultDimension()
    var
        DefaultDimensionRec: Record "Default Dimension";
        SalesReceivablesSetupRec: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetupRec.Reset();
        SalesReceivablesSetupRec.Get();
        DefaultDimensionRec.Reset();
        DefaultDimensionRec.SetRange("Table ID", 18);
        DefaultDimensionRec.SetRange("No.", Rec."Sell-to Customer No.");
        DefaultDimensionRec.SetRange("Dimension Code", SalesReceivablesSetupRec."Customer Group Dimension Code");
        if DefaultDimensionRec.FindFirst() then begin
            Rec.Validate("ShortCut Dimension 5 Code", DefaultDimensionRec."Dimension Value Code");
            Rec.Modify();
        end;
    end;

    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear("CIT Work Description");
        "CIT Work Description".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    /// <summary>
    /// Retrieves work description from the sales header.
    /// </summary>
    /// <returns>Work description.</returns>
    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("CIT Work Description");
        "CIT Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("CIT Work Description")));
    end;
}
