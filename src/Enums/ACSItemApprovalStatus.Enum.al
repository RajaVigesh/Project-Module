enum 70200012 "ACS Item Approval Status"
{
    Extensible = true;

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; "Pending Approval")
    {
        Caption = 'Pending Approval';
    }
    value(2; Active)
    {
        Caption = 'Active';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
}
