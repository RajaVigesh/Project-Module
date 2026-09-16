permissionset 70200025 "ACS Sales Project Ext"
{
    Assignable = true;
    Caption = 'ACS Sales Project Ext - Full Access';

    Permissions =
        tabledata "ACS Vendor Activity Header" = RIMD,
        tabledata "ACS Vendor Activity Line" = RIMD,
        tabledata "ACS Attachment Transfer Log" = RIMD,
        table "ACS Vendor Activity Header" = X,
        table "ACS Vendor Activity Line" = X,
        table "ACS Attachment Transfer Log" = X,
        page "ACS Existing Project Lookup" = X,
        page "ACS Sales Quote List All" = X,
        page "ACS Vendor Activity Confirmation" = X,
        page "ACS Vendor Activity Subform" = X,
        codeunit "ACS Vendor Cost Mgt." = X,
        codeunit "ACS Quote Attachment Transfer" = X,
        codeunit "ACS Quote To Project Mgt." = X,
        codeunit "ACS Sales Quote Status Mgt." = X,
        codeunit "ACS Item Approval Mgt." = X,
        codeunit "ACS Project Task Creation Mgt." = X,
        codeunit "ACS Vendor Activity Mgt." = X,
        codeunit "ACS Qty To Invoice Mgt." = X,
        codeunit "ACS Project Invoice Attachment Mgt." = X;
}
