report 90100 "Workflow Template Deletion"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    Permissions = tabledata "Workflow Buffer" = rimd;

    dataset
    {
        dataitem("Workflow Buffer"; "Workflow Buffer")
        {
            trigger OnPreDataItem()
            begin
                if CategoryCode <> '' then
                    "Workflow Buffer".SetRange("Category Code", CategoryCode)
                else
                    Error('category code should not be blank');
                if WorkFlowCode <> '' then
                    "Workflow Buffer".SetRange("Workflow Code", WorkFlowCode)
                else
                    Error('WorkFlow Code should not be Blank');
            end;

            trigger OnAfterGetRecord()
            begin
                "Workflow Buffer".DeleteAll();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
            area(Content)
            {
                group(general)
                {
                    field(CategoryCode; CategoryCode)
                    {
                        ApplicationArea = all;
                        Caption = 'Category Code';
                    }
                    field(WorkFlowCode; WorkFlowCode)
                    {
                        ApplicationArea = all;
                        Caption = 'WorkFlow Code';
                    }
                }
            }
        }
    }


    var
        CategoryCode: Code[20];
        WorkFlowCode: Code[20];
}