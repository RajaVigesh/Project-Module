tableextension 90101 "ACS Item Ext" extends Item
{
    fields
    {
        field(70200000; "ACS Status"; Enum "ACS Item Approval Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
